import 'package:raygun_cli/src/sourcemap/sourcemap_base.dart';

/// Uploads a Node app sourcemap file to Raygun.
/// TODO: Not implemented yet.
class SourcemapNode extends SourcemapBase {
  SourcemapNode({
    required super.command,
    required super.verbose,
  });

  @override
  Future<bool> upload() async {
    // final baseUri = command.option('base-uri')!;
    // final src = command.option('src')!;

    // TODO: search for all map files in source folder and upload them.

    print('Comming soon!');
    return false;
  }
}
