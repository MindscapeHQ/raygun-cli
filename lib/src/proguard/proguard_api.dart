import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:raygun_cli/src/core/raygun_api.dart';

class ProguardApi {
  const ProguardApi(this.httpClient);

  final http.Client httpClient;

  ProguardApi.create() : httpClient = http.Client();

  /// Uploads a Proguard/R8 mapping file to Raygun.
  /// Returns true if the upload was successful.
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

    final builder = RaygunMultipartRequestBuilder(
      'https://app.raygun.com/upload/proguardsymbols/$appId?authToken=$externalAccessToken',
      'POST',
    ).addFile('file', path).addField('version', version);

    if (overwrite) {
      builder.addField('overwrite', 'true');
    }

    final request = builder.build();

    try {
      final response = await httpClient.send(request);
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        print(
          'Success uploading Proguard/R8 mapping file: ${response.statusCode}',
        );
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
}
