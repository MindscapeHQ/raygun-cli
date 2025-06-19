import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:raygun_cli/src/sourcemap/sourcemap_api.dart';
import 'package:test/test.dart';

import 'sourcemap_api_test.mocks.dart';

@GenerateMocks([http.Client])
void main() {
  group('SourcemapsApi', () {
    late MockClient mockClient;
    late SourcemapsApi sourcemapsApi;

    setUp(() {
      mockClient = MockClient();
      sourcemapsApi = SourcemapsApi(httpClient: mockClient);
    });

    group('uploadSourcemap', () {
      test('returns true when upload is successful (200)', () async {
        // Create a temporary test file
        final testFile = File('test_sourcemap.js.map');
        testFile.writeAsStringSync('{"version": 3, "sources": ["test.js"]}');

        final response = http.StreamedResponse(
          Stream.value([]),
          200,
        );

        when(mockClient.send(any)).thenAnswer((_) async => response);

        final result = await sourcemapsApi.uploadSourcemap(
          appId: 'test-app-id',
          token: 'test-token',
          path: 'test_sourcemap.js.map',
          uri: 'https://example.com/app.js',
        );

        expect(result, true);
        verify(mockClient.send(any)).called(1);

        // Clean up
        testFile.deleteSync();
      });

      test('returns false when upload fails', () async {
        final testFile = File('test_sourcemap.js.map');
        testFile.writeAsStringSync('{"version": 3, "sources": ["test.js"]}');

        final response = http.StreamedResponse(
          Stream.value([]),
          400,
        );

        when(mockClient.send(any)).thenAnswer((_) async => response);

        final result = await sourcemapsApi.uploadSourcemap(
          appId: 'test-app-id',
          token: 'test-token',
          path: 'test_sourcemap.js.map',
          uri: 'https://example.com/app.js',
        );

        expect(result, false);

        testFile.deleteSync();
      });

      test('returns false when file does not exist', () async {
        final result = await sourcemapsApi.uploadSourcemap(
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
