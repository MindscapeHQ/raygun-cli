import 'dart:io';

import 'package:raygun_cli/deployments/deployments_api.dart';
import 'package:args/args.dart';
import '../config_props.dart';

class Deployments {
  final ArgResults command;
  final bool verbose;
  late final String token;
  late final String apiKey;

  Deployments({
    required this.command,
    required this.verbose,
  });

  Future<void> notify() async {
    if (!command.wasParsed('version')) {
      print('Error: Missing "--version"');
      print('  Please provide "--version" via argument');
      exit(2);
    }

    final version = command.option('version') as String;
    final ownerName = command.option('owner-name');
    final emailAddress = command.option('email-address');
    final comment = command.option('comment');
    final scmIdentifier = command.option('scm-identifier');
    final scmType = command.option('scm-type');
    final apiKey = ConfigProp.apiKey.load(command);
    final token = ConfigProp.token.load(command);

    if (verbose) {
      print('token: $token');
      print('api-key: $apiKey');
      print('version: $version');
      print('owner-name: $ownerName');
      print('email-address: $emailAddress');
      print('comment: $comment');
      print('scm-identifier: $scmIdentifier');
      print('scm-type: $scmType');
    }

    final success = await createDeployment(
      token: token,
      apiKey: apiKey,
      version: version,
      ownerName: ownerName,
      emailAddress: emailAddress,
      comment: comment,
      scmIdentifier: scmIdentifier,
      scmType: scmType,
    );

    if (success) {
      print('Deployment created successfully');
      exit(0);
    } else {
      print('Failed to create deployment');
      exit(2);
    }
  }
}
