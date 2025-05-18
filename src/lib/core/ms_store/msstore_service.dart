import 'dart:io';
import 'package:collection/collection.dart';
import 'package:dio/dio.dart';
import 'package:process_run/shell_run.dart';
import 'package:revitool/core/ms_store/non_uwp_response_dto.dart';
import 'package:revitool/core/ms_store/packages_info_dto.dart';
import 'package:revitool/core/ms_store/product.dart';
import 'package:revitool/core/ms_store/search_response_dto.dart';
import 'package:revitool/core/ms_store/update_response.dart';
import 'package:revitool/shared/network_service.dart';
import 'package:revitool/utils.dart';

import 'package:xml/xml.dart' as xml;

class _PackageCacheEntry {
  final Set<MSStorePackagesInfoDTO> packages;
  final DateTime expiryDate;

  const _PackageCacheEntry({required this.packages, required this.expiryDate});

  bool get isExpired => DateTime.now().isAfter(expiryDate);
}

class MSStoreService {
  static final _storeFolder =
      "${Directory.systemTemp.path}\\Revision-Tool\\MSStore";
  String get storeFolder => _storeFolder;

  static final _cookieFile =
      File('$directoryExe\\msstore\\cookie.xml').readAsStringSync();
  static final _urlFile =
      File('$directoryExe\\msstore\\url.xml').readAsStringSync();
  static final _wuFile =
      File('$directoryExe\\msstore\\wu.xml').readAsStringSync();
  static const _fe3Delivery =
      "https://fe3.delivery.mp.microsoft.com/ClientWebService/client.asmx";
  static const _storeAPI = "https://storeedgefd.dsx.mp.microsoft.com/v9.0";
  // static const _filteredSearchAPI = "https://apps.microsoft.com/store/api/Products/GetFilteredSearch";
  static const _searchAPI = "https://apps.microsoft.com/api/products/search";
  static final _optionsSoapXML = Options(
    headers: {
      "user-agent":
          "Mozilla/5.0 (Windows NT 10.0; rv:107.0) Gecko/20100101 Firefox/107.0",
      "Accept": "*/*",
      "Content-Type": "application/soap+xml",
    },
  );

  static final _options = Options(
    headers: {
      "user-agent":
          "Mozilla/5.0 (Windows NT 10.0; rv:107.0) Gecko/20100101 Firefox/107.0",
      "content-type": "application/json;charset=utf-8",
      "accept": "application/json",
    },
  );

  static String _cookie = "";

  static const _knownPackageArch = {'x86', 'x64', 'arm64', 'arm', 'neutral'};

  static final _cancelToken = CancelToken();
  static final _networkService = NetworkService();

  static const _instance = MSStoreService._private();
  factory MSStoreService() => _instance;
  const MSStoreService._private();

  static final _packagesCache = <String, _PackageCacheEntry>{};
  static String _currentProductId = "";
  Set<MSStorePackagesInfoDTO> get packages {
    if (_currentProductId.isNotEmpty &&
        _packagesCache.containsKey(_currentProductId) &&
        !_packagesCache[_currentProductId]!.isExpired) {
      return Set.unmodifiable(_packagesCache[_currentProductId]!.packages);
    }
    return Set.unmodifiable([]);
  }

  Future<void> startProcess(String id, String ring) async {
    final productId = id.trim();
    _currentProductId = productId;

    if (_packagesCache.containsKey(productId) &&
        !_packagesCache[productId]!.isExpired) {
      return;
    }

    try {
      if (isUWP(productId)) {
        if (_cookie.isEmpty) {
          _cookie = await _getCookie();
        }

        final String categoryID = await _getCategoryID(productId);

        await _parsePackages(
          await _fetchFileListXML(categoryID, _cookie, ring),
          ring,
        );
      }

      // Non-UWP apps mostly start with "XP"
      if (isNonUWP(productId)) {
        await _getNonAppxPackage(productId);
      }
    } catch (e) {
      _packagesCache.remove(productId);
      _currentProductId = "";
      throw Exception('Failed to retrieve packages: ${e.toString()}');
    }
  }

  /// Returns true if the product is UWP
  bool isUWP(String productId) {
    return productId.startsWith("9");
  }

  /// Returns true if the product is not UWP
  bool isNonUWP(String productId) {
    return productId.toLowerCase().startsWith("xp");
  }

