import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:raygun_cli/src/proguard/proguard_api.dart';
import 'package:test/test.dart';

import 'proguard_api_test.mocks.dart';

@GenerateMocks([http.Client])
void main() {
  group('ProguardApi', () {
    late MockClient mockClient;
    late ProguardApi proguardApi;

    setUp(() {
      mockClient = MockClient();
      proguardApi = ProguardApi(mockClient);
    });

    group('uploadProguardMapping', () {
      test('returns true when upload is successful (200)', () async {
        // Create a temporary test file
        final testFile = File('test_mapping.txt');
        testFile.writeAsStringSync('test proguard mapping content');

        final response = http.StreamedResponse(
          Stream.value(utf8.encode('Upload successful')),
          200,
        );

        when(mockClient.send(any)).thenAnswer((_) async => response);

        final result = await proguardApi.uploadProguardMapping(
          appId: 'test-app-id',
          externalAccessToken: 'test-token',
          path: 'test_mapping.txt',
          version: '1.0.0',
          overwrite: false,
        );

        expect(result, true);
        verify(mockClient.send(any)).called(1);

        // Clean up
        testFile.deleteSync();
      });

      test(
        'returns true when upload is successful with overwrite flag',
        () async {
          final testFile = File('test_mapping.txt');
          testFile.writeAsStringSync('test proguard mapping content');

          final response = http.StreamedResponse(
            Stream.value(utf8.encode('Upload successful')),
            200,
          );

          when(mockClient.send(any)).thenAnswer((_) async => response);

          final result = await proguardApi.uploadProguardMapping(
            appId: 'test-app-id',
            externalAccessToken: 'test-token',
            path: 'test_mapping.txt',
            version: '1.0.0',
            overwrite: true,
          );

          expect(result, true);

          testFile.deleteSync();
        },
      );

      test('returns false when upload fails', () async {
        final testFile = File('test_mapping.txt');
        testFile.writeAsStringSync('test proguard mapping content');

        final response = http.StreamedResponse(
          Stream.value(utf8.encode('Bad request')),
          400,
        );

        when(mockClient.send(any)).thenAnswer((_) async => response);

        final result = await proguardApi.uploadProguardMapping(
          appId: 'test-app-id',
          externalAccessToken: 'test-token',
          path: 'test_mapping.txt',
          version: '1.0.0',
          overwrite: false,
        );

        expect(result, false);

        testFile.deleteSync();
      });

      test('returns false when file does not exist', () async {
        final result = await proguardApi.uploadProguardMapping(
          appId: 'test-app-id',
          externalAccessToken: 'test-token',
          path: 'nonexistent_file.txt',
          version: '1.0.0',
          overwrite: false,
        );

        expect(result, false);
        verifyNever(mockClient.send(any));
      });

      test('handles network exceptions and returns false', () async {
        final testFile = File('test_mapping.txt');
        testFile.writeAsStringSync('test proguard mapping content');

        when(mockClient.send(any)).thenThrow(Exception('Network error'));

        final result = await proguardApi.uploadProguardMapping(
          appId: 'test-app-id',
          externalAccessToken: 'test-token',
          path: 'test_mapping.txt',
          version: '1.0.0',
          overwrite: false,
        );

        expect(result, false);

        testFile.deleteSync();
      });

      test('returns false for 401 unauthorized', () async {
        final testFile = File('test_mapping.txt');
        testFile.writeAsStringSync('test proguard mapping content');

        final response = http.StreamedResponse(
          Stream.value(utf8.encode('Unauthorized')),
          401,
        );

        when(mockClient.send(any)).thenAnswer((_) async => response);

        final result = await proguardApi.uploadProguardMapping(
          appId: 'test-app-id',
          externalAccessToken: 'invalid-token',
          path: 'test_mapping.txt',
          version: '1.0.0',
          overwrite: false,
        );

        expect(result, false);

        testFile.deleteSync();
      });

      test('returns false for 500 internal server error', () async {
        final testFile = File('test_mapping.txt');
        testFile.writeAsStringSync('test proguard mapping content');

        final response = http.StreamedResponse(
          Stream.value(utf8.encode('Internal server error')),
          500,
        );

        when(mockClient.send(any)).thenAnswer((_) async => response);

        final result = await proguardApi.uploadProguardMapping(
          appId: 'test-app-id',
          externalAccessToken: 'test-token',
          path: 'test_mapping.txt',
          version: '1.0.0',
          overwrite: false,
        );

        expect(result, false);

        testFile.deleteSync();
      });
    });
  });
}
