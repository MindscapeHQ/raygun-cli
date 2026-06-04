import 'dart:io';

import 'package:args/args.dart';
import 'package:raygun_cli/src/core/raygun_command.dart';
import 'package:raygun_cli/src/dsym/dsym.dart';
import 'package:raygun_cli/src/dsym/dsym_api.dart';

/// Default dSYM command wired to the production Raygun API client.
final DsymCommand dsymCommand = DsymCommand(api: DsymApi.create());

/// CLI command that uploads Apple dSYM archives to Raygun.
class DsymCommand extends RaygunCommand {
  /// Creates a dSYM command that sends requests through [api].
  const DsymCommand({required this.api});

  /// API client used to upload dSYM archives.
  final DsymApi api;

  /// Name used to invoke this command from the top-level CLI parser.
  @override
  String get name => 'dsym';

  /// Builds the argument parser for dSYM upload options.
  @override
  ArgParser buildParser() {
    return ArgParser()
      ..addFlag(
        'help',
        abbr: 'h',
        negatable: false,
        help: 'Print dsym usage information',
      )
      ..addOption('app-id', mandatory: true, help: 'Raygun application ID')
      ..addOption(
        'external-access-token',
        mandatory: true,
        help: 'Raygun external access token',
      )
      ..addOption('path', mandatory: true, help: 'Path to the dSYM zip file');
  }

  /// Executes the dSYM upload command and exits with a process status code.
  @override
  void execute(ArgResults command, bool verbose) {
    if (command.wasParsed('help')) {
      print('Usage: raygun-cli $name <arguments>');
      print(buildParser().usage);
      exit(0);
    }

    Dsym(command: command, verbose: verbose, api: api)
        .upload()
        .then((success) {
          if (success) {
            exit(0);
          } else {
            exit(1);
          }
        })
        .catchError((error) {
          print('Error uploading dSYM file: $error');
          exit(2);
        });
  }
}
