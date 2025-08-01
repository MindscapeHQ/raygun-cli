import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:raygun_cli/src/sourcemap/sourcemap_api.dart';
import 'package:test/test.dart';

import 'sourcemap_api_test.mocks.dart';

@GenerateMocks([http.Client])
void main() {
  group('SourcemapApi', () {
    late MockClient mockClient;
    late SourcemapApi sourcemapApi;

    setUp(() {
      mockClient = MockClient();
      sourcemapApi = SourcemapApi(httpClient: mockClient);
    });

    group('uploadSourcemap', () {
      late File testFile;

      setUpAll(() {
        // Create a temporary test file
        testFile = File('test_sourcemap.js.map');
        testFile.writeAsStringSync('{"version": 3, "sources": ["test.js"]}');
      });

      tearDownAll(() {
        // Clean up the test file after all tests
        try {
          if (testFile.existsSync()) {
            testFile.deleteSync();
          }
        } catch (e) {
          // Ignore if the file cannot be deleted
        }
      });

      test('returns true when upload is successful (200)', () async {
        final response = http.StreamedResponse(
          Stream.value([]),
          200,
        );

        when(mockClient.send(any)).thenAnswer((_) async => response);

        final result = await sourcemapApi.uploadSourcemap(
          appId: 'test-app-id',
          token: 'test-token',
          path: 'test_sourcemap.js.map',
          uri: 'https://example.com/app.js',
        );

        expect(result, true);
        verify(mockClient.send(any)).called(1);
      });

      test('returns false when upload fails', () async {
        final response = http.StreamedResponse(
          Stream.value([]),
          400,
        );

        when(mockClient.send(any)).thenAnswer((_) async => response);

        final result = await sourcemapApi.uploadSourcemap(
          appId: 'test-app-id',
          token: 'test-token',
          path: 'test_sourcemap.js.map',
          uri: 'https://example.com/app.js',
        );

        expect(result, false);
      });

      test('returns false when file does not exist', () async {
        final result = await sourcemapApi.uploadSourcemap(
          appId: 'test-app-id',
          token: 'test-token',
          path: 'nonexistent_sourcemap.js.map',
          uri: 'https://example.com/app.js',
        );

        expect(result, false);
        verifyNever(mockClient.send(any));
      });
    });
  });
}
