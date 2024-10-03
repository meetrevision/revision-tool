import 'dart:io';
import 'package:collection/collection.dart';
import 'package:common/src/dto/ms_store/non_uwp_response_dto.dart';
import 'package:common/src/dto/ms_store/packages_info_dto.dart';
import 'package:common/src/dto/ms_store/search_response_dto.dart';
import 'package:common/src/services/network_service.dart';
import 'package:common/src/utils.dart';
import 'package:dio/dio.dart';
import 'package:process_run/shell_run.dart';

import 'package:xml/xml.dart' as xml;

class MSStoreService {
  static final _storeFolder =
      "${Directory.systemTemp.path}\\Revision-Tool\\MSStore";
  String get storeFolder => _storeFolder;

  static final _cookieFile = File('$directoryExe\\msstore\\cookie.xml');
  static final _urlFile = File('$directoryExe\\msstore\\url.xml');
  static final _wuFile = File('$directoryExe\\msstore\\wu.xml');
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
      "Content-Type": "application/soap+xml"
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

  static const _dependencies = [
    "Microsoft.VCLibs",
    "Microsoft.NET",
    "Microsoft.UI",
    "Microsoft.WinJS",
    "Microsoft.WindowsAppRuntime",
  ];
  static bool isDependency(String name) =>
      _dependencies.any((e) => name.startsWith(RegExp(e)));

  static final _regex = RegExp(r'"WuCategoryId":"([^"]+)"');
  static final _namePattern = RegExp(r'^[^_]+', multiLine: true);

  // major.minor.build.revision
  // static final _versionPattern = RegExp(r'_(\d+\.\d+\.\d+\.\d+)_');

  // static const _validUWPExtensions = {
  //   "appx",
  //   "appxbundle",
  //   "msix",
  //   "msixbundle",
  //   // "eappx",
  //   // "eappxbundle",
  //   // "emsix",
  //   // "emsixbundle"
  // };

  static var _cookie = "";

  static final _cancelToken = CancelToken();
  static final _networkService = NetworkService();
  // final WinRegistryService = WinRegistryService();

  static const _instance = MSStoreService._private();
  factory MSStoreService() {
    return _instance;
  }
  const MSStoreService._private();

  static var _packages = List<MSStorePackagesInfoDTO>.empty(growable: true);
  List<MSStorePackagesInfoDTO> get packages => List.unmodifiable(_packages);

  Future<void> startProcess(String id, String ring) async {
    _packages = [];
    final productId = id.trim();

    if (isUWP(productId)) {
      if (_cookie.isEmpty) {
        _cookie = await _getCookie();
      }

      final String categoryID = await _getCategoryID(productId);

      await _parsePackages(
        await _fetchFileListXML(categoryID, _cookie, ring),
        ring,
      );

      if (_packages.isNotEmpty) {
        await _getLatestPackages();
        return;
      }
    }

    // Non-UWP apps mostly start with "XP"
    if (isNonUWP(productId)) {
      await _getNonAppxPackage(productId);
    }
  }

  /// Returns true if the product is UWP
  bool isUWP(String productId) {
    return productId.startsWith("9");
  }

  /*
   in normal cases, returning inverse of isUWP is enough, but who knows what Microsoft will do in the future 
  */

  /// Returns true if the product is not UWP
  bool isNonUWP(String productId) {
    return productId.toLowerCase().startsWith("xp");
  }

  Future<List<ProductsList>> searchProducts(String query, String ring) async {
    //"$_filteredSearchAPI?&Query=$query&FilteredCategories=AllProducts&hl=en-us${systemLanguage.toLowerCase()}&
    final response = await _networkService.get(
        "$_searchAPI?gl=US&hl=en-us&query=$query&mediaType=all&age=all&price=all&category=all&subscription=all",

// https://apps.microsoft.com/api/products/search?gl=GE&hl=en-us&query=xbox&cursor=
        options: _options);

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
      data: xml.XmlDocument.parse(_cookieFile.readAsStringSync()),
      options: _optionsSoapXML,
      cancelToken: _cancelToken,
    );

