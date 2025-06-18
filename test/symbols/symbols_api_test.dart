import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:raygun_cli/src/symbols/symbols_api.dart';
import 'package:test/test.dart';

import 'symbols_api_test.mocks.dart';

@GenerateMocks([http.Client])
void main() {
  group('SymbolsApi', () {
    late MockClient mockClient;
    late SymbolsApi symbolsApi;

    setUp(() {
      mockClient = MockClient();
      symbolsApi = SymbolsApi(httpClient: mockClient);
    });

    group('uploadSymbols', () {
      test('returns true when upload is successful (200)', () async {
        // Create a temporary test file
        final testFile = File('test_symbols.txt');
        testFile.writeAsStringSync('test symbols content');

        final response = http.StreamedResponse(
          Stream.value([]),
          200,
        );

        when(mockClient.send(any)).thenAnswer((_) async => response);

        final result = await symbolsApi.uploadSymbols(
          appId: 'test-app-id',
          token: 'test-token',
          path: 'test_symbols.txt',
          version: '1.0.0',
        );

        expect(result, true);
        verify(mockClient.send(any)).called(1);

        // Clean up
        testFile.deleteSync();
      });

      test('returns true when upload is successful (201)', () async {
        final testFile = File('test_symbols.txt');
        testFile.writeAsStringSync('test symbols content');

        final response = http.StreamedResponse(
          Stream.value([]),
          201,
        );

        when(mockClient.send(any)).thenAnswer((_) async => response);

        final result = await symbolsApi.uploadSymbols(
          appId: 'test-app-id',
          token: 'test-token',
          path: 'test_symbols.txt',
          version: '1.0.0',
        );

        expect(result, true);

        testFile.deleteSync();
      });

      test('returns false when upload fails', () async {
        final testFile = File('test_symbols.txt');
        testFile.writeAsStringSync('test symbols content');

        final response = http.StreamedResponse(
          Stream.value(utf8.encode('Bad request')),
          400,
        );

        when(mockClient.send(any)).thenAnswer((_) async => response);

        final result = await symbolsApi.uploadSymbols(
          appId: 'test-app-id',
          token: 'test-token',
          path: 'test_symbols.txt',
          version: '1.0.0',
        );

        expect(result, false);

        testFile.deleteSync();
      });

      test('throws exception when file does not exist', () async {
        expect(
          () => symbolsApi.uploadSymbols(
            appId: 'test-app-id',
            token: 'test-token',
            path: 'nonexistent_file.txt',
            version: '1.0.0',
          ),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('listSymbols', () {
      test('returns true and prints symbols when successful', () async {
        final symbolsResponse = [
          {
            'name': 'symbols1.txt',
            'identifier': 'id1',
            'version': '1.0.0',
          },
          {
            'name': 'symbols2.txt',
            'identifier': 'id2',
            'version': '1.1.0',
          },
        ];

        final response = http.StreamedResponse(
          Stream.value(utf8.encode(jsonEncode(symbolsResponse))),
          200,
        );

        when(mockClient.send(any)).thenAnswer((_) async => response);

        final result = await symbolsApi.listSymbols(
          appId: 'test-app-id',
          token: 'test-token',
        );

        expect(result, true);
        verify(mockClient.send(any)).called(1);
      });

      test('returns false when list request fails', () async {
        final response = http.StreamedResponse(
          Stream.value([]),
          401,
        );

        when(mockClient.send(any)).thenAnswer((_) async => response);

        final result = await symbolsApi.listSymbols(
          appId: 'test-app-id',
          token: 'test-token',
        );

        expect(result, false);
      });
    });

    group('deleteSymbols', () {
      test('returns true when delete is successful', () async {
        final response = http.StreamedResponse(
          Stream.value([]),
          204,
        );

        when(mockClient.send(any)).thenAnswer((_) async => response);

        final result = await symbolsApi.deleteSymbols(
          appId: 'test-app-id',
          token: 'test-token',
          id: 'symbol-id',
        );

        expect(result, true);
        verify(mockClient.send(any)).called(1);
      });

      test('returns false when delete fails', () async {
        final response = http.StreamedResponse(
          Stream.value([]),
          404,
        );

        when(mockClient.send(any)).thenAnswer((_) async => response);

        final result = await symbolsApi.deleteSymbols(
          appId: 'test-app-id',
          token: 'test-token',
          id: 'nonexistent-id',
        );

        expect(result, false);
      });
    });
  });
}
