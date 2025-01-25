import 'dart:io';

import 'package:args/args.dart';
import 'package:raygun_cli/sourcemap/flutter/sourcemap_flutter.dart';
import 'package:raygun_cli/sourcemap/node/sourcemap_node.dart';
import 'package:raygun_cli/sourcemap/sourcemap_single_file.dart';

import '../config_props.dart';

const kSourcemapCommand = 'sourcemap';

ArgParser buildParserSourcemap() {
  return ArgParser()
    ..addFlag(
      'help',
      abbr: 'h',
      negatable: false,
      help: 'Print sourcemap usage information.',
    )
    ..addOption(
      'app-id',
      help: 'Raygun application ID',
    )
    ..addOption(
      'token',
      help: 'Raygun access token',
    )
    ..addOption(
      'platform',
      abbr: 'p',
      help: 'Specify project platform. Supported: [flutter, node]',
    )
    ..addOption(
      'uri',
      help: 'Application URI (e.g. https://localhost:3000/main.dart.js)',
    )
    ..addOption(
      'base-uri',
      help: 'Base application URI (e.g. https://localhost:3000/)',
    )
    ..addOption(
      'input-map',
      abbr: 'i',
      help: 'Single sourcemap file',
    )
    ..addOption(
      'src',
      abbr: 's',
      help: 'Source files',
    );
}

void parseSourcemapCommand(ArgResults command, bool verbose) {
  if (command.wasParsed('help')) {
    print('Usage: raygun-cli sourcemap <arguments>');
    print(buildParserSourcemap().usage);
    exit(0);
  }
  final configProps = ConfigProps.load(command, verbose: verbose);

  switch (command.option('platform')) {
    case null:
      SourcemapSingleFile(
        command: command,
        verbose: verbose,
        config: configProps,
      ).upload();
    case 'flutter':
      SourcemapFlutter(
        command: command,
        verbose: verbose,
        config: configProps,
      ).upload();
    case 'node':
      SourcemapNode(
        command: command,
        verbose: verbose,
        config: configProps,
      ).upload();
    default:
      print('Unsupported platform');
      exit(1);
  }
}
