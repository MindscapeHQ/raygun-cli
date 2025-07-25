import 'dart:io';

import 'package:raygun_cli/src/config_props.dart';
import 'package:raygun_cli/src/sourcemap/sourcemap_base.dart';

/// Uploads a single sourcemap file to Raygun.
class SourcemapSingleFile extends SourcemapBase {
  SourcemapSingleFile({
    required super.command,
    required super.verbose,
    required super.api,
  });

  @override
  Future<bool> upload() async {
    if (!command.wasParsed('uri')) {
      print('Missing "uri"');
      exit(2);
    }
    final uri = command.option('uri')!;

    if (!command.wasParsed('input-map')) {
      print('Missing "input-map"');
      exit(2);
    }
    final path = command.option('input-map')!;

    final appId = ConfigProp.appId.load(command);
    final token = ConfigProp.token.load(command);

    if (verbose) {
      print('app-id: $appId');
      print('token: $token');
      print('input-map: $path');
      print('uri: $uri');
    }

    return await api.uploadSourcemap(
      appId: appId,
      token: token,
      path: path,
      uri: uri,
    );
  }
}
