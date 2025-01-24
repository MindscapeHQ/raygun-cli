import 'package:args/args.dart';

import '../config_props.dart';

abstract class SourcemapBase {
  SourcemapBase({
    required this.command,
    required this.verbose,
    required ConfigProps config,
  }) {
    appId = config.appId;
    token = config.token;
  }

  final ArgResults command;
  final bool verbose;
  late final String appId;
  late final String token;

  Future<void> upload();
}
