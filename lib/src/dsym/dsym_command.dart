import 'dart:io';

import 'package:args/args.dart';
import 'package:raygun_cli/src/core/raygun_command.dart';
import 'package:raygun_cli/src/dsym/dsym.dart';
import 'package:raygun_cli/src/dsym/dsym_api.dart';

final DsymCommand dsymCommand = DsymCommand(api: DsymApi.create());

class DsymCommand extends RaygunCommand {
  const DsymCommand({required this.api});

  final DsymApi api;

  @override
  String get name => 'dsym';

  @override
  ArgParser buildParser() {
    return ArgParser()
      ..addFlag(
        'help',
        abbr: 'h',
        negatable: false,
        help: 'Print dsym usage information',
      )
      ..addOption(
        'app-id',
        mandatory: true,
        help: 'Raygun application ID',
      )
      ..addOption(
        'external-access-token',
        mandatory: true,
        help: 'Raygun external access token',
      )
      ..addOption(
        'path',
        mandatory: true,
        help: 'Path to the dSYM zip file',
      );
  }

  @override
  void execute(ArgResults command, bool verbose) {
    if (command.wasParsed('help')) {
      print('Usage: raygun-cli $name <arguments>');
      print(buildParser().usage);
      exit(0);
    }

    Dsym(
      command: command,
      verbose: verbose,
      api: api,
    ).upload().then((success) {
      if (success) {
        exit(0);
      } else {
        exit(1);
      }
    }).catchError((error) {
      print('Error uploading dSYM file: $error');
      exit(2);
    });
  }
}
