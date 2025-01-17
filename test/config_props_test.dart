import 'package:args/args.dart';
import 'package:raygun_cli/config_props.dart';
import 'package:test/test.dart';

void main() {
  group('ConfigProps', () {
    test('should parse arguments', () {
      ArgParser parser = ArgParser()
        ..addFlag('app-id')
        ..addFlag('token');
      final results =
          parser.parse(['app-id', 'app-id-parsed', 'token', 'token-parsed']);
      final props = ConfigProps.load(results);
      expect(props.appId, 'app-id-parsed');
      expect(props.token, 'token-parsed');
    });

    test('should parse from env vars', () {
      ArgParser parser = ArgParser()
        ..addFlag('app-id')
        ..addFlag('token');
      // intentionally empty
      final results = parser.parse([]);
      final props = ConfigProps.load(results);
      expect(props.appId, 'app-id-env');
      expect(props.token, 'token-env');
    });
  });
}
