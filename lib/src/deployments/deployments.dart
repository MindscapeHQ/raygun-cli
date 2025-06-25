import 'package:args/args.dart';
import 'package:raygun_cli/src/deployments/deployments_api.dart';
import '../config_props.dart';

/// Deployments command
class Deployments {
  final ArgResults command;
  final bool verbose;
  final DeploymentsApi deploymentsApi;

  Deployments({
    required this.command,
    required this.verbose,
    required this.deploymentsApi,
  });

  /// Notifies Raygun that a new deployment has been made.
  Future<bool> notify() async {
    if (!command.wasParsed('version')) {
      print('Error: Missing "--version"');
      print('  Please provide "--version" via argument');
      return false;
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

    final success = await deploymentsApi.createDeployment(
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
      return true;
    } else {
      print('Failed to create deployment');
      return false;
    }
  }
}
