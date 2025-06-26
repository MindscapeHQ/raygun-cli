import 'package:args/args.dart';

abstract class RaygunCommand {
  const RaygunCommand();

  String get name;

  void execute(ArgResults command, bool verbose);

  ArgParser buildParser();
}
