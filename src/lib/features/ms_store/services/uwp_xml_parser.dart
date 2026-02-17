import 'dart:io';
import 'package:xml/xml.dart';
import '../../../utils.dart';
import '../models/uwp/uwp_package.dart';

/// Stateless parser for UWP-related XML responses.
/// Designed to be run in an isolate via [compute].
class UwpXmlParser {
  const UwpXmlParser();

  static const _knownPackageArch = {'x86', 'x64', 'arm64', 'arm', 'neutral'};

  /// Parses the encrypted cookie from the SOAP response
  String parseCookieResponse(String xmlString) {
    final document = XmlDocument.parse(xmlString);
    return document.findAllElements('EncryptedData').first.innerText;
  }

  /// Extracts architecture from package moniker
  String extractArchitecture(String package) {
    package = package.toLowerCase();
    for (final String arch in _knownPackageArch) {
      if (package.contains(arch)) {
        return arch;
      }
    }
    return _knownPackageArch.last;
  }

  /// Parses the package list XML into [UwpPackageResponse]
  /// Matches entries between ExtendedUpdateInfo and NewUpdates
  static UwpPackageResponse parsePackageListXml(String xmlString) {
    const parser = UwpXmlParser();
    final document = XmlDocument.parse(xmlString);
    final updatesMap = <String, UpdateModel>{};

    final XmlElement? syncUpdatesResult = document
        .findAllElements('SyncUpdatesResult')
        .firstOrNull;
    if (syncUpdatesResult == null) return const UwpPackageResponse(updates: {});

    // 1. Parse ExtendedUpdateInfo for files and metadata
    final XmlElement? extendedUpdateInfo = syncUpdatesResult.getElement(
      'ExtendedUpdateInfo',
    );
    if (extendedUpdateInfo != null) {
      final XmlElement? updates = extendedUpdateInfo.getElement('Updates');
      if (updates != null) {
        for (final XmlElement updateElement in updates.findElements('Update')) {
          final String? id = updateElement.getElement('ID')?.innerText;

          final XmlElement? xmlElement = updateElement.getElement('Xml');
          if (id == null || xmlElement == null) continue;

          final XmlElement? filesElement = xmlElement.getElement('Files');
          if (filesElement == null || filesElement.children.isEmpty) continue;

          final files = <FileModel>{};
          for (final XmlElement fileElement in filesElement.findElements(
            'File',
          )) {
            final String fileName = fileElement.getAttribute('FileName')!;
            final String? packageFullName = fileElement.getAttribute(
              'InstallerSpecificIdentifier',
            );
            final String fileType = fileName.split('.').last;

            if (fileType.startsWith('e') || packageFullName == null) {
              continue; // encrypted files installation is not supported
            }

            files.add(
              FileModel(
                fileName: fileName,
                fileType: fileType,
                packageFullName: packageFullName,
                digest: fileElement.getAttribute('Digest'),
                digestAlgorithm: fileElement.getAttribute('DigestAlgorithm'),
                size: int.tryParse(fileElement.getAttribute('Size') ?? '0'),
                modifiedDate: DateTime.tryParse(
                  fileElement.getAttribute('Modified') ?? '',
                ),
              ),
            );
          }

          if (files.isEmpty) continue;

          final XmlElement? propsElement = xmlElement.getElement(
            'ExtendedProperties',
          );
          final ExtendedProperties? extendedProperties = propsElement != null
              ? ExtendedProperties(
                  contentType: propsElement.getAttribute('ContentType'),
                  isAppxFramework:
                      propsElement.getAttribute('IsAppxFramework') == 'true',
                  creationDate: DateTime.tryParse(
                    propsElement.getAttribute('CreationDate') ?? '',
                  ),
                  packageIdentityName: propsElement.getAttribute(
                    'PackageIdentityName',
                  ),
                )
              : null;

          updatesMap[id] = UpdateModel(
            id: id,
            xml: ElementXml(
              fileModel: files,
              extendedProperties: extendedProperties,
            ),
          );
        }
      }
    }

    // 2. Parse NewUpdates for identity and architecture
    final XmlElement? newUpdates = syncUpdatesResult.getElement('NewUpdates');
    if (newUpdates != null) {
      for (final XmlElement updateInfoElement in newUpdates.findElements(
        'UpdateInfo',
      )) {
        final String? id = updateInfoElement.getElement('ID')?.innerText;
        final XmlElement? xmlElement = updateInfoElement.getElement('Xml');
        if (id == null || !updatesMap.containsKey(id) || xmlElement == null) {
          continue;
        }

        final XmlElement? identityElement = xmlElement.getElement(
          'UpdateIdentity',
        );
        if (identityElement == null) continue;

        final updateIdentity = UpdateIdentity(
          id: identityElement.getAttribute('UpdateID') ?? '',
          revisionNumber: identityElement.getAttribute('RevisionNumber') ?? '',
        );

        String? packageMoniker;
        final XmlElement? appRules = xmlElement.getElement(
          'ApplicabilityRules',
        );
        final XmlElement? appxMetadata = appRules
            ?.getElement('Metadata')
            ?.getElement('AppxPackageMetadata')
            ?.getElement('AppxMetadata');

        if (appxMetadata != null) {
          packageMoniker = appxMetadata.getAttribute('PackageMoniker');
          // skip ads
          if (packageMoniker != null &&
              packageMoniker.startsWith('Microsoft.Advertising')) {
            updatesMap.remove(id);
            continue;
          }
        }

        final String arch = packageMoniker != null
            ? parser.extractArchitecture(packageMoniker)
            : _knownPackageArch.last;

        updatesMap[id] = updatesMap[id]!.copyWith(
          arch: arch,
          xml: updatesMap[id]!.xml.copyWith(
            updateIdentity: updateIdentity,
            packageMoniker: packageMoniker,
          ),
        );
      }
    }

    // 3. Filter to keep only latest packages by comparing modified dates
    final latestPackages = <String, UpdateModel>{};
    for (final UpdateModel update in updatesMap.values) {
      final String? identityName =
          update.xml.extendedProperties?.packageIdentityName;
      if (identityName == null || update.arch == null) continue;

      final cacheKey = '$identityName-${update.arch}';

      if (!latestPackages.containsKey(cacheKey)) {
        latestPackages[cacheKey] = update;
      } else {
        final UpdateModel existing = latestPackages[cacheKey]!;
        final DateTime? existingDate =
            existing.xml.fileModel.firstOrNull?.modifiedDate;
        final DateTime? currentDate =
            update.xml.fileModel.firstOrNull?.modifiedDate;

        if (currentDate != null &&
            (existingDate == null || currentDate.isAfter(existingDate))) {
          latestPackages[cacheKey] = update;
        }
      }
    }

    return UwpPackageResponse(updates: latestPackages.values.toSet());
  }

