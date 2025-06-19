import 'dart:io';

import 'package:args/args.dart';
import 'package:raygun_cli/src/core/raygun_command.dart';
import 'package:raygun_cli/src/sourcemap/flutter/sourcemap_flutter.dart';
import 'package:raygun_cli/src/sourcemap/node/sourcemap_node.dart';
import 'package:raygun_cli/src/sourcemap/sourcemap_api.dart';
import 'package:raygun_cli/src/sourcemap/sourcemap_single_file.dart';

SourcemapCommand sourcemapCommand =
    SourcemapCommand(api: SourcemapApi.create());

class SourcemapCommand extends RaygunCommand {
  const SourcemapCommand({
    required this.api,
  });

  final SourcemapApi api;

  @override
  String get name => 'sourcemap';

  @override
  ArgParser buildParser() {
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

  @override
  void execute(
    ArgResults command,
    bool verbose,
  ) {
    if (command.wasParsed('help')) {
      print('Usage: raygun-cli $name (upload|list|delete) <arguments>');
      print(buildParser().usage);
      exit(0);
    }

    run(
      command: command,
      verbose: verbose,
    ).then((result) {
      if (result) {
        exit(0);
      } else {
        exit(2);
      }
    }).catchError((e) {
      print('Error: $e');
      exit(2);
    });
  }

  Future<bool> run({
    required ArgResults command,
    required bool verbose,
  }) async {
    if (command.wasParsed('help')) {
      print('Usage: raygun-cli sourcemap <arguments>');
      print(buildParser().usage);
      return false;
    }

    switch (command.option('platform')) {
      case null:
        return SourcemapSingleFile(
          command: command,
          verbose: verbose,
          api: api,
        ).upload();
      case 'flutter':
        return SourcemapFlutter(
          command: command,
          verbose: verbose,
          api: api,
        ).upload();
      case 'node':
        return SourcemapNode(
          command: command,
          verbose: verbose,
          api: api,
        ).upload();
      default:
        print('Unsupported platform');
        return false;
    }
  }
}
