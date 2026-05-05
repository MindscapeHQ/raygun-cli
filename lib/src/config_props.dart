import 'dart:io';

import 'package:args/args.dart';
import 'package:raygun_cli/src/config_file.dart';
import 'package:raygun_cli/src/environment.dart';

/// A Config property is a value that can be set via:
///   1. CLI argument (highest priority)
///   2. Environment variable
///   3. `.env` config file (lowest priority)
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
  /// Exits with code 2 if the value cannot be found in any source.
  String load(ArgResults arguments) {
    if (arguments.wasParsed(name)) {
      return arguments[name];
    }
    final envValue = Environment.instance[envKey];
    if (envValue != null) return envValue;

    final fileValue = ConfigFile.instance[envKey];
    if (fileValue != null) return fileValue;

    print('Error: Missing "$name"');
    print(
      '  Please provide "$name" via --$name argument, environment variable '
      '"$envKey", or as "$envKey" in a .env config file.',
    );
    exit(2);
  }
}
