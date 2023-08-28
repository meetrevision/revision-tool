import 'dart:io';
import 'package:dio/dio.dart';
// ignore: depend_on_referenced_packages

class Network {
  static final Network _instance = Network._private();

  final _dio = Dio();
  static final _options = Options(
    headers: {
      "user-agent":
          "Mozilla/5.0 (Windows NT 10.0; rv:107.0) Gecko/20100101 Firefox/107.0",
      "content-type": "application/json;charset=utf-8",
      "accept": "application/json",
    },
  );

  factory Network() {
    return _instance;
  }

  Network._private();

  Future<Map<String, dynamic>> getJSON(String url) async {
    var response = await _dio.get(url, options: _options);

    final responseJson = Map<String, dynamic>.from(response.data);

    if (response.statusCode == 200) {
      return responseJson;
    } else {
      throw Exception('Failed to load');
    }
  }

  Future downloadNewVersion(String url, String path) async {
    await _dio.download(
      url,
      "$path\\RevisionTool-Setup.exe",
    );
    await openExeFile("$path\\RevisionTool-Setup.exe");
  }

  Future<void> openExeFile(String filePath) async {
    await Process.start(filePath,
        ['/VERYSILENT', '/RESTARTAPPLICATIONS', r'/TASKS="desktopicon"']);
    await File(filePath).delete();
  }

  // Future<String> getDownloadFilesHTML(String productId) async {
  //   final response = await _dio.post(
  //       "https://store.rg-adguard.net/api/GetFiles",
  //       data: {
  //         "type": "ProductId",
  //         "url": productId,
  //         "ring": "Retail",
  //         "lang": "en-US"
  //       },
  //       options: Options(
  //         headers: {
  //           "user-agent":
  //               "Mozilla/5.0 (Windows NT 10.0; rv:107.0) Gecko/20100101 Firefox/107.0",
  //           "referer": "https://store.rg-adguard.net/",
  //           "Accept": "*/*",
  //           "Content-Type": "application/x-www-form-urlencoded"
  //         },
  //       ));

  //   if (response.statusCode == 200) {
  //     // print(response.data);
  //     return response.data;
  //   } else {
  //     throw Exception('Failed to load');
  //   }
  // }

// TODO: Implement this method
  // List<String> extractDownloadLinks(String htmlContent) {
  // final document = parse(htmlContent);

  // final links = document.querySelectorAll("a[href]");

  // final downloadLinks = <String>[];
  // for (var link in links) {
  //   final url = link.attributes['href'];
  //   if (url != null &&
  //       (url.endsWith(".msix") ||
  //           url.endsWith(".appx") ||
  //           url.endsWith(".msixbundle")) &&
  //       url.contains("x64")) {
  //     downloadLinks.add(url);
  //   }
  // }

  // return downloadLinks;
  // }
}
