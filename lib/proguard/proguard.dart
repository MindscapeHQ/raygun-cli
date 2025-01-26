import 'dart:io';

import 'package:raygun_cli/proguard/proguard_api.dart';
import 'package:args/args.dart';
import '../config_props.dart';

class Proguard {
  final ArgResults command;
  final bool verbose;
  late final String appId;
  late final String token;
  Proguard({
    required this.command,
    required this.verbose,
    required ConfigProps config,
  }) {
    appId = config.appId;
    token = config.token;
  }

  Future<void> upload() async {
    if (!command.wasParsed('path')) {
      print('Error: Missing "--path"');
      print('  Please provide "--path" via argument');
      exit(2);
    }

    if (!command.wasParsed('version')) {
      print('Error: Missing "--version"');
      print('  Please provide "--version" via argument');
      exit(2);
    }

    if (!command.wasParsed('external-access-token')) {
      print('Error: Missing "--external-access-token"');
      print('  Please provide "--external-access-token" via argument');
      exit(2);
    }

    final externalAccessToken =
        command.option('external-access-token') as String;
    final path = command.option('path') as String;
    final version = command.option('version') as String;
    final overwrite = command.wasParsed('overwrite');

    if (verbose) {
      print('app-id: $appId');
      print('token: $token');
      print('external-access-token: $externalAccessToken');
      print('path: $path');
      print('version: $version');
      print('overwrite: $overwrite');
    }

    final success = await uploadProguardMapping(
      appId: appId,
      externalAccessToken: externalAccessToken,
      path: path,
      version: version,
      overwrite: overwrite,
    );

    if (success) {
      exit(0);
    } else {
      exit(2);
    }
  }
}
