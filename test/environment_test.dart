import 'package:raygun_cli/src/environment.dart';
import 'package:test/test.dart';

void main() {
  group('Environment', () {
    test('exposes the three RAYGUN_* env-var keys as constants', () {
      expect(Environment.raygunAppIdKey, 'RAYGUN_APP_ID');
      expect(Environment.raygunTokenKey, 'RAYGUN_TOKEN');
      expect(Environment.raygunApiKeyKey, 'RAYGUN_API_KEY');
    });

    test('constructor stores the three nullable fields', () {
      final env = Environment(
        raygunAppId: 'app',
        raygunToken: 'tok',
        raygunApiKey: 'key',
      );
      expect(env.raygunAppId, 'app');
      expect(env.raygunToken, 'tok');
      expect(env.raygunApiKey, 'key');
    });

    test('null fields are returned as null', () {
      final env = Environment(
        raygunAppId: null,
        raygunToken: null,
        raygunApiKey: null,
      );
      expect(env.raygunAppId, isNull);
      expect(env.raygunToken, isNull);
      expect(env.raygunApiKey, isNull);
    });

    group('operator []', () {
      late Environment env;
      setUp(() {
        env = Environment(
          raygunAppId: 'app-val',
          raygunToken: 'tok-val',
          raygunApiKey: 'key-val',
        );
      });

      test('returns appId for RAYGUN_APP_ID', () {
        expect(env[Environment.raygunAppIdKey], 'app-val');
      });

      test('returns token for RAYGUN_TOKEN', () {
        expect(env[Environment.raygunTokenKey], 'tok-val');
      });

      test('returns apiKey for RAYGUN_API_KEY', () {
        expect(env[Environment.raygunApiKeyKey], 'key-val');
      });

      test('returns null when the matching field is null', () {
        final empty = Environment(
          raygunAppId: null,
          raygunToken: null,
          raygunApiKey: null,
        );
        expect(empty[Environment.raygunAppIdKey], isNull);
        expect(empty[Environment.raygunTokenKey], isNull);
        expect(empty[Environment.raygunApiKeyKey], isNull);
      });

      test('throws ArgumentError for an unknown key', () {
        expect(() => env['NOT_A_REAL_KEY'], throwsA(isA<ArgumentError>()));
      });

      test('is case-sensitive', () {
        // The current impl uses an exact string switch; verify that fact
        // so any future change to relax case-sensitivity is intentional.
        expect(() => env['raygun_app_id'], throwsA(isA<ArgumentError>()));
      });
    });

    group('singleton', () {
      tearDown(() {
        // Reset the singleton to a known-empty state so we don't leak the
        // process's real RAYGUN_* env vars into later tests.
        Environment.setInstance(
          Environment(raygunAppId: null, raygunToken: null, raygunApiKey: null),
        );
      });

      test('setInstance overrides the global instance', () {
        final injected = Environment(
          raygunAppId: 'injected-app',
          raygunToken: 'injected-tok',
          raygunApiKey: 'injected-key',
        );
        Environment.setInstance(injected);
        expect(identical(Environment.instance, injected), isTrue);
        expect(Environment.instance.raygunAppId, 'injected-app');
      });

      test('setInstance is idempotent (last call wins)', () {
        Environment.setInstance(
          Environment(
            raygunAppId: 'first',
            raygunToken: null,
            raygunApiKey: null,
          ),
        );
        Environment.setInstance(
          Environment(
            raygunAppId: 'second',
            raygunToken: null,
            raygunApiKey: null,
          ),
        );
        expect(Environment.instance.raygunAppId, 'second');
      });
    });
  });
}
