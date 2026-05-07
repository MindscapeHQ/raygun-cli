import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

/// End-to-end tests that spawn the real CLI binary as a subprocess.
///
/// These tests verify the full user-facing flow: argument parsing →
/// `--config-file` handling → `ConfigFile` discovery → `ConfigProp.load`
/// resolution → values reaching the command code.
///
/// Strategy: we use the `deployments` command with `--verbose`, which prints
/// the resolved values (`token: ...`, `api-key: ...`) before attempting the
/// HTTP call. We assert on those verbose lines. The HTTP call itself will
/// fail (network/401), which is expected and irrelevant — we only care that
/// the credentials flowed through correctly.
void main() {
  late Directory tempDir;
  final cliEntry = p.absolute('bin/raygun_cli.dart');

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('raygun_cli_e2e_');
  });

  tearDown(() {
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  /// Writes a `.env` file in [dir].
  void writeEnv(Directory dir, Map<String, String> values) {
    final body = values.entries.map((e) => '${e.key}=${e.value}').join('\n');
    File(p.join(dir.path, '.env')).writeAsStringSync(body);
  }

  /// Runs the CLI in [cwd] with the given [args] and [env] (no parent env
  /// inherited so the host's RAYGUN_* vars can never bleed into the test).
  Future<ProcessResult> runCli(
    Directory cwd, {
    required List<String> args,
    Map<String, String> env = const {},
  }) {
    return Process.run(
      Platform.resolvedExecutable,
      ['run', cliEntry, ...args],
      workingDirectory: cwd.path,
      environment: env,
      includeParentEnvironment: false,
    );
  }

  group('E2E: .env discovery', () {
    test(
      'CLI loads credentials from .env in CWD',
      () async {
        writeEnv(tempDir, {
          'RAYGUN_TOKEN': 'tok-cwd-e2e',
          'RAYGUN_API_KEY': 'key-cwd-e2e',
        });
        final result = await runCli(
          tempDir,
          args: ['-v', 'deployments', '--version=1.0.0'],
        );
        expect(
          result.stdout,
          contains('Loaded config from ${p.join(tempDir.path, '.env')}'),
        );
        expect(result.stdout, contains('token: tok-cwd-e2e'));
        expect(result.stdout, contains('api-key: key-cwd-e2e'));
      },
      timeout: const Timeout(Duration(seconds: 90)),
    );

    test(
      'CLI walks up parent directories to find .env',
      () async {
        writeEnv(tempDir, {
          'RAYGUN_TOKEN': 'tok-parent',
          'RAYGUN_API_KEY': 'key-parent',
        });
        final nested = Directory(p.join(tempDir.path, 'a', 'b'))
          ..createSync(recursive: true);
        // Pin the upward walk's stop boundary to tempDir via HOME.
        final result = await runCli(
          nested,
          args: ['-v', 'deployments', '--version=1.0.0'],
          env: {'HOME': tempDir.path},
        );
        expect(
          result.stdout,
          contains('Loaded config from ${p.join(tempDir.path, '.env')}'),
        );
        expect(result.stdout, contains('token: tok-parent'));
        expect(result.stdout, contains('api-key: key-parent'));
      },
      timeout: const Timeout(Duration(seconds: 90)),
    );
  });

  group('E2E: --config-file flag', () {
    test(
      'explicit --config-file=<path> is honored',
      () async {
        final altDir = Directory.systemTemp.createTempSync('raygun_cli_alt_');
        try {
          final altPath = p.join(altDir.path, 'custom.env');
          File(altPath).writeAsStringSync(
            'RAYGUN_TOKEN=tok-explicit\nRAYGUN_API_KEY=key-explicit\n',
          );

          // CWD .env exists with different values — must be ignored.
          writeEnv(tempDir, {
            'RAYGUN_TOKEN': 'tok-cwd-should-not-win',
            'RAYGUN_API_KEY': 'key-cwd-should-not-win',
          });

          final result = await runCli(
            tempDir,
            args: [
              '-v',
              '--config-file=$altPath',
              'deployments',
              '--version=1.0.0',
            ],
          );
          expect(result.stdout, contains('Loaded config from $altPath'));
          expect(result.stdout, contains('token: tok-explicit'));
          expect(result.stdout, contains('api-key: key-explicit'));
          expect(result.stdout, isNot(contains('tok-cwd-should-not-win')));
        } finally {
          altDir.deleteSync(recursive: true);
        }
      },
      timeout: const Timeout(Duration(seconds: 90)),
    );

    test(
      'invalid --config-file path exits with code 2',
      () async {
        final result = await runCli(
          tempDir,
          args: [
            '--config-file=/definitely/does/not/exist.env',
            'deployments',
            '--version=1.0.0',
          ],
        );
        expect(result.exitCode, 2);
        expect(
          result.stdout,
          contains('Error: --config-file points to a missing file'),
        );
      },
      timeout: const Timeout(Duration(seconds: 90)),
    );
  });

  group('E2E: precedence', () {
    test(
      'CLI argument wins over both env var and .env file',
      () async {
        writeEnv(tempDir, {
          'RAYGUN_TOKEN': 'tok-from-file',
          'RAYGUN_API_KEY': 'key-from-file',
        });
        final result = await runCli(
          tempDir,
          args: [
            '-v',
            'deployments',
            '--version=1.0.0',
            '--token=tok-from-arg',
            '--api-key=key-from-arg',
          ],
          env: {
            'RAYGUN_TOKEN': 'tok-from-env',
            'RAYGUN_API_KEY': 'key-from-env',
          },
        );
        expect(result.stdout, contains('token: tok-from-arg'));
        expect(result.stdout, contains('api-key: key-from-arg'));
        expect(result.stdout, isNot(contains('tok-from-env')));
        expect(result.stdout, isNot(contains('tok-from-file')));
      },
      timeout: const Timeout(Duration(seconds: 90)),
    );

    test(
      'environment variable wins over .env file when arg is absent',
      () async {
        writeEnv(tempDir, {
          'RAYGUN_TOKEN': 'tok-from-file',
          'RAYGUN_API_KEY': 'key-from-file',
        });
        final result = await runCli(
          tempDir,
          args: ['-v', 'deployments', '--version=1.0.0'],
          env: {
            'RAYGUN_TOKEN': 'tok-from-env',
            'RAYGUN_API_KEY': 'key-from-env',
          },
        );
        expect(result.stdout, contains('token: tok-from-env'));
        expect(result.stdout, contains('api-key: key-from-env'));
        expect(result.stdout, isNot(contains('tok-from-file')));
      },
      timeout: const Timeout(Duration(seconds: 90)),
    );

    test(
      '.env file is used as the lowest-priority fallback',
      () async {
        writeEnv(tempDir, {
          'RAYGUN_TOKEN': 'tok-only-in-file',
          'RAYGUN_API_KEY': 'key-only-in-file',
        });
        final result = await runCli(
          tempDir,
          args: ['-v', 'deployments', '--version=1.0.0'],
        );
        expect(result.stdout, contains('token: tok-only-in-file'));
        expect(result.stdout, contains('api-key: key-only-in-file'));
      },
      timeout: const Timeout(Duration(seconds: 90)),
    );

    test(
      'mixed: env supplies token, .env supplies api-key',
      () async {
        writeEnv(tempDir, {'RAYGUN_API_KEY': 'key-from-file'});
        final result = await runCli(
          tempDir,
          args: ['-v', 'deployments', '--version=1.0.0'],
          env: {'RAYGUN_TOKEN': 'tok-from-env'},
        );
        expect(result.stdout, contains('token: tok-from-env'));
        expect(result.stdout, contains('api-key: key-from-file'));
      },
      timeout: const Timeout(Duration(seconds: 90)),
    );
  });

  group('E2E: missing config', () {
    test(
      'exits with code 2 and helpful error when no source provides creds',
      () async {
        // No .env in tempDir, no env vars, no args → must exit(2).
        final result = await runCli(
          tempDir,
          args: ['deployments', '--version=1.0.0'],
        );
        expect(result.exitCode, 2);
        expect(result.stdout, contains('Missing'));
        expect(result.stdout, contains('.env config file'));
      },
      timeout: const Timeout(Duration(seconds: 90)),
    );

    test(
      'empty .env value falls through and surfaces "Missing" not an HTTP error',
      () async {
        // The user's .env exists but the value is blank — common after
        // copying example/.env.example. We must surface the friendly
        // "Missing" exit-code-2 instead of letting '' propagate to an
        // opaque 401/404 from the Raygun API.
        writeEnv(tempDir, {'RAYGUN_TOKEN': '', 'RAYGUN_API_KEY': ''});
        final result = await runCli(
          tempDir,
          args: ['deployments', '--version=1.0.0'],
        );
        expect(result.exitCode, 2);
        expect(result.stdout, contains('Missing'));
        expect(
          result.stdout,
          contains('Empty or whitespace-only values are treated as missing'),
        );
      },
      timeout: const Timeout(Duration(seconds: 90)),
    );

    test(
      'parent-directory .env is NOT discovered when HOME is unset',
      () async {
        // Regression for the unbounded-walk bug (PR #62 review): when HOME
        // and USERPROFILE are both unset, we used to walk up to the
        // filesystem root and could pick up a stray /.env. Now we only
        // check the CWD, so a parent .env must not be discovered.
        writeEnv(tempDir, {
          'RAYGUN_TOKEN': 'tok-from-parent',
          'RAYGUN_API_KEY': 'key-from-parent',
        });
        final nested = Directory(p.join(tempDir.path, 'sub'))
          ..createSync(recursive: true);

        final result = await runCli(
          nested,
          args: ['-v', 'deployments', '--version=1.0.0'],
          // No HOME, no USERPROFILE, no RAYGUN_* vars.
        );
        // Should fail with the friendly Missing message — neither the env
        // nor the parent .env should have supplied credentials.
        expect(result.exitCode, 2);
        expect(result.stdout, contains('Missing'));
        expect(result.stdout, isNot(contains('tok-from-parent')));
        expect(result.stdout, isNot(contains('key-from-parent')));
        expect(
          result.stdout,
          contains(
            'HOME/USERPROFILE not set; restricting .env discovery '
            'to current directory',
          ),
        );
      },
      timeout: const Timeout(Duration(seconds: 90)),
    );

    test(
      'empty .env value falls through to env var',
      () async {
        // .env has the keys but blank; env vars supply real values.
        // Verbose output should show the "Ignoring empty" notice and then
        // resolve from the env var tier.
        writeEnv(tempDir, {'RAYGUN_TOKEN': '', 'RAYGUN_API_KEY': ''});
        final result = await runCli(
          tempDir,
          args: ['-v', 'deployments', '--version=1.0.0'],
          env: {
            'RAYGUN_TOKEN': 'tok-from-env',
            'RAYGUN_API_KEY': 'key-from-env',
          },
        );
        expect(result.stdout, contains('token: tok-from-env'));
        expect(result.stdout, contains('api-key: key-from-env'));
        expect(
          result.stdout,
          contains('[VERBOSE] Resolved token from environment variable'),
        );
      },
      timeout: const Timeout(Duration(seconds: 90)),
    );
  });
}
