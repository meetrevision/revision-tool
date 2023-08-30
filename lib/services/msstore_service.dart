import 'dart:io';
import 'package:collection/collection.dart';
import 'package:dio/dio.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:process_run/cmd_run.dart';
import 'package:process_run/shell_run.dart';
import '../models/filtered_response.dart';
import '../models/ms_store/packages_info.dart';
import 'package:xml/xml.dart' as xml;
import '../models/products_list.dart';
import '../utils.dart';
import 'registry_utils_service.dart';

class MSStoreService {
  static final MSStoreService _instance = MSStoreService._private();

  static final _cookieFile = File('$directoryExe\\msstore\\cookie.xml');
  static final _urlFile = File('$directoryExe\\msstore\\url.xml');
  static final _wuFile = File('$directoryExe\\msstore\\wu.xml');
  static const _fe3Delivery =
      "https://fe3.delivery.mp.microsoft.com/ClientWebService/client.asmx";
  static const _storeAPI = "https://storeedgefd.dsx.mp.microsoft.com/v9.0";
  static const _filteredSearchAPI =
      "https://apps.microsoft.com/store/api/Products/GetFilteredSearch";
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
  static final _namePattern = RegExp(r'^([A-Za-z]+\.)+[A-Za-z]+');
  static final _versionPattern = RegExp(r'_(\d+\.\d+\.\d+\.\d+)_');

  // static final _genPattern = RegExp(r'\.(\d\.\d)_');

  static const _validExtensions = [
    "appx",
    "appxbundle",
    "msix",
    "msixbundle",
    "exe",
    "msi",
    "eappx",
    "eappxbundle",
    "emsix",
    "emsixbundle"
  ];
  static var _cookie = "";

  final _dio = Dio();
  final _cancelToken = CancelToken();
  final RegistryUtilsService _registryUtilsService = RegistryUtilsService();

  factory MSStoreService() {
    return _instance;
  }

  MSStoreService._private();

  Future<List<PackagesInfo>> startProcess(String productId, String ring) async {
    if (_cookie.isEmpty) {
      _cookie = await _getCookie();
    }
    debugPrint("Cookie: $_cookie");
    final String categoryID = await _getCategoryID(productId);
    debugPrint("Category ID: $categoryID");
    final List<PackagesInfo> packages = await _getPackages(
        await _getFileListXML(categoryID, _cookie, ring), ring);

    if (packages.isNotEmpty) {
      // filter packages
      final groupedPackages = _groupSamePackages(packages);
      final filteredPackages = _getLatestPackages(groupedPackages);

      if (filteredPackages.isEmpty) {
        return packages;
      }

      return filteredPackages;
    } else {
      throw Exception(
          "No packages found, non-UWP apps needs to be implemented");
    }
  }

  Future<List<ProductsList>> searchProducts(String query) async {
    //"$_filteredSearchAPI?&Query=$query&FilteredCategories=AllProducts&hl=en-us${systemLanguage.toLowerCase()}&
    final response = await _dio.get(
        "$_filteredSearchAPI?&Query=$query&FilteredCategories=AllProducts&hl=en-us&gl=us",
        options: _options);

    if (response.statusCode == 200) {
      return FilteredResponse.fromJson(response.data).productsList ?? [];
    }
    throw Exception('Failed to search products');
  }

  Future<String> _getCookie() async {
    final response = await _dio.post(_fe3Delivery,
        data: xml.XmlDocument.parse(_cookieFile.readAsStringSync()),
        options: _optionsSoapXML,
        cancelToken: _cancelToken);

    if (response.statusCode == 200) {
      return xml.XmlDocument.parse(response.data)
          .findAllElements("EncryptedData")
          .first
          .innerText;
    }
    return "";
  }

  Future<String> _getCategoryID(String id) async {
    final response = await _dio.get(
        "$_storeAPI/products/$id?market=${systemLanguage.substring(3).toUpperCase()}&locale=$systemLanguage&deviceFamily=Windows.Desktop",
        cancelToken: _cancelToken);
    final skus = response.data["Payload"]["Skus"];
    if (response.statusCode == 200) {
      if (skus.isNotEmpty && skus.first["FulfillmentData"] != null) {
        return _regex.firstMatch(skus.first["FulfillmentData"])!.group(1)!;
      } else {
        throw Exception("The selected app is not UWP");
      }
    }
    throw Exception('Failed to get category id');
  }

