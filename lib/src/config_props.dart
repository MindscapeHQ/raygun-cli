import 'dart:io';

import 'package:args/args.dart';
import 'package:raygun_cli/src/config_file.dart';
import 'package:raygun_cli/src/environment.dart';

/// A Config property is a value that can be set via:
///   1. CLI argument (highest priority)
///   2. Environment variable
///   3. `.env` config file (lowest priority)
///
/// Empty (`''`) or whitespace-only (`'   '`, `'\t'`, …) values at any tier
/// are treated as **not set** and the lookup falls through to the next tier.
/// This avoids surfacing opaque downstream errors (e.g. an HTTP 401/404 from
/// Raygun) when a user has left a key blank in their `.env` file or fat-
/// fingered an env var. Raygun credentials never legitimately contain only
/// whitespace.
class ConfigProp {
  static const appId = ConfigProp(
    name: 'app-id',
    envKey: Environment.raygunAppIdKey,
  );

  static const token = ConfigProp(
    name: 'token',
    envKey: Environment.raygunTokenKey,
  );

  static const apiKey = ConfigProp(
    name: 'api-key',
    envKey: Environment.raygunApiKeyKey,
  );

  /// The name of the property
  final String name;

  /// The environment variable key
  final String envKey;

  const ConfigProp({required this.name, required this.envKey});

  /// Load the value of the property.
  ///
  /// Resolution order: CLI argument > environment variable > `.env` file.
  /// Empty or whitespace-only values at any tier are treated as missing and
  /// fall through. Exits with code 2 if the value cannot be found in any
  /// source.
  ///
  /// When [verbose] is true, prints a `[VERBOSE] Resolved …` line indicating
  /// which source supplied the value, and a `[VERBOSE] Ignoring blank …`
  /// notice when a present-but-blank value is skipped.
  String load(ArgResults arguments, {bool verbose = false}) {
    final argValue = arguments.wasParsed(name)
        ? arguments[name] as String?
        : null;
    if (_isPresent(argValue)) {
      if (verbose) print('[VERBOSE] Resolved $name from CLI argument');
      return argValue!;
    }
    if (argValue != null && verbose) {
      print(
        '[VERBOSE] Ignoring blank value for $name from CLI argument; '
        'falling through',
      );
    }

    final envValue = Environment.instance[envKey];
    if (_isPresent(envValue)) {
      if (verbose) {
        print('[VERBOSE] Resolved $name from environment variable ($envKey)');
      }
      return envValue!;
    }
    if (envValue != null && verbose) {
      print(
        '[VERBOSE] Ignoring blank value for $name from environment variable '
        '($envKey); falling through',
      );
    }

    final fileValue = ConfigFile.instance[envKey];
    if (_isPresent(fileValue)) {
      if (verbose) {
        final path = ConfigFile.instance.path;
        final suffix = path != null ? ' ($path)' : '';
        print('[VERBOSE] Resolved $name from .env file$suffix');
      }
      return fileValue!;
    }
    if (fileValue != null && verbose) {
      print(
        '[VERBOSE] Ignoring blank value for $name from .env file; '
        'falling through',
      );
    }

    print('Error: Missing "$name"');
    print(
      '  Please provide "$name" via --$name argument, environment variable '
      '"$envKey", or as "$envKey" in a .env config file. '
      'Empty or whitespace-only values are treated as missing.',
    );
    exit(2);
  }

  static bool _isPresent(String? value) =>
      value != null && value.trim().isNotEmpty;
}
