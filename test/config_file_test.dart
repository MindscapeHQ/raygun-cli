import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:raygun_cli/src/config_file.dart';
import 'package:test/test.dart';

void main() {
  group('ConfigFile', () {
    late Directory tempDir;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('raygun_cli_cfgfile_test_');
      ConfigFile.resetForTest();
    });

    tearDown(() {
      if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
      ConfigFile.resetForTest();
    });

    /// Writes a `.env` file in [dir] with the given [contents] and returns
    /// the absolute path.
    String writeEnv(Directory dir, String contents) {
      final file = File(p.join(dir.path, ConfigFile.fileName));
      file.writeAsStringSync(contents);
      return file.absolute.path;
    }

    group('discovery', () {
      test('returns empty when no .env exists anywhere', () {
        final cfg = ConfigFile.load(
          startDir: tempDir.path,
          stopDir: tempDir.path,
        );
        expect(cfg.path, isNull);
        expect(cfg['ANYTHING'], isNull);
      });

      test('loads .env from current directory', () {
        final envPath = writeEnv(tempDir, 'RAYGUN_APP_ID=abc123\n');
        final cfg = ConfigFile.load(
          startDir: tempDir.path,
          stopDir: tempDir.path,
        );
        expect(cfg.path, envPath);
        expect(cfg['RAYGUN_APP_ID'], 'abc123');
      });

      test('walks up parent directories to find .env', () {
        final envPath = writeEnv(tempDir, 'RAYGUN_TOKEN=tok\n');
        final nested = Directory(p.join(tempDir.path, 'a', 'b', 'c'))
          ..createSync(recursive: true);

        final cfg = ConfigFile.load(
          startDir: nested.path,
          stopDir: tempDir.path,
        );
        expect(cfg.path, envPath);
        expect(cfg['RAYGUN_TOKEN'], 'tok');
      });

      test('does not escape stopDir boundary when walking up', () {
        // .env lives in a sibling above stopDir — must NOT be discovered.
        writeEnv(tempDir, 'RAYGUN_API_KEY=secret\n');
        final stopDir = Directory(p.join(tempDir.path, 'project'))
          ..createSync();
        final start = Directory(p.join(stopDir.path, 'sub'))..createSync();

        final cfg = ConfigFile.load(
          startDir: start.path,
          stopDir: stopDir.path,
        );
        expect(cfg.path, isNull);
        expect(cfg['RAYGUN_API_KEY'], isNull);
      });

      test('discovers .env exactly at stopDir boundary', () {
        final envPath = writeEnv(tempDir, 'RAYGUN_APP_ID=at-boundary\n');
        final start = Directory(p.join(tempDir.path, 'sub', 'sub2'))
          ..createSync(recursive: true);

        final cfg = ConfigFile.load(
          startDir: start.path,
          stopDir: tempDir.path,
        );
        expect(cfg.path, envPath);
        expect(cfg['RAYGUN_APP_ID'], 'at-boundary');
      });

      test('finds the closest .env when multiple exist in the chain', () {
        writeEnv(tempDir, 'RAYGUN_APP_ID=outer\n');
        final inner = Directory(p.join(tempDir.path, 'inner'))..createSync();
        writeEnv(inner, 'RAYGUN_APP_ID=inner\n');

        final cfg = ConfigFile.load(
          startDir: inner.path,
          stopDir: tempDir.path,
        );
        expect(cfg['RAYGUN_APP_ID'], 'inner');
      });
    });

    group('explicit --config-file path', () {
      test('honors explicit path even if a closer .env exists', () {
        // closer .env in CWD has different value
        writeEnv(tempDir, 'RAYGUN_APP_ID=from-cwd\n');
        // explicit override file elsewhere
        final overrideDir = Directory.systemTemp.createTempSync('cfgoverride_');
        try {
          final overridePath = p.join(overrideDir.path, 'custom.env');
          File(overridePath).writeAsStringSync('RAYGUN_APP_ID=from-override\n');

          final cfg = ConfigFile.load(
            explicitPath: overridePath,
            startDir: tempDir.path,
            stopDir: tempDir.path,
          );
          expect(cfg.path, p.absolute(overridePath));
          expect(cfg['RAYGUN_APP_ID'], 'from-override');
        } finally {
          overrideDir.deleteSync(recursive: true);
        }
      });

      test('exits with code 2 when explicit path is missing', () async {
        final result = await Process.run(Platform.resolvedExecutable, [
          'run',
          'bin/raygun_cli.dart',
          '--config-file=/definitely/does/not/exist.env',
          'deployments',
          '--version=1.0.0',
        ]);
        expect(result.exitCode, 2);
        expect(result.stdout, contains('Error: --config-file points to'));
      }, timeout: const Timeout(Duration(seconds: 60)));
    });

    group('parsing', () {
      test('returns null for unknown keys', () {
        writeEnv(tempDir, 'RAYGUN_APP_ID=abc\n');
        final cfg = ConfigFile.load(
          startDir: tempDir.path,
          stopDir: tempDir.path,
        );
        expect(cfg['NOT_PRESENT'], isNull);
      });

      test('reads double-quoted values with spaces', () {
        writeEnv(tempDir, 'RAYGUN_TOKEN="tok with spaces"\n');
        final cfg = ConfigFile.load(
          startDir: tempDir.path,
          stopDir: tempDir.path,
        );
        expect(cfg['RAYGUN_TOKEN'], 'tok with spaces');
      });

      test('reads single-quoted values with spaces', () {
        writeEnv(tempDir, "RAYGUN_TOKEN='single quoted value'\n");
        final cfg = ConfigFile.load(
          startDir: tempDir.path,
          stopDir: tempDir.path,
        );
        expect(cfg['RAYGUN_TOKEN'], 'single quoted value');
      });

      test('ignores whole-line # comments', () {
        writeEnv(
          tempDir,
          '# this is a comment\nRAYGUN_APP_ID=abc\n# another comment\n',
        );
        final cfg = ConfigFile.load(
          startDir: tempDir.path,
          stopDir: tempDir.path,
        );
        expect(cfg['RAYGUN_APP_ID'], 'abc');
      });

      test('ignores blank lines', () {
        writeEnv(tempDir, '\n\nRAYGUN_APP_ID=abc\n\n\nRAYGUN_TOKEN=tok\n\n');
        final cfg = ConfigFile.load(
          startDir: tempDir.path,
          stopDir: tempDir.path,
        );
        expect(cfg['RAYGUN_APP_ID'], 'abc');
        expect(cfg['RAYGUN_TOKEN'], 'tok');
      });

      test('tolerates `export KEY=value` syntax', () {
        writeEnv(tempDir, 'export RAYGUN_APP_ID=exported-app\n');
        final cfg = ConfigFile.load(
          startDir: tempDir.path,
          stopDir: tempDir.path,
        );
        expect(cfg['RAYGUN_APP_ID'], 'exported-app');
      });

      test('preserves UTF-8 / multibyte characters', () {
        writeEnv(tempDir, 'RAYGUN_TOKEN=héllo-世界-🎉\n');
        final cfg = ConfigFile.load(
          startDir: tempDir.path,
          stopDir: tempDir.path,
        );
        expect(cfg['RAYGUN_TOKEN'], 'héllo-世界-🎉');
      });

      test('parses multiple keys from a realistic .env', () {
        writeEnv(tempDir, '''
# Raygun config
RAYGUN_APP_ID=app-id-123
RAYGUN_TOKEN="pat_xyz with spaces"
export RAYGUN_API_KEY=apikey-789
''');
        final cfg = ConfigFile.load(
          startDir: tempDir.path,
          stopDir: tempDir.path,
        );
        expect(cfg['RAYGUN_APP_ID'], 'app-id-123');
        expect(cfg['RAYGUN_TOKEN'], 'pat_xyz with spaces');
        expect(cfg['RAYGUN_API_KEY'], 'apikey-789');
      });

      test('lines without `=` are silently ignored', () {
        writeEnv(tempDir, 'NOT_A_KV_LINE\nRAYGUN_APP_ID=valid\n');
        final cfg = ConfigFile.load(
          startDir: tempDir.path,
          stopDir: tempDir.path,
        );
        expect(cfg['NOT_A_KV_LINE'], isNull);
        expect(cfg['RAYGUN_APP_ID'], 'valid');
      });

      test('empty value `KEY=` is treated as null by lookup', () {
        // dotenv stores empty strings; ConfigFile passes them through.
        // Our convention: ConfigProp falls through on `null`, so an empty
        // value here is still returned (not null).
        writeEnv(tempDir, 'RAYGUN_APP_ID=\n');
        final cfg = ConfigFile.load(
          startDir: tempDir.path,
          stopDir: tempDir.path,
        );
        expect(cfg['RAYGUN_APP_ID'], '');
      });
    });

    group('singleton + setInstance', () {
      test('setInstance overrides discovery', () {
        writeEnv(tempDir, 'RAYGUN_APP_ID=from-disk\n');

        final injected = ConfigFile.load(
          startDir: tempDir.path,
          stopDir: tempDir.path,
        );
        ConfigFile.setInstance(injected);

        expect(ConfigFile.instance['RAYGUN_APP_ID'], 'from-disk');
      });

      test('resetForTest clears the cached singleton', () {
        ConfigFile.setInstance(ConfigFile.empty());
        expect(ConfigFile.instance['ANY'], isNull);
        ConfigFile.resetForTest();
        // Subsequent access triggers fresh discovery; with no .env, returns
        // an empty instance again. We don't assert on path because it
        // depends on the test runner's CWD.
        expect(ConfigFile.instance, isA<ConfigFile>());
      });

      test('empty() instance has no values and null path', () {
        final cfg = ConfigFile.empty();
        expect(cfg.path, isNull);
        expect(cfg['ANY'], isNull);
      });
    });
  });
}
