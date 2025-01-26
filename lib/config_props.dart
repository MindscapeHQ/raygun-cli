import 'dart:io';

import 'package:args/args.dart';
import 'package:raygun_cli/environment.dart';

/// A Config property is a value
/// that can be set via argument
/// or environment variable.
class ConfigProp {
  static const appIdProp = ConfigProp(
    name: 'app-id',
    envKey: Environment.raygunAppIdKey,
  );

  static const tokenProp = ConfigProp(
    name: 'token',
    envKey: Environment.raygunTokenKey,
  );

  static const apiKeyProp = ConfigProp(
    name: 'api-key',
    envKey: Environment.raygunApiKeyKey,
  );

  /// The name of the property
  final String name;

  /// The environment variable key
  final String envKey;

  const ConfigProp({
    required this.name,
    required this.envKey,
  });

  /// Load the value of the property from arguments or environment variables
  String loadFrom(ArgResults arguments) {
    String? value;
    if (arguments.wasParsed(name)) {
      value = arguments[name];
    } else {
      value = Environment.instance[envKey];
    }
    if (value == null) {
      print('Error: Missing "$name"');
      print(
          '  Please provide "$name" via argument or environment variable "$envKey"');
      exit(2);
    }
    return value;
  }
}