  Future<String> _getFileListXML(
      String categoryID, String cookie, String ring) async {
    final cookie2 = xml.XmlDocument.parse(_wuFile.readAsStringSync())
        .toString()
        .replaceAll("{1}", cookie)
        .replaceAll("{2}", categoryID)
        .replaceAll("{3}", ring);

    final response = await _dio.post(_fe3Delivery,
        data: cookie2, options: _optionsSoapXML, cancelToken: _cancelToken);

    if (response.statusCode == 200) {
      return xml.XmlDocument.parse(response.data)
          .toString()
          .replaceAll("&lt;", "<")
          .replaceAll("&gt;", ">");
    }
    throw Exception('Failed to get file list xml');
  }

// TODO: Implement this method
  Future<List<PackagesInfo>> getNonAppxPackage(String appID) async {
    // final response = await _dio.get(
    //     "https://storeedgefd.dsx.mp.microsoft.com/v9.0/packageManifests/$appID",
    //     cancelToken: _cancelToken);
    // final packages = <PackagesInfo>[];
    // final pi = PackagesInfo("", "", "", "", "", appID, -1, "");
    // print(response.data);

    // final nonUWPPackage = NonUWPPackageDown.fromJson(jsonDecode(response));

    return List.empty();
  }

  Future<List<PackagesInfo>> _getPackages(String xmlList, String ring) async {
    final List<PackagesInfo> packages = [];
    final xmlDoc = xml.XmlDocument.parse(xmlList);
    final Map<String, String> packageMap = {};

    for (final node in xmlDoc.findAllElements("File")) {
      if (node.getAttribute("InstallerSpecificIdentifier") != null) {
        String name = node.getAttribute("InstallerSpecificIdentifier")!;
        String digest = node.getAttribute("Digest")!;

        packageMap.putIfAbsent(
            name,
            () =>
                '${node.getAttribute("FileName")!.substring(node.getAttribute("FileName")!.lastIndexOf('.') + 1)}|${node.getAttribute("Size")!}|$digest');
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
        final extension = package.split('|')[0];
        final digest = package.split('|')[2];
        final updateIdentity =
            node.parent!.parent!.getElement('UpdateIdentity')!;

        if (_validExtensions.contains(extension) &&
                !name.contains("Microsoft.Advertising") &&
                name.contains("x64") ||
            name.contains("neutral")) {
          packages.add(PackagesInfo(
            name,
            extension,
            await _getUri(updateIdentity.getAttribute('UpdateID')!,
                updateIdentity.getAttribute('RevisionNumber')!, ring, digest),
            updateIdentity.getAttribute('RevisionNumber')!,
            updateIdentity.getAttribute('UpdateID')!,
            node.parent!.parent!.parent!.getElement('ID')!.value,
            double.parse(package.split('|')[1]),
            digest,
            null,
          ));
        }
      }
    }

    return packages;
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
  Map<String?, List<PackagesInfo>> _groupSamePackages(
      List<PackagesInfo> packages) {
    final groupedItems = packages
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
            entry.key))
        .toList()
        .groupListsBy((item) => _namePattern.firstMatch(item.name!)?.group(0));

    return groupedItems;
  }

  /// Returns a list of latest UWP packages
  List<PackagesInfo> _getLatestPackages(
      Map<String?, List<PackagesInfo>> groupedPackages) {
    if (groupedPackages.isEmpty) return [];

    final latestGenPackages = groupedPackages.values
        .map((group) => group.fold(<PackagesInfo>[], (acc, package) {
              final version = _parseVersion(package.name!);
              final maxVersion = acc.fold(
                  -1,
                  (accVersion, PackagesInfo accPackage) =>
                      _parseVersion(accPackage.name!) > accVersion
                          ? _parseVersion(accPackage.name!)
                          : accVersion);
              if (version > maxVersion) {
                return [package];
              } else if (version == maxVersion) {
                acc.add(package);
              }
              return acc;
            }))
        .expand((i) => i)
        .toList();

    return latestGenPackages;
  }

  int _parseVersion(String name) {
    final match = _versionPattern.firstMatch(name);
    if (match == null) return -1;

    List<String> versionParts = match.group(1)!.replaceAll('_', '').split('.');
    if (versionParts.isNotEmpty) {
      final lastPart = versionParts.last;
      versionParts[versionParts.length - 1] = lastPart.characters.first == '0'
          ? lastPart
          : lastPart.replaceAll(RegExp(r'0+$'), '');
    }
    return int.parse(versionParts.join(''));
  }

  Future<List<ProcessResult>> installUWPPackages(String path) async {
    return await run(
      'powershell -NoP -ExecutionPolicy Bypass -NonInteractive -C "& {\$appxFiles = Get-ChildItem -Path "$path"; foreach (\$file in \$appxFiles) { Add-AppxPackage -Path \$file.FullName; echo "\$(\$file.Name)";}}"',
    );
  }
}
