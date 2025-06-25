import 'package:raygun_cli/src/proguard/proguard_api.dart';
import 'package:args/args.dart';
import '../config_props.dart';

class Proguard {
  final ArgResults command;
  final bool verbose;
  final ProguardApi api;

  Proguard({
    required this.command,
    required this.verbose,
    required this.api,
  });

  Future<bool> upload() async {
    if (!command.wasParsed('path')) {
      print('Error: Missing "--path"');
      print('  Please provide "--path" via argument');
      return false;
    }

    if (!command.wasParsed('version')) {
      print('Error: Missing "--version"');
      print('  Please provide "--version" via argument');
      return false;
    }

    if (!command.wasParsed('external-access-token')) {
      print('Error: Missing "--external-access-token"');
      print('  Please provide "--external-access-token" via argument');
      return false;
    }

    final externalAccessToken =
        command.option('external-access-token') as String;
    final path = command.option('path') as String;
    final version = command.option('version') as String;
    final overwrite = command.wasParsed('overwrite');
    final appId = ConfigProp.appId.load(command);

    if (verbose) {
      print('app-id: $appId');
      print('external-access-token: $externalAccessToken');
      print('path: $path');
      print('version: $version');
      print('overwrite: $overwrite');
    }

    final success = await api.uploadProguardMapping(
      appId: appId,
      externalAccessToken: externalAccessToken,
      path: path,
      version: version,
      overwrite: overwrite,
    );

    return success;
  }
}
