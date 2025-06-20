import 'package:args/args.dart';
import 'package:raygun_cli/raygun_cli.dart';

const String version = '1.0.0';

ArgParser buildParser() {
  return ArgParser()
    ..addFlag(
      'help',
      abbr: 'h',
      negatable: false,
      help: 'Print this usage information.',
    )
    ..addFlag(
      'verbose',
      abbr: 'v',
      negatable: false,
      help: 'Show additional command output.',
    )
    ..addFlag(
      'version',
      negatable: false,
      help: 'Print the tool version.',
    )
    ..addCommand(
      kSourcemapCommand,
      buildParserSourcemap(),
    )
    ..addCommand(
      symbolsCommand.name,
      symbolsCommand.buildParserSymbols(),
    )
    ..addCommand(
      kDeploymentsCommand,
      buildParserDeployments(),
    )
    ..addCommand(
      kProguardCommand,
      buildParserProguard(),
    );
}

void printUsage(ArgParser argParser) {
  print('Raygun CLI: $version');
  print('');
  print('Usage: raygun-cli <command> <arguments>');
  print(argParser.usage);
  print('');
  print('Commands:');
  for (final command in argParser.commands.keys) {
    print('  $command');
  }
  print('');
}

void main(List<String> arguments) {
  final ArgParser argParser = buildParser();
  try {
    final ArgResults results = argParser.parse(arguments);
    bool verbose = false;

    if (results.wasParsed('help') || arguments.isEmpty) {
      printUsage(argParser);
      return;
    }
    if (results.wasParsed('version')) {
      print('raygun-cli version: $version');
      return;
    }
    if (results.wasParsed('verbose')) {
      verbose = true;
    }

    if (results.command?.name == kSourcemapCommand) {
      parseSourcemapCommand(results.command!, verbose);
      return;
    }

    if (results.command?.name == symbolsCommand.name) {
      symbolsCommand.execute(results.command!, verbose);
      return;
    }

    if (results.command?.name == kDeploymentsCommand) {
      parseDeploymentsCommand(results.command!, verbose);
      return;
    }

    if (results.command?.name == kProguardCommand) {
      parseProguardCommand(results.command!, verbose);
      return;
    }

    if (verbose) {
      print('[VERBOSE] All arguments: ${results.arguments}');
    }
  } on FormatException catch (e) {
    // Print usage information if an invalid argument was provided.
    print(e.message);
    print('');
    printUsage(argParser);
  }
}