  Future<List<ProductsList>> searchProducts(String query, String ring) async {
    //"$_filteredSearchAPI?&Query=$query&FilteredCategories=AllProducts&hl=en-us${systemLanguage.toLowerCase()}&
    final response = await _networkService.get(
      "$_searchAPI?gl=US&hl=en-us&query=$query&mediaType=all&age=all&price=all&category=all&subscription=all",

      // https://apps.microsoft.com/api/products/search?gl=GE&hl=en-us&query=xbox&cursor=
      options: _options,
    );

    if (response.statusCode == 200) {
      final responseData = MSStoreSearchResponseDTO.fromJson(response.data);
      return [
        ...(responseData.highlightedList ?? List<ProductsList>.empty()),
        ...(responseData.productsList ?? List<ProductsList>.empty()),
      ];
    }
    throw Exception('Failed to search the product');
  }

  Future<String> _getCookie() async {
    final response = await _networkService.post(
      _fe3Delivery,
      data: xml.XmlDocument.parse(_cookieFile),
      options: _optionsSoapXML,
      cancelToken: _cancelToken,
    );

    if (response.statusCode == 200) {
      return xml.XmlDocument.parse(
        response.data,
      ).findAllElements("EncryptedData").first.innerText;
    }
    throw Exception('Failed to get a cookie');
  }

  Future<String> _getCategoryID(String id) async {
    // When Windows region is set to English (World), the language code isn't compatible with the store API, therefore use US en-US
    final response = await _networkService.get(
      "$_storeAPI/products/$id?market=US&locale=en-us&deviceFamily=Windows.Desktop",
      cancelToken: _cancelToken,
    );

    if (response.statusCode == 200) {
      final product = Product.fromJson(response.data);

      final skus = product.payload!.skus!;

      if (skus.isNotEmpty) {
        for (final sku in skus) {
          if (sku.skuType!.value == SkuType.full.value) {
            _packagesCache[_currentProductId] = _PackageCacheEntry(
              packages: {},
              expiryDate: product.expiryUtc!,
            );
            return sku.fulfillmentData!.wuCategoryId!;
          }
        }
      }
      throw Exception("The selected app is not UWP");
    }
    throw Exception('Failed to get category id');
  }

  Future<String> _fetchFileListXML(
    String categoryID,
    String cookie,
    String ring,
  ) async {
    final cookie2 = _wuFile
        .replaceAll("{1}", cookie)
        .replaceAll("{2}", categoryID)
        .replaceAll("{3}", ring);

    final response = await _networkService.post(
      _fe3Delivery,
      data: cookie2,
      options: _optionsSoapXML,
      cancelToken: _cancelToken,
    );

    if (response.statusCode == 200) {
      return response.data
          .toString()
          .replaceAll("&lt;", "<")
          .replaceAll("&gt;", ">");
    }
    throw Exception('Failed to get file list xml');
  }

  Future<void> _getNonAppxPackage(String id) async {
    final response = await _networkService.get(
      "$_storeAPI/packageManifests/$id?Market=US",
      cancelToken: _cancelToken,
    );

    if (response.statusCode != 200) return;

    final data = MSStoreNonUWPResponseDTO.fromJson(response.data).data;
    final versions = data?.versions;
    if (versions == null || versions.isEmpty) return;

    final urls = <String>{};
    final pkgs = <MSStorePackagesInfoDTO>{};

    for (final version in versions) {
      for (final installer in version.installers!) {
        final url = installer.installerUrl;
        if (url == null || urls.contains(url)) continue;

        final String fileType =
            installer.installerType ?? url.substring(url.lastIndexOf('.') + 1);

        if (!["exe", "msi"].contains(fileType)) continue;
        pkgs.add(
          MSStorePackagesInfoDTO(
            id: id,

            isDependency: false,
            uri: url,
            arch: extractArchitecture(installer.installerUrl!),
            fileModel: FileModel(
              fileName:
                  "${version.defaultLocale?.packageName}-${installer.architecture}",
              fileType: fileType,
            ),
            commandLines: installer.installerSwitches?.silent?.replaceAll(
              '"',
              '',
            ),
          ),
        );
        urls.add(url);
      }
    }

    if (pkgs.isNotEmpty) {
      _packagesCache[_currentProductId] = _PackageCacheEntry(
        packages: pkgs,
        expiryDate: DateTime.now().add(const Duration(minutes: 2)),
      );
    }
  }

  String extractArchitecture(String package) {
    package = package.toLowerCase();
    for (final arch in _knownPackageArch) {
      if (package.contains(arch)) {
        return arch;
      }
    }
    return _knownPackageArch.last;
  }

