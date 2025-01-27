import 'package:args/args.dart';

/// Base class for JavaScript sourcemap uploaders
abstract class SourcemapBase {
  SourcemapBase({
    required this.command,
    required this.verbose,
  });

  /// Command line arguments
  final ArgResults command;

  /// Print verbose output
  final bool verbose;

  /// Uploads the sourcemap
  Future<void> upload();
}
