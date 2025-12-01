import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:raygun_cli/src/core/raygun_api.dart';

class DsymApi {
  const DsymApi(this.httpClient);

  final http.Client httpClient;

  DsymApi.create() : httpClient = http.Client();

  /// Uploads a dSYM zip file to Raygun.
  /// Returns true if the upload was successful.
  Future<bool> uploadDsym({
    required String appId,
    required String externalAccessToken,
    required String path,
  }) async {
    final file = File(path);
    if (!file.existsSync()) {
      print('$path: file not found!');
      return false;
    }
    print('Uploading: $path');

    final request = RaygunMultipartRequestBuilder(
      'https://app.raygun.com/dashboard/$appId/settings/symbols?authToken=$externalAccessToken',
      'POST',
    ).addFile('DsymFile', path).build();

    try {
      final response = await httpClient.send(request);
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        print('Success uploading dSYM file: ${response.statusCode}');
        print('Result: $responseBody');
        return true;
      }

      print('Error uploading dSYM file: ${response.statusCode}');
      print('Response: $responseBody');
      return false;
    } catch (e) {
      print('Exception while uploading dSYM file: $e');
      return false;
    }
  }
}
