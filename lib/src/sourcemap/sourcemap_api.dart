import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:raygun_cli/src/core/raygun_api.dart';

class SourcemapApi {
  const SourcemapApi({
    required this.httpClient,
  });

  /// Creates a new instance of [SourcemapApi] with the provided [httpClient].
  SourcemapApi.create() : httpClient = http.Client();

  final http.Client httpClient;

  /// Uploads a sourcemap file to Raygun.
  /// returns true if the upload was successful.
  Future<bool> uploadSourcemap({
    required String appId,
    required String token,
    required String path,
    required String uri,
  }) async {
    final file = File(path);
    if (!file.existsSync()) {
      print('$path: file not found!');
      return false;
    }
    print('Uploading: $path');

    final request = RaygunMultipartRequestBuilder(
      'https://api.raygun.com/v3/applications/$appId/source-maps',
      'PUT',
    ).addBearerToken(token).addField('uri', uri).addFile('file', path).build();

    final response = await httpClient.send(request);
    if (response.statusCode == 200) {
      print('File uploaded succesfully!');
      return true;
    } else {
      print('Error uploading file. Response code: ${response.statusCode}');
      return false;
    }
  }
}