  UpdateResponse xmlToUpdateResponse(xml.XmlDocument document) {
    final updatesMap = <String, UpdateModel>{};

    final doc = document.findAllElements('SyncUpdatesResult').first;

    for (final updateElement in doc
        .getElement('ExtendedUpdateInfo')!
        .getElement('Updates')!
        .findElements('Update')) {
      final id = updateElement.getElement('ID')!.innerText;

      final xmlElement = updateElement.getElement('Xml');
      if (xmlElement == null) continue;

      final filesElement = xmlElement.getElement('Files');
      if (filesElement == null || filesElement.children.isEmpty) continue;
      final files = <FileModel>{};
      for (final fileElement in filesElement.findElements('File')) {
        final packageFullName = fileElement.getAttribute(
          'InstallerSpecificIdentifier',
        );
        if (packageFullName == null) continue;

        final fileName = fileElement.getAttribute('FileName');
        final fileType = fileName!.split('.').last;

        if (fileType.startsWith("e")) {
          continue; // encrypted files installation is not supported
        }

        files.add(
          FileModel(
            fileName: fileElement.getAttribute('FileName'),
            fileType: fileType,
            packageFullName: packageFullName,
            digest: fileElement.getAttribute('Digest'),
            digestAlgorithm: fileElement.getAttribute('DigestAlgorithm'),
            size:
                fileElement.getAttribute('Size') != null
                    ? int.tryParse(fileElement.getAttribute('Size')!)
                    : null,
            modifiedDate:
                fileElement.getAttribute('Modified') != null
                    ? DateTime.parse(fileElement.getAttribute('Modified')!)
                    : null,
          ),
        );
      }

      if (files.isEmpty) continue;

      final propsElement = xmlElement.getElement('ExtendedProperties');
      if (propsElement != null) {
        final extendedProperties = ExtendedProperties(
          contentType: propsElement.getAttribute('ContentType'),
          isAppxFramework:
              propsElement.getAttribute('IsAppxFramework') == 'true',
          creationDate:
              propsElement.getAttribute('CreationDate') != null
                  ? DateTime.parse(propsElement.getAttribute('CreationDate')!)
                  : null,
          packageIdentityName: propsElement.getAttribute('PackageIdentityName'),
        );

        updatesMap[id] = UpdateModel(
          id: id,
          xml: ElementXml(
            fileModel: files,
            extendedProperties: extendedProperties,
          ),
        );
      }
    }

    for (final updateInfoElement in doc
        .getElement('NewUpdates')!
        .findElements('UpdateInfo')) {
      final id = updateInfoElement.getElement('ID')?.innerText ?? '';

      if (id.isEmpty) continue;
      if (!updatesMap.containsKey(id)) continue;

      final xmlElement = updateInfoElement.getElement('Xml');
      if (xmlElement == null) continue;

      final identityElement = xmlElement.getElement('UpdateIdentity');
      UpdateIdentity? updateIdentity;
      if (identityElement == null) continue;

      updateIdentity = UpdateIdentity(
        id: identityElement.getAttribute('UpdateID')!,
        revisionNumber: identityElement.getAttribute('RevisionNumber')!,
      );

      String? packageMoniker;
      final appRules = xmlElement.getElement('ApplicabilityRules');
      if (appRules == null) continue;
      final appxMetadata = appRules
          .getElement('Metadata')!
          .getElement('AppxPackageMetadata')!
          .getElement('AppxMetadata');
      if (appxMetadata != null) {
        packageMoniker = appxMetadata.getAttribute('PackageMoniker')!;

        if (packageMoniker.startsWith("Microsoft.Advertising")) {
          // skip ads
          updatesMap.remove(id);
          continue;
        }
      }

      updatesMap[id] = updatesMap[id]!.copyWith(
        arch: extractArchitecture(packageMoniker!),
        xml: updatesMap[id]!.xml.copyWith(
          updateIdentity: updateIdentity,
          packageMoniker: packageMoniker,
        ),
      );
    }

    // Filter to keep only latest packages by comparing modified dates
    final latestPackages = <String, UpdateModel>{};
    for (final update in updatesMap.values) {
      final id =
          "${update.xml.extendedProperties!.packageIdentityName!}-${update.arch!}";

      if (!latestPackages.containsKey(id)) {
        latestPackages[id] = update;
      } else {
        final existing = latestPackages[id]!;
        final existingDate = existing.xml.fileModel.first.modifiedDate;
        final currentDate = update.xml.fileModel.first.modifiedDate;

        if (currentDate != null &&
            (existingDate == null || currentDate.isAfter(existingDate))) {
          latestPackages[id] = update;
        }
      }
    }

    return UpdateResponse(updates: latestPackages.values.toSet());
  }

