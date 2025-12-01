import 'package:raygun_cli/src/dsym/dsym_api.dart';
import 'package:args/args.dart';
import '../config_props.dart';

class Dsym {
  final ArgResults command;
  final bool verbose;
  final DsymApi api;

  Dsym({required this.command, required this.verbose, required this.api});

  Future<bool> upload() async {
    if (!command.wasParsed('path')) {
      print('Error: Missing "--path"');
      print('  Please provide "--path" via argument');
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
    final appId = ConfigProp.appId.load(command);

    if (verbose) {
      print('app-id: $appId');
      print('external-access-token: $externalAccessToken');
      print('path: $path');
    }

    final success = await api.uploadDsym(
      appId: appId,
      externalAccessToken: externalAccessToken,
      path: path,
    );

    return success;
  }
}
