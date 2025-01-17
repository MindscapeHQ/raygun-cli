import 'dart:io';

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
      final props = ConfigProps.load(results);
      expect(props.appId, 'app-id-parsed');
      expect(props.token, 'token-parsed');
    });

    test('should parse from env vars', () {
      // fake environment variables
      Environment.setInstance(
        Environment(
          raygunAppId: 'app-id-env',
          raygunToken: 'token-env',
        ),
      );

      // define parser
      ArgParser parser = ArgParser()
        ..addFlag('verbose')
        ..addOption('app-id')
        ..addOption('token');

      // parse nothing
      final results = parser.parse([]);

      // load from env vars
      final props = ConfigProps.load(results);
      expect(props.appId, 'app-id-env');
      expect(props.token, 'token-env');
    });

    test('should parse with priority', () {
      // fake environment variables
      Environment.setInstance(
        Environment(
          raygunAppId: 'app-id-env',
          raygunToken: 'token-env',
        ),
      );

      // define parser
      ArgParser parser = ArgParser()
        ..addFlag('verbose')
        ..addOption('app-id')
        ..addOption('token');

      // parse arguments
      final results =
          parser.parse(['--app-id=app-id-parsed', '--token=token-parsed']);

      // load from parsed even if env vars are set
      final props = ConfigProps.load(results);
      expect(props.appId, 'app-id-parsed');
      expect(props.token, 'token-parsed');
    });

    test('should parse from both', () {
      // fake environment variables
      // token is not provided
      Environment.setInstance(
        Environment(
          raygunAppId: 'app-id-env',
          raygunToken: null,
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
      final props = ConfigProps.load(results);
      expect(props.appId, 'app-id-env');
      expect(props.token, 'token-parsed');
    });
  });
}
