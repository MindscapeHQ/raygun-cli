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
    ..addFlag('version', negatable: false, help: 'Print the tool version.')
    ..addCommand(sourcemapCommand.name, sourcemapCommand.buildParser())
    ..addCommand(symbolsCommand.name, symbolsCommand.buildParser())
    ..addCommand(deploymentsCommand.name, deploymentsCommand.buildParser())
    ..addCommand(proguardCommand.name, proguardCommand.buildParser())
    ..addCommand(dsymCommand.name, dsymCommand.buildParser());
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
    if (results.wasParsed('verbose')) {
      verbose = true;
    }

    if (verbose) {
      print('[VERBOSE] All arguments: ${results.arguments}');
    }

    if (results.wasParsed('help') || arguments.isEmpty) {
      printUsage(argParser);
      return;
    }
    if (results.wasParsed('version')) {
      print('raygun-cli version: $version');
      return;
    }

    if (results.command?.name == sourcemapCommand.name) {
      sourcemapCommand.execute(results.command!, verbose);
      return;
    }

    if (results.command?.name == symbolsCommand.name) {
      symbolsCommand.execute(results.command!, verbose);
      return;
    }

    if (results.command?.name == deploymentsCommand.name) {
      deploymentsCommand.execute(results.command!, verbose);
      return;
    }

    if (results.command?.name == proguardCommand.name) {
      proguardCommand.execute(results.command!, verbose);
      return;
    }

    if (results.command?.name == dsymCommand.name) {
      dsymCommand.execute(results.command!, verbose);
      return;
    }

    throw FormatException('Unknown or missing command.');
  } on FormatException catch (e) {
    // Print usage information if an invalid argument was provided.
    print('Error: ${e.message}');
    print('');
    printUsage(argParser);
  }
}
