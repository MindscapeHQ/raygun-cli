import 'package:args/args.dart';
import 'package:raygun_cli/src/sourcemap/sourcemap_api.dart';

/// Base class for JavaScript sourcemap uploaders
abstract class SourcemapBase {
  SourcemapBase({
    required this.command,
    required this.verbose,
  }) : sourcemapApi = SourcemapApi.create();

  /// Command line arguments
  final ArgResults command;

  /// Print verbose output
  final bool verbose;

  late SourcemapApi sourcemapApi;

  /// Uploads the sourcemap
  Future<bool> upload();
}
