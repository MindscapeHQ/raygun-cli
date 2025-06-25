import 'dart:io';

import 'package:args/args.dart';
import 'package:raygun_cli/src/core/raygun_command.dart';
import 'package:raygun_cli/src/proguard/proguard.dart';
import 'package:raygun_cli/src/proguard/proguard_api.dart';

final ProguardCommand proguardCommand =
    ProguardCommand(api: ProguardApi.create());

class ProguardCommand extends RaygunCommand {
  const ProguardCommand({required this.api});

  final ProguardApi api;

  @override
  String get name => 'proguard';

  @override
  ArgParser buildParser() {
    return ArgParser()
      ..addFlag(
        'help',
        abbr: 'h',
        negatable: false,
        help: 'Print proguard usage information',
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
        help: 'Path to the ProGuard/R8 mapping file',
      )
      ..addOption(
        'version',
        mandatory: true,
        help: 'Version of the app this mapping file is for',
      )
      ..addFlag(
        'overwrite',
        defaultsTo: false,
        help: 'Overwrite existing mapping file if one exists for this version',
      );
  }

  @override
  void execute(ArgResults command, bool verbose) {
    if (command.wasParsed('help')) {
      print('Usage: raygun-cli $name <arguments>');
      print(buildParser().usage);
      exit(0);
    }

    Proguard(
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
      print('Error uploading ProGuard mapping file: $error');
      exit(2);
    });
  }
}
