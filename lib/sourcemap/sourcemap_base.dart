import 'package:args/args.dart';

abstract class SourcemapBase {
  SourcemapBase({
    required this.command,
    required this.verbose,
  });

  final ArgResults command;
  final bool verbose;

  Future<void> upload();
}
