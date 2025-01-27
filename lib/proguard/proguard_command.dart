import 'dart:io';

import 'package:args/args.dart';
import 'package:raygun_cli/proguard/proguard.dart';

const kProguardCommand = 'proguard';

ArgParser buildParserProguard() {
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

void parseProguardCommand(ArgResults command, bool verbose) {
  if (command.wasParsed('help')) {
    print('Usage: raygun-cli proguard <arguments>');
    print(buildParserProguard().usage);
    exit(0);
  }

  Proguard(
    command: command,
    verbose: verbose,
  ).upload();
}