  /// Parses the download URL from the GetExtendedUpdateInfo2 response
  /// Correlates the file by [digest] if multiple files are present.
  String parseDownloadUrl(String xmlString, [String? digest]) {
    final document = XmlDocument.parse(xmlString);

    if (digest != null) {
      final Iterable<XmlElement> locations = document.findAllElements(
        'FileLocation',
      );
      for (final location in locations) {
        final String? fileDigest = location.getElement('FileDigest')?.innerText;
        if (fileDigest == digest) {
          return location.getElement('Url')?.innerText ?? '';
        }
      }
    }

    final XmlElement? urlElement = document.findAllElements('Url').firstOrNull;
    if (urlElement == null) {
      throw Exception('Download URL not found in XML response');
    }
    return urlElement.innerText;
  }

  /// Lazy-loads XML templates from assets
  static final Map<String, String> _templates = {};

  String getTemplateSync(String name) {
    if (_templates.containsKey(name)) return _templates[name]!;

    final file = File('$directoryExe\\msstore\\$name.xml');
    if (!file.existsSync()) {
      throw Exception('Template $name.xml not found at ${file.path}');
    }

    final String content = file.readAsStringSync();
    _templates[name] = content;
    return content;
  }

  Future<String> getTemplate(String name) async => getTemplateSync(name);
}