  Future<void> _parsePackages(String xmlList, String ring) async {
    final xmlDoc = xml.XmlDocument.parse(xmlList);
    final updatesResponse = xmlToUpdateResponse(xmlDoc);

    for (final update in updatesResponse.updates) {
      final id = update.id;
      final xml = update.xml;

      final files = update.xml.fileModel;
      if (files.isEmpty) return;

      _packagesCache[_currentProductId]!.packages.add(
        MSStorePackagesInfoDTO(
          id: id,
          arch: update.arch!,
          isDependency: xml.extendedProperties!.isAppxFramework!,
          fileModel: files.first.copyWith(fileName: xml.packageMoniker),
          uri: await _getUri(
            updateID: xml.updateIdentity!.id,
            revision: xml.updateIdentity!.revisionNumber,
            ring: ring,
            digets: files.first.digest!,
          ),
          updateIdentity: xml.updateIdentity,
        ),
      );
    }
  }

  Future<String> _getUri({
    required String updateID,
    required String revision,
    required String ring,
    required String digets,
  }) async {
    final httpContent = _urlFile
        .replaceAll("{1}", updateID)
        .replaceAll("{2}", revision)
        .replaceAll("{3}", ring);

    final response = await _networkService.post(
      "$_fe3Delivery/secured",
      data: httpContent,
      options: Options(
        headers: {
          HttpHeaders.contentTypeHeader: "application/soap+xml",
          "user-agent":
              "Mozilla/5.0 (Windows NT 10.0; rv:107.0) Gecko/20100101 Firefox/107.0",
        },
      ),
      cancelToken: _cancelToken,
    );

    if (response.statusCode == 200) {
      final xmlDoc = xml.XmlDocument.parse(response.data);

      for (final node in xmlDoc.findAllElements("FileLocation")) {
        if (node.getElement("FileDigest")!.innerText == digets) {
          return node.getElement("Url")!.innerText;
        }
      }
    }
    return "";
  }

  Future<List<Response>> downloadPackages(String productId, String ring) async {
    final path = "$_storeFolder\\$productId\\$ring";
    final downloadFutures = <Future<Response>>[];

    for (final item in _packagesCache[productId]!.packages) {
      final downloadPath = item.isDependency ? "$path\\Dependencies" : path;
      downloadFutures.add(
        _networkService.downloadFile(
          item.uri,
          "$downloadPath\\${item.fileModel!.fileName}.${item.fileModel!.fileType}",
        ),
      );
    }

    return Future.wait(downloadFutures);
  }

  Future<List<ProcessResult>> installPackages(String id, String ring) async {
    return isUWP(id)
        ? await _installUWPPackages(id, ring)
        : await _installNonUWPPackages(id, ring);
  }

  Future<List<ProcessResult>> _installUWPPackages(
    String id,
    String ring,
  ) async {
    final path = "$_storeFolder\\$id\\$ring";
    final entities = Directory(path).listSync();

    if (entities.isEmpty) return [];

    final results = <Future<ProcessResult>>[];

    for (final entity in entities) {
      if (entity is File) {
        results.add(_addAppxProcess(entity.path));
      }
      if (entity is Directory && entity.path.endsWith('Dependencies')) {
        final deps = entity.listSync().whereType<File>();
        for (final file in deps) {
          results.add(_addAppxProcess(file.path));
        }
      }
    }

    return Future.wait(results);
  }

  Future<ProcessResult> _addAppxProcess(String path) async {
    return await Process.run("powershell", [
      "Add-AppxPackage -Path $path -ForceApplicationShutdown",
    ]);
  }

  Future<List<ProcessResult>> _installNonUWPPackages(
    String id,
    String ring,
  ) async {
    final fileList = Directory("$_storeFolder\\$id\\$ring").listSync();
    final results = <ProcessResult>[];

    for (final file in fileList) {
      if (file is File) {
        final filePath = file.path;
        final arguments =
            _packagesCache[_currentProductId]!.packages
                .firstWhereOrNull(
                  (e) =>
                      e.fileModel!.fileName ==
                      (file.path.split('\\').last).split(".").first,
                )
                ?.commandLines
                ?.split(' ') ??
            List<String>.empty();

        results.add(
          await runExecutableArguments(filePath, arguments, verbose: true),
        );
      }
    }

    return results;
  }

  Future<void> cleanUpDownloads() async {
    final dir = Directory(_storeFolder);
    if (await dir.exists()) {
      await dir.delete(recursive: true);
    }
  }
}
