import 'dart:io';

import 'package:args/args.dart';
import 'package:raygun_cli/environment.dart';

/// Configuration properties for the Raygun CLI
class ConfigProps {
  /// Raygun's application ID
  final String appId;

  /// Raygun's access token
  final String token;

  ConfigProps._({
    required this.appId,
    required this.token,
  });

  /// Load configuration properties from arguments or environment variables
  /// and return a new instance of [ConfigProps] or exit with code 2.
  factory ConfigProps.load(ArgResults arguments) {
    String? appId;
    String? token;

    // Providing app-id and token via argument takes priority
    if (arguments.wasParsed('app-id')) {
      appId = arguments['app-id'];
    } else {
      appId = Environment.instance.raygunAppId;
    }

    if (appId == null) {
      print('Error: Missing "app-id"');
      print(
          '  Please provide "app-id" via argument or environment variable "RAYGUN_APP_ID"');
      exit(2);
    }

    if (arguments.wasParsed('token')) {
      token = arguments['token'];
    } else {
      token = Environment.instance.raygunToken;
    }

    if (token == null) {
      print('Error: Missing "token"');
      print(
          '  Please provide "token" via argument or environment variable "RAYGUN_TOKEN"');
      exit(2);
    }

    if (arguments.wasParsed('verbose')) {
      print('App ID: $appId');
      print('Token: $token');
    }

    return ConfigProps._(
      appId: appId,
      token: token,
    );
  }
}
