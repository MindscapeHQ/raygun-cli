import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:raygun_cli/src/proguard/proguard_api.dart';
import 'package:raygun_cli/src/proguard/proguard.dart';
import 'package:raygun_cli/src/proguard/proguard_command.dart';
import 'package:test/test.dart';

import 'proguard_command_test.mocks.dart';

@GenerateMocks([ProguardApi])
void main() {
  group('Proguard', () {
    late MockProguardApi mockApi;
    late ProguardCommand command;
    late Proguard proguard;

    setUp(() {
      mockApi = MockProguardApi();
      command = ProguardCommand(api: mockApi);
    });

    group('upload', () {
      test('upload calls uploadProguardMapping with correct parameters',
          () async {
        when(mockApi.uploadProguardMapping(
          appId: anyNamed('appId'),
          externalAccessToken: anyNamed('externalAccessToken'),
          path: anyNamed('path'),
          version: anyNamed('version'),
          overwrite: anyNamed('overwrite'),
        )).thenAnswer((_) async => true);

        final parser = command.buildParser();
        final results = parser.parse([
          '--app-id=test-app-id',
          '--external-access-token=test-token',
          '--path=test.txt',
          '--version=1.0.0',
          '--overwrite'
        ]);

        proguard = Proguard(
          command: results,
          verbose: false,
          api: mockApi,
        );

        final success = await proguard.upload();

        expect(success, true);
        verify(mockApi.uploadProguardMapping(
          appId: 'test-app-id',
          externalAccessToken: 'test-token',
          path: 'test.txt',
          version: '1.0.0',
          overwrite: true,
        )).called(1);
      });

      test(
          'upload calls uploadProguardMapping without overwrite when flag not set',
          () async {
        when(mockApi.uploadProguardMapping(
          appId: anyNamed('appId'),
          externalAccessToken: anyNamed('externalAccessToken'),
          path: anyNamed('path'),
          version: anyNamed('version'),
          overwrite: anyNamed('overwrite'),
        )).thenAnswer((_) async => true);

        final parser = command.buildParser();
        final results = parser.parse([
          '--app-id=test-app-id',
          '--external-access-token=test-token',
          '--path=test.txt',
          '--version=1.0.0'
        ]);

        proguard = Proguard(
          command: results,
          verbose: false,
          api: mockApi,
        );

        final success = await proguard.upload();

        expect(success, true);
        verify(mockApi.uploadProguardMapping(
          appId: 'test-app-id',
          externalAccessToken: 'test-token',
          path: 'test.txt',
          version: '1.0.0',
          overwrite: false,
        )).called(1);
      });

      test('upload returns false when path is missing', () async {
        final parser = command.buildParser();
        final results = parser.parse([
          '--app-id=test-app-id',
          '--external-access-token=test-token',
          '--version=1.0.0'
        ]);

        proguard = Proguard(
          command: results,
          verbose: false,
          api: mockApi,
        );

        final success = await proguard.upload();

        expect(success, false);
        verifyNever(mockApi.uploadProguardMapping(
          appId: anyNamed('appId'),
          externalAccessToken: anyNamed('externalAccessToken'),
          path: anyNamed('path'),
          version: anyNamed('version'),
          overwrite: anyNamed('overwrite'),
        ));
      });

      test('upload returns false when version is missing', () async {
        final parser = command.buildParser();
        final results = parser.parse([
          '--app-id=test-app-id',
          '--external-access-token=test-token',
          '--path=test.txt'
        ]);

        proguard = Proguard(
          command: results,
          verbose: false,
          api: mockApi,
        );

        final success = await proguard.upload();

        expect(success, false);
        verifyNever(mockApi.uploadProguardMapping(
          appId: anyNamed('appId'),
          externalAccessToken: anyNamed('externalAccessToken'),
          path: anyNamed('path'),
          version: anyNamed('version'),
          overwrite: anyNamed('overwrite'),
        ));
      });

      test('upload returns false when external-access-token is missing',
          () async {
        final parser = command.buildParser();
        final results = parser.parse(
            ['--app-id=test-app-id', '--path=test.txt', '--version=1.0.0']);

        proguard = Proguard(
          command: results,
          verbose: false,
          api: mockApi,
        );

        final success = await proguard.upload();

        expect(success, false);
        verifyNever(mockApi.uploadProguardMapping(
          appId: anyNamed('appId'),
          externalAccessToken: anyNamed('externalAccessToken'),
          path: anyNamed('path'),
          version: anyNamed('version'),
          overwrite: anyNamed('overwrite'),
        ));
      });
    });
  });
}
