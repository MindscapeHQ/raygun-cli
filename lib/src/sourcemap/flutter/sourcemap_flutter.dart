import 'dart:io';

import 'package:raygun_cli/src/config_props.dart';
import 'package:raygun_cli/src/sourcemap/sourcemap_api.dart';
import 'package:raygun_cli/src/sourcemap/sourcemap_base.dart';

/// Uploads a Flutter web sourcemap file to Raygun.
class SourcemapFlutter extends SourcemapBase {
  SourcemapFlutter({
    required super.command,
    required super.verbose,
  });

  @override
  Future<void> upload() async {
    if (command.option('uri') == null && command.option('base-uri') == null) {
      print('Provide either "uri" or "base-uri"');
      exit(2);
    }
    final uri =
        command.option('uri') ?? '${command.option('base-uri')}main.dart.js';
    final path = command.option('input-map') ?? 'build/web/main.dart.js.map';
    final appId = ConfigProp.appId.load(command);
    final token = ConfigProp.token.load(command);
    if (verbose) {
      print('app-id: $appId');
      print('token: $token');
      print('input-map: $path');
      print('uri: $uri');
    }
    final out = await uploadSourcemap(
      appId: appId,
      token: token,
      path: path,
      uri: uri,
    );
    if (out) {
      exit(0);
    } else {
      exit(2);
    }
  }
}
