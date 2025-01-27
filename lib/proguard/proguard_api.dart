import 'dart:io';

import 'package:http/http.dart' as http;

Future<bool> uploadProguardMapping({
  required String appId,
  required String externalAccessToken,
  required String path,
  required String version,
  required bool overwrite,
}) async {
  final file = File(path);
  if (!file.existsSync()) {
    print('$path: file not found!');
    return false;
  }
  print('Uploading: $path');

  final url =
      'https://app.raygun.com/upload/proguardsymbols/$appId?authToken=$externalAccessToken';

  final request = http.MultipartRequest('POST', Uri.parse(url));
  request.files.add(
    http.MultipartFile(
      'file',
      file.readAsBytes().asStream(),
      file.lengthSync(),
      filename: path.split("/").last,
    ),
  );
  request.fields.addAll({
    'version': version,
  });
  if (overwrite) {
    request.fields.addAll({
      'overwrite': 'true',
    });
  }
  try {
    final response = await request.send();
    final responseBody = await response.stream.bytesToString();

    if (response.statusCode == 200) {
      print(
          'Success uploading Proguard/R8 mapping file: ${response.statusCode}');
      print('Result: $responseBody');
      return true;
    }

    print('Error uploading Proguard/R8 mapping file: ${response.statusCode}');
    print('Response: $responseBody');
    return false;
  } catch (e) {
    print('Exception while uploading Proguard/R8 mapping file: $e');
    return false;
  }
}
