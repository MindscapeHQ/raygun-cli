import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:raygun_cli/src/deployments/deployments_api.dart';
import 'package:test/test.dart';

import 'deployments_api_test.mocks.dart';

@GenerateMocks([http.Client])
void main() {
  group('DeploymentsApi', () {
    late MockClient mockClient;
    late DeploymentsApi deploymentsApi;

    setUp(() {
      mockClient = MockClient();
      deploymentsApi = DeploymentsApi(mockClient);
    });

    group('createDeployment', () {
      test(
        'returns true when deployment creation is successful (201)',
        () async {
          final responseBody = jsonEncode({'identifier': 'test-deployment-id'});
          final response = http.StreamedResponse(
            Stream.value(utf8.encode(responseBody)),
            201,
          );

          when(mockClient.send(any)).thenAnswer((_) async => response);

          final result = await deploymentsApi.createDeployment(
            token: 'test-token',
            apiKey: 'test-api-key',
            version: '1.0.0',
          );

          expect(result, true);
          verify(mockClient.send(any)).called(1);
        },
      );

      test('returns true with all optional parameters', () async {
        final responseBody = jsonEncode({'identifier': 'test-deployment-id'});
        final response = http.StreamedResponse(
          Stream.value(utf8.encode(responseBody)),
          200,
        );

        when(mockClient.send(any)).thenAnswer((_) async => response);

        final result = await deploymentsApi.createDeployment(
          token: 'test-token',
          apiKey: 'test-api-key',
          version: '1.0.0',
          ownerName: 'John Doe',
          emailAddress: 'john@example.com',
          comment: 'Test deployment',
          scmIdentifier: 'abc123',
          scmType: 'GitHub',
        );

        expect(result, true);
        verify(mockClient.send(any)).called(1);
      });

      test('returns false when deployment creation fails (400)', () async {
        final response = http.StreamedResponse(
          Stream.value(utf8.encode('Bad request')),
          400,
        );

        when(mockClient.send(any)).thenAnswer((_) async => response);

        final result = await deploymentsApi.createDeployment(
          token: 'test-token',
          apiKey: 'test-api-key',
          version: '1.0.0',
        );

        expect(result, false);
        verify(mockClient.send(any)).called(1);
      });

      test('handles network exceptions and returns false', () async {
        when(mockClient.send(any)).thenThrow(Exception('Network error'));

        final result = await deploymentsApi.createDeployment(
          token: 'test-token',
          apiKey: 'test-api-key',
          version: '1.0.0',
        );

        expect(result, false);
        verify(mockClient.send(any)).called(1);
      });

      test('handles JSON decode error and returns false', () async {
        final response = http.StreamedResponse(
          Stream.value(utf8.encode('invalid json')),
          200,
        );

        when(mockClient.send(any)).thenAnswer((_) async => response);

        final result = await deploymentsApi.createDeployment(
          token: 'test-token',
          apiKey: 'test-api-key',
          version: '1.0.0',
        );

        expect(result, false);
        verify(mockClient.send(any)).called(1);
      });
    });
  });
}
