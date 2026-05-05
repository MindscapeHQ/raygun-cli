import 'dart:io';

import 'package:dotenv/dotenv.dart';
import 'package:path/path.dart' as p;

/// Wraps access to a `.env` config file.
///
/// Lookup order during discovery:
/// 1. An explicit path provided via `--config-file=<path>`.
/// 2. A `.env` in the current working directory.
/// 3. A `.env` in any parent directory, walking up to (but not past) the
///    user's home directory or filesystem root.
///
/// If no file is found, an empty instance is returned (silent no-op).
///
/// Allows faking via [setInstance] for testing.
class ConfigFile {
  static const String fileName = '.env';

  static ConfigFile? _instance;

  final DotEnv _env;

  /// The absolute path to the loaded `.env`, or `null` if no file was loaded.
  final String? path;

  ConfigFile._(this._env, this.path);

  /// Empty instance used when no `.env` was found.
  factory ConfigFile.empty() => ConfigFile._(DotEnv(quiet: true), null);

  /// Singleton instance access.
  ///
  /// Will perform discovery if not already initialized. To override discovery
  /// (e.g. via `--config-file`), call [setInstance] before accessing.
  static ConfigFile get instance => _instance ??= load();

  /// For testing or to inject a pre-loaded instance.
  static void setInstance(ConfigFile instance) {
    _instance = instance;
  }

  /// For testing: clear the singleton so the next [instance] access re-discovers.
  static void resetForTest() {
    _instance = null;
  }

  /// Read a value for [key]. Returns `null` if not present.
  String? operator [](String key) => _env[key];

  /// Discover and load a `.env` file.
  ///
  /// - [explicitPath]: if non-null, load that file directly. If the file does
  ///   not exist, prints an error and exits with code 2.
  /// - [startDir]: directory to start searching from (defaults to CWD).
  /// - [stopDir]: directory to stop searching at, exclusive of its parent
  ///   (defaults to the user's home directory; falls back to filesystem root).
  /// - [verbose]: if true, prints the path of the loaded file.
  static ConfigFile load({
    String? explicitPath,
    String? startDir,
    String? stopDir,
    bool verbose = false,
  }) {
    if (explicitPath != null) {
      final file = File(explicitPath);
      if (!file.existsSync()) {
        print('Error: --config-file points to a missing file: $explicitPath');
        exit(2);
      }
      final env = DotEnv(quiet: true)..load([file.absolute.path]);
      if (verbose) print('Loaded config from ${file.absolute.path}');
      return ConfigFile._(env, file.absolute.path);
    }

    final discovered = _discover(
      startDir: startDir ?? Directory.current.path,
      stopDir: stopDir ?? _defaultStopDir(),
    );
    if (discovered == null) return ConfigFile.empty();

    final env = DotEnv(quiet: true)..load([discovered]);
    if (verbose) print('Loaded config from $discovered');
    return ConfigFile._(env, discovered);
  }

  /// Walk up from [startDir] looking for [fileName]. Stops once the parent
  /// of the current directory is outside [stopDir]'s subtree, or once the
  /// filesystem root is reached.
  static String? _discover({
    required String startDir,
    required String stopDir,
  }) {
    final stopAbsolute = p.absolute(stopDir);
    var dir = Directory(p.absolute(startDir));

    while (true) {
      final candidate = File(p.join(dir.path, fileName));
      if (candidate.existsSync()) {
        return candidate.absolute.path;
      }

      // Stop if we've reached the configured boundary.
      if (p.equals(dir.path, stopAbsolute)) return null;

      final parent = dir.parent;
      // Reached filesystem root.
      if (p.equals(parent.path, dir.path)) return null;

      // Don't escape the stopDir's subtree.
      if (!p.isWithin(stopAbsolute, parent.path) &&
          !p.equals(parent.path, stopAbsolute)) {
        return null;
      }

      dir = parent;
    }
  }

  /// Default boundary for upward discovery: the user's home directory
  /// (or the filesystem root if `HOME`/`USERPROFILE` is unset).
  static String _defaultStopDir() {
    final home =
        Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'];
    if (home != null && home.isNotEmpty) return home;
    return p.rootPrefix(Directory.current.path);
  }
}
