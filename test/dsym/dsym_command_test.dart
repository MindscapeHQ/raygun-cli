import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:raygun_cli/src/dsym/dsym_api.dart';
import 'package:raygun_cli/src/dsym/dsym.dart';
import 'package:raygun_cli/src/dsym/dsym_command.dart';
import 'package:test/test.dart';

import 'dsym_command_test.mocks.dart';

@GenerateMocks([DsymApi])
void main() {
  group('Dsym', () {
    late MockDsymApi mockApi;
    late DsymCommand command;
    late Dsym dsym;

    setUp(() {
      mockApi = MockDsymApi();
      command = DsymCommand(api: mockApi);
    });

    group('upload', () {
      test('upload calls uploadDsym with correct parameters', () async {
        when(
          mockApi.uploadDsym(
            appId: anyNamed('appId'),
            externalAccessToken: anyNamed('externalAccessToken'),
            path: anyNamed('path'),
          ),
        ).thenAnswer((_) async => true);

        final parser = command.buildParser();
        final results = parser.parse([
          '--app-id=test-app-id',
          '--external-access-token=test-token',
          '--path=test.zip',
        ]);

        dsym = Dsym(command: results, verbose: false, api: mockApi);

        final success = await dsym.upload();

        expect(success, true);
        verify(
          mockApi.uploadDsym(
            appId: 'test-app-id',
            externalAccessToken: 'test-token',
            path: 'test.zip',
          ),
        ).called(1);
      });

      test('upload returns false when path is missing', () async {
        final parser = command.buildParser();
        final results = parser.parse([
          '--app-id=test-app-id',
          '--external-access-token=test-token',
        ]);

        dsym = Dsym(command: results, verbose: false, api: mockApi);

        final success = await dsym.upload();

        expect(success, false);
        verifyNever(
          mockApi.uploadDsym(
            appId: anyNamed('appId'),
            externalAccessToken: anyNamed('externalAccessToken'),
            path: anyNamed('path'),
          ),
        );
      });

      test(
        'upload returns false when external-access-token is missing',
        () async {
          final parser = command.buildParser();
          final results = parser.parse([
            '--app-id=test-app-id',
            '--path=test.zip',
          ]);

          dsym = Dsym(command: results, verbose: false, api: mockApi);

          final success = await dsym.upload();

          expect(success, false);
          verifyNever(
            mockApi.uploadDsym(
              appId: anyNamed('appId'),
              externalAccessToken: anyNamed('externalAccessToken'),
              path: anyNamed('path'),
            ),
          );
        },
      );
    });
  });
}
