import 'dart:io';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:raygun_cli/src/sourcemap/sourcemap_api.dart';
import 'package:raygun_cli/src/sourcemap/sourcemap_command.dart';
import 'package:test/test.dart';

import 'sourcemap_command_test.mocks.dart';

@GenerateMocks([SourcemapApi])
void main() {
  group('SourcemapCommand', () {
    late MockSourcemapApi mockApi;
    late SourcemapCommand command;

    setUp(() {
      mockApi = MockSourcemapApi();
      command = SourcemapCommand(api: mockApi);
    });

    group('run', () {
      test('handles single file upload (platform null)', () async {
        // Create a temporary test file
        final testFile = File('test_sourcemap.js.map');
        testFile.writeAsStringSync('{"version": 3, "sources": ["test.js"]}');

        when(mockApi.uploadSourcemap(
          appId: anyNamed('appId'),
          token: anyNamed('token'),
          path: anyNamed('path'),
          uri: anyNamed('uri'),
        )).thenAnswer((_) async => true);

        final parser = command.buildParser();

        // "platform" is not specified, so it defaults to "single-file" upload
        // "input-map" is required for single file upload
        final results = parser.parse([
          '--app-id=test-app-id',
          '--token=test-token',
          '--uri=http://test.com/app.js',
          '--input-map=test_sourcemap.js.map'
        ]);

        final result = await command.run(
          command: results,
          verbose: false,
        );

        expect(result, true);
        verify(mockApi.uploadSourcemap(
          appId: 'test-app-id',
          token: 'test-token',
          path: 'test_sourcemap.js.map',
          uri: 'http://test.com/app.js',
        )).called(1);

        // Clean up
        testFile.deleteSync();
      });

      test('handles flutter platform upload', () async {
        when(mockApi.uploadSourcemap(
          appId: anyNamed('appId'),
          token: anyNamed('token'),
          path: anyNamed('path'),
          uri: anyNamed('uri'),
        )).thenAnswer((_) async => true);

        final parser = command.buildParser();

        // path is optional for flutter,
        // so we use default 'build/web/main.dart.js.map'
        final results = parser.parse([
          '--platform=flutter',
          '--app-id=test-app-id',
          '--token=test-token',
          '--base-uri=http://test.com/'
        ]);

        final result = await command.run(
          command: results,
          verbose: false,
        );

        expect(result, true);
        verify(mockApi.uploadSourcemap(
          appId: 'test-app-id',
          token: 'test-token',
          path: 'build/web/main.dart.js.map',
          uri: 'http://test.com/main.dart.js',
        )).called(1);
      });

      test('handles node platform (returns false - not implemented)', () async {
        final parser = command.buildParser();
        final results = parser.parse([
          '--platform=node',
          '--app-id=test-app-id',
          '--token=test-token',
          '--base-uri=http://test.com/'
        ]);

        final result = await command.run(
          command: results,
          verbose: false,
        );

        // The "node" platform is not implemented, so it should return false
        expect(result, false);
        verifyNever(mockApi.uploadSourcemap(
          appId: anyNamed('appId'),
          token: anyNamed('token'),
          path: anyNamed('path'),
          uri: anyNamed('uri'),
        ));
      });

      test('returns false for unsupported platform', () async {
        final parser = command.buildParser();
        final results = parser.parse([
          '--platform=unsupported',
          '--app-id=test-app-id',
          '--token=test-token'
        ]);

        final result = await command.run(
          command: results,
          verbose: false,
        );

        expect(result, false);
      });

      test('returns false when help is parsed', () async {
        final parser = command.buildParser();
        final results = parser.parse(['--help']);

        final result = await command.run(
          command: results,
          verbose: false,
        );

        expect(result, false);
      });
    });
  });
}
