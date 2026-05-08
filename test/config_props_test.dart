import 'dart:async';
import 'dart:io';

import 'package:args/args.dart';
import 'package:path/path.dart' as p;
import 'package:raygun_cli/src/config_file.dart';
import 'package:raygun_cli/src/config_props.dart';
import 'package:raygun_cli/src/environment.dart';
import 'package:test/test.dart';

/// Captures `print` calls made inside [body] into [logs].
void runZonedPrint(List<String> logs, void Function() body) {
  runZoned(
    body,
    zoneSpecification: ZoneSpecification(
      print: (_, _, _, line) => logs.add(line),
    ),
  );
}

void main() {
  ArgParser buildParser() => ArgParser()
    ..addFlag('verbose')
    ..addOption('app-id')
    ..addOption('token')
    ..addOption('api-key');

  late Directory tempDir;

  /// Writes a `.env` in a temp dir and installs it as the global ConfigFile.
  void installConfigFile(Map<String, String> values) {
    final body = values.entries.map((e) => '${e.key}=${e.value}').join('\n');
    File(p.join(tempDir.path, ConfigFile.fileName)).writeAsStringSync(body);
    ConfigFile.setInstance(
      ConfigFile.load(startDir: tempDir.path, stopDir: tempDir.path),
    );
  }

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('raygun_cli_props_test_');
    // Reset both singletons to a known-empty baseline before every test.
    Environment.setInstance(
      Environment(raygunAppId: null, raygunToken: null, raygunApiKey: null),
    );
    ConfigFile.setInstance(ConfigFile.empty());
  });

  tearDown(() {
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
    ConfigFile.resetForTest();
  });

  // -----------------------------------------------------------------
  // Pre-existing behaviour (regression coverage)
  // -----------------------------------------------------------------
  group('ConfigProp existing behaviour', () {
    test('parses values from CLI arguments', () {
      final results = buildParser().parse([
        '--app-id=app-id-parsed',
        '--token=token-parsed',
      ]);
      expect(ConfigProp.appId.load(results), 'app-id-parsed');
      expect(ConfigProp.token.load(results), 'token-parsed');
    });

    test('parses values from environment variables', () {
      Environment.setInstance(
        Environment(
          raygunAppId: 'app-id-env',
          raygunToken: 'token-env',
          raygunApiKey: 'api-key-env',
        ),
      );
      final results = buildParser().parse([]);
      expect(ConfigProp.appId.load(results), 'app-id-env');
      expect(ConfigProp.token.load(results), 'token-env');
      expect(ConfigProp.apiKey.load(results), 'api-key-env');
    });

    test('CLI argument wins over environment variable', () {
      Environment.setInstance(
        Environment(
          raygunAppId: 'app-id-env',
          raygunToken: 'token-env',
          raygunApiKey: 'api-key-env',
        ),
      );
      final results = buildParser().parse([
        '--app-id=app-id-arg',
        '--token=token-arg',
        '--api-key=api-key-arg',
      ]);
      expect(ConfigProp.appId.load(results), 'app-id-arg');
      expect(ConfigProp.token.load(results), 'token-arg');
      expect(ConfigProp.apiKey.load(results), 'api-key-arg');
    });

    test('mixed: app-id from env, token from arg', () {
      Environment.setInstance(
        Environment(
          raygunAppId: 'app-id-env',
          raygunToken: null,
          raygunApiKey: null,
        ),
      );
      final results = buildParser().parse(['--token=token-arg']);
      expect(ConfigProp.appId.load(results), 'app-id-env');
      expect(ConfigProp.token.load(results), 'token-arg');
    });
  });

  // -----------------------------------------------------------------
  // New: .env config file integration
  // -----------------------------------------------------------------
  group('ConfigProp .env file integration', () {
    test('loads from file when arg and env are absent', () {
      installConfigFile({Environment.raygunAppIdKey: 'app-id-from-file'});
      final results = buildParser().parse([]);
      expect(ConfigProp.appId.load(results), 'app-id-from-file');
    });

    test('arg wins over env and file', () {
      Environment.setInstance(
        Environment(
          raygunAppId: 'app-id-env',
          raygunToken: null,
          raygunApiKey: null,
        ),
      );
      installConfigFile({Environment.raygunAppIdKey: 'app-id-file'});
      final results = buildParser().parse(['--app-id=app-id-arg']);
      expect(ConfigProp.appId.load(results), 'app-id-arg');
    });

    test('env wins over file when arg absent', () {
      Environment.setInstance(
        Environment(
          raygunAppId: 'app-id-env',
          raygunToken: null,
          raygunApiKey: null,
        ),
      );
      installConfigFile({Environment.raygunAppIdKey: 'app-id-file'});
      final results = buildParser().parse([]);
      expect(ConfigProp.appId.load(results), 'app-id-env');
    });

    test('file value used only when arg AND env are absent', () {
      installConfigFile({Environment.raygunTokenKey: 'token-from-file'});
      final results = buildParser().parse([]);
      expect(ConfigProp.token.load(results), 'token-from-file');
    });

    test('all three ConfigProps load from file', () {
      installConfigFile({
        Environment.raygunAppIdKey: 'app-id-file',
        Environment.raygunTokenKey: 'token-file',
        Environment.raygunApiKeyKey: 'api-key-file',
      });
      final results = buildParser().parse([]);
      expect(ConfigProp.appId.load(results), 'app-id-file');
      expect(ConfigProp.token.load(results), 'token-file');
      expect(ConfigProp.apiKey.load(results), 'api-key-file');
    });

    test('mixed sources across props: file→appId, env→token, arg→apiKey', () {
      Environment.setInstance(
        Environment(
          raygunAppId: null,
          raygunToken: 'token-env',
          raygunApiKey: null,
        ),
      );
      installConfigFile({
        Environment.raygunAppIdKey: 'app-id-file',
        Environment.raygunTokenKey: 'token-file', // shadowed by env
        Environment.raygunApiKeyKey: 'api-key-file', // shadowed by arg
      });
      final results = buildParser().parse(['--api-key=api-key-arg']);
      expect(ConfigProp.appId.load(results), 'app-id-file');
      expect(ConfigProp.token.load(results), 'token-env');
      expect(ConfigProp.apiKey.load(results), 'api-key-arg');
    });

    test('falls through to env when file lacks the requested key', () {
      Environment.setInstance(
        Environment(
          raygunAppId: 'app-id-env',
          raygunToken: null,
          raygunApiKey: null,
        ),
      );
      installConfigFile({Environment.raygunTokenKey: 'token-file'});
      final results = buildParser().parse([]);
      expect(ConfigProp.appId.load(results), 'app-id-env');
      expect(ConfigProp.token.load(results), 'token-file');
    });

    test(
      'file with empty value (KEY=) is treated as missing and falls through',
      () {
        // dotenv stores '' for empty values. ConfigProp treats empty as
        // missing and falls through to the next tier — a higher-priority
        // env var must win.
        Environment.setInstance(
          Environment(
            raygunAppId: 'app-id-env',
            raygunToken: null,
            raygunApiKey: null,
          ),
        );
        installConfigFile({Environment.raygunAppIdKey: ''});
        final results = buildParser().parse([]);
        expect(ConfigProp.appId.load(results), 'app-id-env');
      },
    );

    test(
      'empty value at every tier exits with code 2',
      () async {
        // Empty .env value, empty env var, empty CLI arg — must surface the
        // friendly "Missing" error, not propagate '' downstream. Spawned in
        // a child process so the exit(2) doesn't kill the test runner.
        File(
          p.join(tempDir.path, ConfigFile.fileName),
        ).writeAsStringSync('RAYGUN_TOKEN=\nRAYGUN_API_KEY=\n');
        final result = await Process.run(
          Platform.resolvedExecutable,
          [
            'run',
            p.absolute('bin/raygun_cli.dart'),
            'deployments',
            '--version=1.0.0',
            '--token=',
            '--api-key=',
          ],
          workingDirectory: tempDir.path,
          environment: const {'RAYGUN_TOKEN': '', 'RAYGUN_API_KEY': ''},
          includeParentEnvironment: false,
        );
        expect(result.exitCode, 2);
        expect(result.stdout, contains('Missing'));
        expect(
          result.stdout,
          contains('Empty or whitespace-only values are treated as missing'),
        );
      },
      timeout: const Timeout(Duration(seconds: 60)),
    );

    test('empty CLI arg falls through to env var', () {
      Environment.setInstance(
        Environment(
          raygunAppId: 'app-id-env',
          raygunToken: null,
          raygunApiKey: null,
        ),
      );
      final results = buildParser().parse(['--app-id=']);
      expect(ConfigProp.appId.load(results), 'app-id-env');
    });

    test('empty env var falls through to .env file', () {
      Environment.setInstance(
        Environment(raygunAppId: '', raygunToken: null, raygunApiKey: null),
      );
      installConfigFile({Environment.raygunAppIdKey: 'app-id-file'});
      final results = buildParser().parse([]);
      expect(ConfigProp.appId.load(results), 'app-id-file');
    });

    test('whitespace-only CLI arg falls through to env var', () {
      // The user types `--app-id="   "` — currently accepted as a real value
      // and propagated to Raygun (404). Must instead fall through.
      Environment.setInstance(
        Environment(
          raygunAppId: 'app-id-env',
          raygunToken: null,
          raygunApiKey: null,
        ),
      );
      final results = buildParser().parse(['--app-id=   ']);
      expect(ConfigProp.appId.load(results), 'app-id-env');
    });

    test('whitespace-only env var falls through to .env file', () {
      // `export RAYGUN_APP_ID=" "` should not satisfy the lookup.
      Environment.setInstance(
        Environment(raygunAppId: '   ', raygunToken: null, raygunApiKey: null),
      );
      installConfigFile({Environment.raygunAppIdKey: 'app-id-file'});
      final results = buildParser().parse([]);
      expect(ConfigProp.appId.load(results), 'app-id-file');
    });

    test('tab-only env var is treated as missing', () {
      Environment.setInstance(
        Environment(raygunAppId: '\t\t', raygunToken: null, raygunApiKey: null),
      );
      installConfigFile({Environment.raygunAppIdKey: 'app-id-file'});
      final results = buildParser().parse([]);
      expect(ConfigProp.appId.load(results), 'app-id-file');
    });
  });

  // -----------------------------------------------------------------
  // New: verbose source-attribution logging
  // -----------------------------------------------------------------
  group('ConfigProp verbose attribution', () {
    test('prints CLI source line when value comes from CLI', () {
      final results = buildParser().parse(['--app-id=from-arg']);
      final logs = <String>[];
      runZonedPrint(logs, () {
        expect(ConfigProp.appId.load(results, verbose: true), 'from-arg');
      });
      expect(logs, contains('[VERBOSE] Resolved app-id from CLI argument'));
    });

    test('prints env source line (with key) when value comes from env', () {
      Environment.setInstance(
        Environment(
          raygunAppId: 'from-env',
          raygunToken: null,
          raygunApiKey: null,
        ),
      );
      final results = buildParser().parse([]);
      final logs = <String>[];
      runZonedPrint(logs, () {
        expect(ConfigProp.appId.load(results, verbose: true), 'from-env');
      });
      expect(
        logs,
        contains(
          '[VERBOSE] Resolved app-id from environment variable (RAYGUN_APP_ID)',
        ),
      );
    });

    test('prints .env source line (with path) when value comes from file', () {
      installConfigFile({Environment.raygunAppIdKey: 'from-file'});
      final results = buildParser().parse([]);
      final logs = <String>[];
      runZonedPrint(logs, () {
        expect(ConfigProp.appId.load(results, verbose: true), 'from-file');
      });
      final envPath = p.join(tempDir.path, ConfigFile.fileName);
      expect(
        logs,
        contains('[VERBOSE] Resolved app-id from .env file ($envPath)'),
      );
    });

    test('prints "ignoring blank" notice when falling through tiers', () {
      // Empty CLI arg + empty env var + valid file value.
      Environment.setInstance(
        Environment(raygunAppId: '', raygunToken: null, raygunApiKey: null),
      );
      installConfigFile({Environment.raygunAppIdKey: 'from-file'});
      final results = buildParser().parse(['--app-id=']);
      final logs = <String>[];
      runZonedPrint(logs, () {
        expect(ConfigProp.appId.load(results, verbose: true), 'from-file');
      });
      expect(
        logs.any(
          (l) =>
              l.contains('Ignoring blank value for app-id from CLI argument'),
        ),
        isTrue,
        reason: 'should warn about blank CLI arg',
      );
      expect(
        logs.any(
          (l) => l.contains(
            'Ignoring blank value for app-id from environment variable',
          ),
        ),
        isTrue,
        reason: 'should warn about blank env var',
      );
    });

    test('prints nothing when verbose is false', () {
      final results = buildParser().parse(['--app-id=from-arg']);
      final logs = <String>[];
      runZonedPrint(logs, () {
        expect(ConfigProp.appId.load(results), 'from-arg');
      });
      expect(logs, isEmpty);
    });
  });

  // -----------------------------------------------------------------
  // New: failure mode — missing in all three sources
  // -----------------------------------------------------------------
  group('ConfigProp missing-in-all-sources failure', () {
    test(
      'exits with code 2 and prints helpful error',
      () async {
        // Use a child process to assert exit code, since exit(2) would kill
        // the test runner. We invoke the real CLI with no arg, no env, no
        // .env file present in the temp working directory.
        final result = await Process.run(
          Platform.resolvedExecutable,
          [
            'run',
            p.absolute('bin/raygun_cli.dart'),
            'deployments',
            '--version=1.0.0',
          ],
          workingDirectory: tempDir.path,
          // includeParentEnvironment: false + empty env map ensures NONE of the
          // RAYGUN_* env vars are visible to the child process — forcing
          // ConfigProp.load() to fall through every tier and exit(2).
          environment: const {},
          includeParentEnvironment: false,
        );
        expect(result.exitCode, 2);
        expect(result.stdout, contains('Missing'));
        expect(
          result.stdout,
          contains('.env config file'),
          reason: 'error message should mention .env as a third option',
        );
      },
      timeout: const Timeout(Duration(seconds: 60)),
    );
  });
}
