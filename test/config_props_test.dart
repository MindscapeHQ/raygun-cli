import 'package:args/args.dart';
import 'package:raygun_cli/config_props.dart';
import 'package:raygun_cli/environment.dart';
import 'package:test/test.dart';

void main() {
  group('ConfigProps', () {
    test('should parse arguments', () {
      ArgParser parser = ArgParser()
        ..addFlag('verbose')
        ..addOption('app-id')
        ..addOption('token');
      final results =
          parser.parse(['--app-id=app-id-parsed', '--token=token-parsed']);
      final token = ConfigProp.token.load(results);
      final appId = ConfigProp.appId.load(results);
      expect(appId, 'app-id-parsed');
      expect(token, 'token-parsed');
    });

    test('should parse from env vars', () {
      // fake environment variables
      Environment.setInstance(
        Environment(
          raygunAppId: 'app-id-env',
          raygunToken: 'token-env',
          raygunApiKey: 'api-key-env',
        ),
      );

      // define parser
      ArgParser parser = ArgParser()
        ..addFlag('verbose')
        ..addOption('app-id')
        ..addOption('api-key')
        ..addOption('token');

      // parse nothing
      final results = parser.parse([]);

      // load from env vars
      final appId = ConfigProp.appId.load(results);
      final token = ConfigProp.token.load(results);
      final apiKey = ConfigProp.apiKey.load(results);
      expect(appId, 'app-id-env');
      expect(token, 'token-env');
      expect(apiKey, 'api-key-env');
    });

    test('should parse with priority', () {
      // fake environment variables
      Environment.setInstance(
        Environment(
          raygunAppId: 'app-id-env',
          raygunToken: 'token-env',
          raygunApiKey: 'api-key-env',
        ),
      );

      // define parser
      ArgParser parser = ArgParser()
        ..addFlag('verbose')
        ..addOption('app-id')
        ..addOption('api-key')
        ..addOption('token');

      // parse arguments
      final results = parser.parse([
        '--app-id=app-id-parsed',
        '--token=token-parsed',
        '--api-key=api-key-parsed',
      ]);

      // load from parsed even if env vars are set
      final appId = ConfigProp.appId.load(results);
      final token = ConfigProp.token.load(results);
      final apiKey = ConfigProp.apiKey.load(results);
      expect(appId, 'app-id-parsed');
      expect(token, 'token-parsed');
      expect(apiKey, 'api-key-parsed');
    });

    test('should parse from both', () {
      // fake environment variables
      // token is not provided
      Environment.setInstance(
        Environment(
          raygunAppId: 'app-id-env',
          raygunToken: null,
          raygunApiKey: null,
        ),
      );

      // define parser
      ArgParser parser = ArgParser()
        ..addFlag('verbose')
        ..addOption('app-id')
        ..addOption('token');

      // parse arguments, only token is passed
      final results = parser.parse(['--token=token-parsed']);

      // app-id from env, token from argument
      final appId = ConfigProp.appId.load(results);
      final token = ConfigProp.token.load(results);
      expect(appId, 'app-id-env');
      expect(token, 'token-parsed');
    });
  });
}