    if (response.statusCode == 200) {
      return xml.XmlDocument.parse(response.data)
          .findAllElements("EncryptedData")
          .first
          .innerText;
    }
    throw Exception('Failed to get a cookie');
  }

  Future<String> _getCategoryID(String id) async {
    //TODO: Implement proper way to get compatible language codes for the store API parameters

    // When Windows region is set to English (World), the language code isn't compatible with the store API
    //"$_storeAPI/products/$id?market=US&locale=en-us&deviceFamily=Windows.Desktop",
    final response = await _networkService.get(
        "$_storeAPI/products/$id?market=US&locale=en-us&deviceFamily=Windows.Desktop",
        cancelToken: _cancelToken);
    final skus = response.data["Payload"]["Skus"];
    if (response.statusCode == 200) {
      if (skus.isNotEmpty && skus.first["FulfillmentData"] != null) {
        return _regex.firstMatch(skus.first["FulfillmentData"])!.group(1)!;
      }
      throw Exception("The selected app is not UWP");
    }
    throw Exception('Failed to get category id');
  }

  Future<String> _fetchFileListXML(
      String categoryID, String cookie, String ring) async {
    final cookie2 = xml.XmlDocument.parse(_wuFile.readAsStringSync())
        .toString()
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
      final xmlDoc = xml.XmlDocument.parse(response.data)
          .toString()
          .replaceAll("&lt;", "<")
          .replaceAll("&gt;", ">");
      return xmlDoc;
    }
    throw Exception('Failed to get file list xml');
  }

  Future<void> _getNonAppxPackage(String id) async {
    final response = await _networkService.get(
        "$_storeAPI/packageManifests/$id?Market=US",
        cancelToken: _cancelToken);

    if (response.statusCode == 200) {
      final responseData =
          MSStoreNonUWPResponseDTO.fromJson(response.data).data;
      final versions = responseData?.versions;

      final urls = <String>{};

      for (final installer in versions!.first.installers!) {
        final installerUrl = installer.installerUrl!;
        final String extension = installer.installerType ??
            installerUrl.substring(installerUrl.lastIndexOf('.') + 1);

        if (extension.isEmpty || extension == "exe" || extension == "msi") {
          final name =
              "${versions.first.defaultLocale!.packageName}-${installer.architecture}";

          if (!urls.contains(installerUrl)) {
            _packages.add(
              MSStorePackagesInfoDTO(
                  name,
                  extension,
                  installerUrl,
                  "",
                  "",
                  id,
                  -1,
                  "",
                  null,
                  null,
                  installer.installerSwitches?.silent?.replaceAll('"', '')),
            );
            urls.add(installerUrl);
          }
        }
      }
    }
  }

  Future<void> _parsePackages(String xmlList, String ring) async {
    final xmlDoc = xml.XmlDocument.parse(xmlList);
    final packageMap = <String, String>{};

    for (final node in xmlDoc.findAllElements("File")) {
      if (node.getAttribute("InstallerSpecificIdentifier") != null) {
        final name = node.getAttribute("InstallerSpecificIdentifier")!;
        final digest = node.getAttribute("Digest")!;
        final modified = node.getAttribute("Modified")!;

        packageMap.putIfAbsent(
            name,
            () =>
                '${node.getAttribute("FileName")!.substring(node.getAttribute("FileName")!.lastIndexOf('.') + 1)}|${node.getAttribute("Size")!}|$digest|$modified');
      }
    }

    for (final node in xmlDoc.findAllElements("SecuredFragment")) {
      final name = node.parent!.parent!
          .getElement("ApplicabilityRules")!
          .getElement("Metadata")!
          .getElement("AppxPackageMetadata")!
          .getElement("AppxMetadata")!
          .getAttribute("PackageMoniker");
      if (name != null) {
        final package = packageMap[name]!;
        final ext = package.split('|')[0];
        final size = double.parse(package.split('|')[1]);
        final digest = package.split('|')[2];
        final lastModified = DateTime.parse(package.split('|')[3]);

        final updateIdentity =
            node.parent!.parent!.getElement('UpdateIdentity')!;

        if (!name.contains("Microsoft.Advertising") && name.contains("x64") ||
            name.contains("neutral") && !ext.startsWith("e")) {
          _packages.add(
            MSStorePackagesInfoDTO(
              name,
              ext,
              await _getUri(
                updateIdentity.getAttribute('UpdateID')!,
                updateIdentity.getAttribute('RevisionNumber')!,
                ring,
                digest,
              ),
              updateIdentity.getAttribute('RevisionNumber')!,
              updateIdentity.getAttribute('UpdateID')!,
              node.parent!.parent!.parent!.getElement('ID')!.value,
              size,
              digest,
              lastModified,
              null,
              null,
            ),
          );
        }
      }
    }
  }

  Future<String> _getUri(
      String updateID, String revision, String ring, String digets) async {
    final httpContent = xml.XmlDocument.parse(_urlFile.readAsStringSync())
        .toString()
        .replaceAll("{1}", updateID)
        .replaceAll("{2}", revision)
        .replaceAll("{3}", ring);

    final response = await _networkService.post("$_fe3Delivery/secured",
        data: httpContent,
        options: Options(headers: {
          HttpHeaders.contentTypeHeader: "application/soap+xml",
          "user-agent":
              "Mozilla/5.0 (Windows NT 10.0; rv:107.0) Gecko/20100101 Firefox/107.0",
        }),
        cancelToken: _cancelToken);

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

  // filters:

  /// Group packages with the same name
  Future<Map<String?, List<MSStorePackagesInfoDTO>>>
      _groupSamePackages() async {
    final groupedItems = _packages
        .asMap()
        .entries
        .map((entry) => MSStorePackagesInfoDTO(
            entry.value.name,
            entry.value.extension,
            entry.value.uri,
            entry.value.revisionNumber,
            entry.value.updateID,
            entry.value.id,
            entry.value.size,
            entry.value.digest,
            entry.value.lastModified,
            entry.key,
            null))
        .toList()
        .groupListsBy((item) => _namePattern.firstMatch(item.name!)?.group(0));

    return groupedItems;
  }

  Future<void> _getLatestPackages() async {
    final groupedPackages = await _groupSamePackages();

    final latestGenPackages = groupedPackages.values.map((group) {
      final versionMap = <MSStorePackagesInfoDTO, DateTime>{};
      for (final package in group) {
        if (versionMap.isEmpty) {
          versionMap[package] = package.lastModified!;
        } else {
          final lastSavedVer = versionMap.values.first;
          final currentVer = package.lastModified!;

          if (currentVer.isAfter(lastSavedVer)) {
            versionMap.clear();
            versionMap[package] = currentVer;
          }
        }
      }
      return versionMap.keys.first;
    }).toList();

    _packages = latestGenPackages;
  }

  Future<List<Response>> downloadPackages(String productId, String ring) async {
    final path = "$_storeFolder\\$productId\\$ring";
    final result = <Response>[];

    for (final item in _packages) {
      final downloadPath =
          isDependency(item.name!) ? "$path\\Dependencies" : path;
      final response = await _networkService.downloadFile(
          item.uri!, "$downloadPath\\${item.name}.${item.extension}");

      result.add(response);
    }
    return result;
  }

  Future<List<ProcessResult>> installPackages(String id, String ring) async {
    return isUWP(id)
        ? await _installUWPPackages(id, ring)
        : await _installNonUWPPackages(id, ring);
  }

  Future<List<ProcessResult>> _installUWPPackages(
      String id, String ring) async {
    final path = "$_storeFolder\\$id\\$ring";
    final dir = Directory(path).listSync();
    final results = <ProcessResult>[];

    if (dir.isNotEmpty) {
      for (final d in dir) {
        if (d is File) {
          results.add(await _addAppxProcess(d.path));
        }
        if (d is Directory) {
          final deps = Directory("$path\\Dependencies").listSync();
          for (final file in deps) {
            if (file is File) {
              results.add(await _addAppxProcess(file.path));
            }
          }
        }
      }
    }
    return results;
  }

  Future<ProcessResult> _addAppxProcess(String path) async {
    return await Process.run(
      "powershell",
      ["Add-AppxPackage -Path $path -ForceApplicationShutdown"],
    );
  }

  Future<List<ProcessResult>> _installNonUWPPackages(
      String id, String ring) async {
    final fileList = Directory("$_storeFolder\\$id\\$ring").listSync();
    final results = <ProcessResult>[];

    for (final file in fileList) {
      if (file is File) {
        final filePath = file.path;
        final arguments = _packages
                .firstWhereOrNull((e) =>
                    e.name == (file.path.split('\\').last).split(".").first)
                ?.commandLines
                ?.split(' ') ??
            List<String>.empty();

        results.add(
          await runExecutableArguments(
            filePath,
            arguments,
            verbose: true,
          ),
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
