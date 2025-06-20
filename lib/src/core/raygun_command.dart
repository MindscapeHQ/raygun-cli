import 'package:args/args.dart';

abstract class RaygunCommand {
  const RaygunCommand();

  String get name;

  void execute(ArgResults command, bool verbose);

  Future<bool> run({
    required ArgResults command,
    required String appId,
    required String token,
  });

  ArgParser buildParserSymbols();
}
