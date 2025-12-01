import 'package:args/args.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:raygun_cli/src/symbols/symbols_api.dart';
import 'package:raygun_cli/src/symbols/symbols_command.dart';
import 'package:test/test.dart';

import 'symbols_command_test.mocks.dart';

@GenerateMocks([SymbolsApi])
void main() {
  group('SymbolsCommand', () {
    late MockSymbolsApi mockApi;
    late SymbolsCommand command;

    setUp(() {
      mockApi = MockSymbolsApi();
      command = SymbolsCommand(api: mockApi);
    });

    group('run', () {
      test(
        'upload command calls uploadSymbols with correct parameters',
        () async {
          when(
            mockApi.uploadSymbols(
              appId: anyNamed('appId'),
              token: anyNamed('token'),
              path: anyNamed('path'),
              version: anyNamed('version'),
            ),
          ).thenAnswer((_) async => true);

          final parser = ArgParser();
          parser.addCommand('upload');
          parser.addOption('path');
          parser.addOption('version');

          final results = parser.parse([
            'upload',
            '--path=test.txt',
            '--version=1.0.0',
          ]);

          final success = await command.run(
            command: results,
            appId: 'test-app-id',
            token: 'test-token',
          );

          expect(success, true);
          verify(
            mockApi.uploadSymbols(
              appId: 'test-app-id',
              token: 'test-token',
              path: 'test.txt',
              version: '1.0.0',
            ),
          ).called(1);
        },
      );

      test('upload command returns false when path is missing', () async {
        final parser = ArgParser();
        parser.addCommand('upload');
        parser.addOption('path');
        parser.addOption('version');

        final results = parser.parse(['upload', '--version=1.0.0']);

        final success = await command.run(
          command: results,
          appId: 'test-app-id',
          token: 'test-token',
        );

        expect(success, false);
        verifyNever(
          mockApi.uploadSymbols(
            appId: anyNamed('appId'),
            token: anyNamed('token'),
            path: anyNamed('path'),
            version: anyNamed('version'),
          ),
        );
      });

      test('upload command returns false when version is missing', () async {
        final parser = ArgParser();
        parser.addCommand('upload');
        parser.addOption('path');
        parser.addOption('version');

        final results = parser.parse(['upload', '--path=test.txt']);

        final success = await command.run(
          command: results,
          appId: 'test-app-id',
          token: 'test-token',
        );

        expect(success, false);
        verifyNever(
          mockApi.uploadSymbols(
            appId: anyNamed('appId'),
            token: anyNamed('token'),
            path: anyNamed('path'),
            version: anyNamed('version'),
          ),
        );
      });

      test('list command calls listSymbols with correct parameters', () async {
        when(
          mockApi.listSymbols(
            appId: anyNamed('appId'),
            token: anyNamed('token'),
          ),
        ).thenAnswer((_) async => true);

        final parser = ArgParser();
        parser.addCommand('list');

        final results = parser.parse(['list']);

        final success = await command.run(
          command: results,
          appId: 'test-app-id',
          token: 'test-token',
        );

        expect(success, true);
        verify(
          mockApi.listSymbols(appId: 'test-app-id', token: 'test-token'),
        ).called(1);
      });

      test(
        'delete command calls deleteSymbols with correct parameters',
        () async {
          when(
            mockApi.deleteSymbols(
              appId: anyNamed('appId'),
              token: anyNamed('token'),
              id: anyNamed('id'),
            ),
          ).thenAnswer((_) async => true);

          final parser = ArgParser();
          parser.addCommand('delete');
          parser.addOption('id');

          final results = parser.parse(['delete', '--id=symbol-id']);

          final success = await command.run(
            command: results,
            appId: 'test-app-id',
            token: 'test-token',
          );

          expect(success, true);
          verify(
            mockApi.deleteSymbols(
              appId: 'test-app-id',
              token: 'test-token',
              id: 'symbol-id',
            ),
          ).called(1);
        },
      );

      test('delete command returns false when id is missing', () async {
        final parser = ArgParser();
        parser.addCommand('delete');
        parser.addOption('id');

        final results = parser.parse(['delete']);

        final success = await command.run(
          command: results,
          appId: 'test-app-id',
          token: 'test-token',
        );

        expect(success, false);
        verifyNever(
          mockApi.deleteSymbols(
            appId: anyNamed('appId'),
            token: anyNamed('token'),
            id: anyNamed('id'),
          ),
        );
      });

      test('returns false for unknown command', () async {
        final parser = ArgParser();
        parser.addCommand('unknown');

        final results = parser.parse(['unknown']);

        final success = await command.run(
          command: results,
          appId: 'test-app-id',
          token: 'test-token',
        );

        expect(success, false);
      });

      test('returns false when no command is provided', () async {
        final parser = ArgParser();

        final results = parser.parse([]);

        final success = await command.run(
          command: results,
          appId: 'test-app-id',
          token: 'test-token',
        );

        expect(success, false);
      });
    });
  });
}
