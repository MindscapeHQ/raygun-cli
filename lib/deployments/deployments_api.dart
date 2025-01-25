import 'dart:convert';
import 'package:http/http.dart' as http;

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
    if (ownerName != null) 'ownerName': ownerName,
    if (emailAddress != null) 'emailAddress': emailAddress,
    if (comment != null) 'comment': comment,
    if (scmIdentifier != null) 'scmIdentifier': scmIdentifier,
    if (scmType != null) 'scmType': scmType,
    'deployedAt': DateTime.now().toUtc().toIso8601String(),
  };

  try {
    final response = await http.post(
      Uri.parse(url),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(payload),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      print('Success creating deployment: ${response.statusCode}');
      print(
          'Deployment identifier: ${jsonDecode(response.body)['identifier']}');
      return true;
    }

    print('Error creating deployment: ${response.statusCode}');
    print('Response: ${response.body}');
    return false;
  } catch (e) {
    print('Exception while creating deployment: $e');
    return false;
  }
}
