import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:raygun_cli/src/core/raygun_api.dart';

class SymbolsApi {
  const SymbolsApi({
    required this.httpClient,
  });

  /// Creates a new instance of [SymbolsApi] with the provided [httpClient].
  SymbolsApi.create() : httpClient = http.Client();

  final http.Client httpClient;

  /// Uploads a Flutter symbols file to Raygun.
  Future<bool> uploadSymbols({
    required String appId,
    required String token,
    required String path,
    required String version,
  }) async {
    final request = RaygunMultipartRequestBuilder(
      'https://api.raygun.com/v3/applications/$appId/flutter-symbols',
      'PUT',
    )
        .addBearerToken(token)
        .addField('version', version)
        .addFile('file', path)
        .build();

    final response = await httpClient.send(request);
    if (response.statusCode == 200 || response.statusCode == 201) {
      print('Symbols file uploaded successfully: ${response.statusCode}');
      return true;
    } else {
      print('Error uploading symbols file: ${response.statusCode}');
      final responseBody = await response.stream.bytesToString();
      print('Response body: $responseBody');
      return false;
    }
  }

  /// Lists all Flutter symbols files in Raygun for the given application.
  Future<bool> listSymbols({
    required String appId,
    required String token,
  }) async {
    final request = RaygunMultipartRequestBuilder(
      'https://api.raygun.com/v3/applications/$appId/flutter-symbols',
      'GET',
    ).addBearerToken(token).build();

    final response = await httpClient.send(request);
    if (response.statusCode == 200) {
      final string = await response.stream.bytesToString();
      final listItems = jsonDecode(string) as List<dynamic>;
      print('');
      print('List of symbols:');
      print('');
      for (final item in listItems) {
        print('Symbols File: ${item['name']}');
        print('Identifier: ${item['identifier']}');
        print('App Version: ${item['version']}');
        print('');
      }
      return true;
    } else {
      print('Error getting list. Response code: ${response.statusCode}');
      return false;
    }
  }

  /// Deletes a Flutter symbols file in Raygun.
  Future<bool> deleteSymbols({
    required String appId,
    required String token,
    required String id,
  }) async {
    final request = RaygunMultipartRequestBuilder(
      'https://api.raygun.com/v3/applications/$appId/flutter-symbols/$id',
      'DELETE',
    ).addBearerToken(token).build();

    final response = await httpClient.send(request);
    if (response.statusCode == 204) {
      print('Deleted: $id');
      return true;
    } else {
      print('Error deleting $id. Response code: ${response.statusCode}');
      return false;
    }
  }
}
