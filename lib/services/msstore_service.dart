import 'dart:io';
import 'package:collection/collection.dart';
import 'package:dio/dio.dart';
import 'package:process_run/cmd_run.dart';
import 'package:process_run/shell_run.dart';
import '../models/ms_store/non_uwp_response.dart';
import '../models/ms_store/search_response.dart';
import '../models/ms_store/packages_info.dart';
import 'package:xml/xml.dart' as xml;
import '../utils.dart';

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

  static final _dio = Dio();
  static final _cancelToken = CancelToken();
  // final _registryUtilsService = RegistryUtilsService();

  static const _instance = MSStoreService._private();
  factory MSStoreService() {
    return _instance;
  }
  const MSStoreService._private();

  static var _packages = List<PackagesInfo>.empty(growable: true);
  List<PackagesInfo> get packages => List.unmodifiable(_packages);

  Future<void> startProcess(String productId, String ring) async {
    _packages = [];

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
        _getLatestPackages();
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
    return productId.startsWith("XP");
  }

  Future<List<ProductsList>> searchProducts(String query, String ring) async {
    //"$_filteredSearchAPI?&Query=$query&FilteredCategories=AllProducts&hl=en-us${systemLanguage.toLowerCase()}&
    final response = await _dio.get(
        "$_searchAPI?gl=US&hl=en-us&query=$query&mediaType=all&age=all&price=all&category=all&subscription=all",

// https://apps.microsoft.com/api/products/search?gl=GE&hl=en-us&query=xbox&cursor=
        options: _options);

    if (response.statusCode == 200) {
      final responseData = SearchResponse.fromJson(response.data);
      return [
        ...(responseData.highlightedList ?? List<ProductsList>.empty()),
        ...(responseData.productsList ?? List<ProductsList>.empty()),
      ];
    }
    throw Exception('Failed to search the product');
  }

  Future<String> _getCookie() async {
    final response = await _dio.post(
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
    final response = await _dio.get(
        "$_storeAPI/products/$id?market=${systemLanguage.substring(3).toUpperCase()}&locale=$systemLanguage&deviceFamily=Windows.Desktop",
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

    final response = await _dio.post(
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

  Future<List<PackagesInfo>> _getNonAppxPackage(String id) async {
    final response = await _dio.get("$_storeAPI/packageManifests/$id?Market=US",
        cancelToken: _cancelToken);

    if (response.statusCode == 200) {
      final responseData = NonUWPResponse.fromJson(response.data).data;
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
            packages.add(
              PackagesInfo(
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
    return packages;
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
            PackagesInfo(
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

    final response = await _dio.post("$_fe3Delivery/secured",
        data: httpContent,
        options: Options(headers: {
          HttpHeaders.contentTypeHeader: "application/soap+xml",
          "user-agent":
              "Mozilla/5.0 (Windows NT 10.0; rv:107.0) Gecko/20100101 Firefox/107.0",
        }),
        cancelToken: _cancelToken);

    if (response.statusMessage == "OK") {
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
  Map<String?, List<PackagesInfo>> _groupSamePackages() {
    final groupedItems = _packages
        .asMap()
        .entries
        .map((entry) => PackagesInfo(
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

  void _getLatestPackages() {
    final groupedPackages = _groupSamePackages();

    final latestGenPackages = groupedPackages.values.map((group) {
      final versionMap = <PackagesInfo, DateTime>{};
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
      final response = await _dio.download(
        item.uri!,
        "$path\\${item.name}.${item.extension}",
        cancelToken: _cancelToken,
      );
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
    return await run(
      'powershell -NoP -ExecutionPolicy Bypass -NonInteractive -C "& {\$appxFiles = Get-ChildItem -Path "$_storeFolder\\$id"; foreach (\$file in \$appxFiles) { Add-AppxPackage -ForceApplicationShutdown -Path \$file.FullName;}}"',
      verbose: false,
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
            .firstWhereOrNull(
                (e) => e.name == (file.path.split('\\').last).split('.').last)
            ?.commandLines
            ?.split(' ');

        results.add(
          await runExecutableArguments(
            filePath,
            arguments ?? List<String>.empty(),
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
