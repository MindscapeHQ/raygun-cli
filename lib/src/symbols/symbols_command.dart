import 'dart:io';

import 'package:args/args.dart';
import 'package:raygun_cli/src/config_props.dart';
import 'package:raygun_cli/src/core/raygun_command.dart';
import 'package:raygun_cli/src/symbols/symbols_api.dart';

SymbolsCommand symbolsCommand = SymbolsCommand(api: SymbolsApi.create());

class SymbolsCommand extends RaygunCommand {
  const SymbolsCommand({
    required this.api,
  });

  final SymbolsApi api;

  @override
  String get name => 'symbols';

  @override
  void execute(ArgResults command, bool verbose) {
    if (command.wasParsed('help')) {
      print('Usage: raygun-cli $name (upload|list|delete) <arguments>');
      print(buildParserSymbols().usage);
      exit(0);
    }
    run(
      command: command,
      appId: ConfigProp.appId.load(command),
      token: ConfigProp.token.load(command),
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

  @override
  Future<bool> run({
    required ArgResults command,
    required appId,
    required token,
  }) async {
    if (command.command?.name == 'upload') {
      if (!command.wasParsed('path') || !command.wasParsed('version')) {
        print('Missing mandatory arguments');
        print(buildParserSymbols().usage);
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
      return api.listSymbols(
        appId: appId,
        token: token,
      );
    }

    if (command.command?.name == 'delete') {
      if (!command.wasParsed('id')) {
        print('Missing mandatory arguments');
        print(buildParserSymbols().usage);
        return false;
      }
      return api.deleteSymbols(
        appId: appId,
        token: token,
        id: command['id'],
      );
    }

    return false;
  }

  @override
  ArgParser buildParserSymbols() {
    return ArgParser()
      ..addFlag(
        'help',
        abbr: 'h',
        negatable: false,
        help: 'Print $name usage information.',
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
        'path',
        help: 'Path to symbols file, used in upload',
      )
      ..addOption(
        'version',
        help: 'App version, used in upload',
      )
      ..addOption(
        'id',
        help: 'Symbol ID, used in delete',
      )
      ..addCommand(
        'upload',
      )
      ..addCommand(
        'list',
      )
      ..addCommand(
        'delete',

        /// Builds the symbols command parser
      );
  }
}
