import 'dart:io';

import 'package:args/args.dart';
import 'package:raygun_cli/src/config_props.dart';
import 'package:raygun_cli/src/core/raygun_command.dart';
import 'package:raygun_cli/src/symbols/symbols_api.dart';

/// Default Flutter symbols command wired to the production Raygun API client.
final SymbolsCommand symbolsCommand = SymbolsCommand(api: SymbolsApi.create());

/// CLI command that uploads, lists, and deletes Flutter obfuscation symbols.
class SymbolsCommand extends RaygunCommand {
  /// Creates a symbols command that sends requests through [api].
  const SymbolsCommand({required this.api});

  /// API client used to manage symbols files.
  final SymbolsApi api;

  /// Name used to invoke this command from the top-level CLI parser.
  @override
  String get name => 'symbols';

  /// Executes the symbols command and exits with a process status code.
  @override
  void execute(ArgResults command, bool verbose) {
    if (command.wasParsed('help')) {
      print('Usage: raygun-cli $name (upload|list|delete) <arguments>');
      print(buildParser().usage);
      exit(0);
    }
    run(
          command: command,
          appId: ConfigProp.appId.load(command, verbose: verbose),
          token: ConfigProp.token.load(command, verbose: verbose),
        )
        .then((result) {
          if (result) {
            exit(0);
          } else {
            exit(2);
          }
        })
        .catchError((e) {
          print('Error: $e');
          exit(2);
        });
  }

  /// Runs the selected symbols subcommand and returns whether it succeeded.
  Future<bool> run({
    required ArgResults command,
    required String appId,
    required String token,
  }) async {
    if (command.command?.name == 'upload') {
      if (!command.wasParsed('path') || !command.wasParsed('version')) {
        print('Missing mandatory arguments');
        print(buildParser().usage);
        return false;
      }
      final path = command['path'];
      final version = command['version'];
      return api.uploadSymbols(
        appId: appId,
        token: token,
        path: path,
        version: version,
      );
    }

    if (command.command?.name == 'list') {
      return api.listSymbols(appId: appId, token: token);
    }

    if (command.command?.name == 'delete') {
      if (!command.wasParsed('id')) {
        print('Missing mandatory arguments');
        print(buildParser().usage);
        return false;
      }
      return api.deleteSymbols(appId: appId, token: token, id: command['id']);
    }

    return false;
  }

  /// Builds the argument parser for symbols upload, list, and delete options.
  @override
  ArgParser buildParser() {
    return ArgParser()
      ..addFlag(
        'help',
        abbr: 'h',
        negatable: false,
        help: 'Print $name usage information.',
      )
      ..addOption('app-id', help: 'Raygun application ID')
      ..addOption('token', help: 'Raygun access token')
      ..addOption('path', help: 'Path to symbols file, used in upload')
      ..addOption('version', help: 'App version, used in upload')
      ..addOption('id', help: 'Symbol ID, used in delete')
      ..addCommand('upload')
      ..addCommand('list')
      ..addCommand('delete');
  }
}
