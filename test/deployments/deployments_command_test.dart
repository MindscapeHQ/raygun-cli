import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:raygun_cli/src/deployments/deployments_api.dart';
import 'package:raygun_cli/src/deployments/deployments.dart';
import 'package:raygun_cli/src/deployments/deployments_command.dart';
import 'package:test/test.dart';

import 'deployments_command_test.mocks.dart';

@GenerateMocks([DeploymentsApi])
void main() {
  group('Deployments', () {
    late MockDeploymentsApi mockApi;
    late DeploymentsCommand command;
    late Deployments deployments;

    setUp(() {
      mockApi = MockDeploymentsApi();
      command = DeploymentsCommand(api: mockApi);
    });

    group('notify', () {
      test('notify calls createDeployment with correct parameters', () async {
        when(
          mockApi.createDeployment(
            token: anyNamed('token'),
            apiKey: anyNamed('apiKey'),
            version: anyNamed('version'),
            ownerName: anyNamed('ownerName'),
            emailAddress: anyNamed('emailAddress'),
            comment: anyNamed('comment'),
            scmIdentifier: anyNamed('scmIdentifier'),
            scmType: anyNamed('scmType'),
          ),
        ).thenAnswer((_) async => true);

        final parser = command.buildParser();
        final results = parser.parse([
          '--token=test-token',
          '--api-key=test-api-key',
          '--version=1.0.0',
          '--owner-name=John Doe',
          '--email-address=john@example.com',
          '--comment=Test deployment',
          '--scm-identifier=abc123',
          '--scm-type=GitHub',
        ]);

        deployments = Deployments(
          command: results,
          verbose: false,
          deploymentsApi: mockApi,
        );

        final success = await deployments.notify();

        expect(success, true);
        verify(
          mockApi.createDeployment(
            token: 'test-token',
            apiKey: 'test-api-key',
            version: '1.0.0',
            ownerName: 'John Doe',
            emailAddress: 'john@example.com',
            comment: 'Test deployment',
            scmIdentifier: 'abc123',
            scmType: 'GitHub',
          ),
        ).called(1);
      });

      test(
        'notify calls createDeployment with only required parameters',
        () async {
          when(
            mockApi.createDeployment(
              token: anyNamed('token'),
              apiKey: anyNamed('apiKey'),
              version: anyNamed('version'),
              ownerName: anyNamed('ownerName'),
              emailAddress: anyNamed('emailAddress'),
              comment: anyNamed('comment'),
              scmIdentifier: anyNamed('scmIdentifier'),
              scmType: anyNamed('scmType'),
            ),
          ).thenAnswer((_) async => true);

          final parser = command.buildParser();
          final results = parser.parse([
            '--token=test-token',
            '--api-key=test-api-key',
            '--version=1.0.0',
          ]);

          deployments = Deployments(
            command: results,
            verbose: false,
            deploymentsApi: mockApi,
          );

          final success = await deployments.notify();

          expect(success, true);
          verify(
            mockApi.createDeployment(
              token: 'test-token',
              apiKey: 'test-api-key',
              version: '1.0.0',
              ownerName: null,
              emailAddress: null,
              comment: null,
              scmIdentifier: null,
              scmType: null,
            ),
          ).called(1);
        },
      );

      test('notify returns false when version is missing', () async {
        final parser = command.buildParser();
        final results = parser.parse([
          '--token=test-token',
          '--api-key=test-api-key',
        ]);

        deployments = Deployments(
          command: results,
          verbose: false,
          deploymentsApi: mockApi,
        );

        final success = await deployments.notify();

        expect(success, false);
        verifyNever(
          mockApi.createDeployment(
            token: anyNamed('token'),
            apiKey: anyNamed('apiKey'),
            version: anyNamed('version'),
            ownerName: anyNamed('ownerName'),
            emailAddress: anyNamed('emailAddress'),
            comment: anyNamed('comment'),
            scmIdentifier: anyNamed('scmIdentifier'),
            scmType: anyNamed('scmType'),
          ),
        );
      });

      test('notify returns false when API call fails', () async {
        when(
          mockApi.createDeployment(
            token: anyNamed('token'),
            apiKey: anyNamed('apiKey'),
            version: anyNamed('version'),
            ownerName: anyNamed('ownerName'),
            emailAddress: anyNamed('emailAddress'),
            comment: anyNamed('comment'),
            scmIdentifier: anyNamed('scmIdentifier'),
            scmType: anyNamed('scmType'),
          ),
        ).thenAnswer((_) async => false);

        final parser = command.buildParser();
        final results = parser.parse([
          '--token=test-token',
          '--api-key=test-api-key',
          '--version=1.0.0',
        ]);

        deployments = Deployments(
          command: results,
          verbose: false,
          deploymentsApi: mockApi,
        );

        final success = await deployments.notify();

        expect(success, false);
        verify(
          mockApi.createDeployment(
            token: 'test-token',
            apiKey: 'test-api-key',
            version: '1.0.0',
            ownerName: null,
            emailAddress: null,
            comment: null,
            scmIdentifier: null,
            scmType: null,
          ),
        ).called(1);
      });
    });
  });
}
