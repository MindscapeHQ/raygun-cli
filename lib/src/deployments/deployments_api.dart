import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:raygun_cli/src/core/raygun_api.dart';

class DeploymentsApi {
  const DeploymentsApi(this.httpClient);

  final http.Client httpClient;

  DeploymentsApi.create() : httpClient = http.Client();

  /// Creates a deployment in Raygun.
  /// Returns true if the deployment was created successfully.
  Future<bool> createDeployment({
    required String token,
    required String apiKey,
    required String version,
    String? ownerName,
    String? emailAddress,
    String? comment,
    String? scmIdentifier,
    String? scmType,
  }) async {
    final url =
        'https://api.raygun.com/v3/applications/api-key/$apiKey/deployments';

    final payload = {
      'version': version,
      'ownerName': ?ownerName,
      'emailAddress': ?emailAddress,
      'comment': ?comment,
      'scmIdentifier': ?scmIdentifier,
      'scmType': ?scmType,
      'deployedAt': DateTime.now().toUtc().toIso8601String(),
    };

    final request = RaygunPostRequestBuilder(
      url,
    ).addBearerToken(token).addJsonBody(payload).build();

    try {
      final response = await httpClient.send(request);
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('Success creating deployment: ${response.statusCode}');
        print(
          'Deployment identifier: ${jsonDecode(responseBody)['identifier']}',
        );
        return true;
      }

      print('Error creating deployment: ${response.statusCode}');
      print('Response: $responseBody');
      return false;
    } catch (e) {
      print('Exception while creating deployment: $e');
      return false;
    }
  }
}
