import 'dart:io';

import 'package:args/args.dart';
import 'package:raygun_cli/src/core/raygun_command.dart';
import 'package:raygun_cli/src/deployments/deployments.dart';
import 'package:raygun_cli/src/deployments/deployments_api.dart';

/// Default deployments command wired to the production Raygun API client.
final DeploymentsCommand deploymentsCommand = DeploymentsCommand(
  api: DeploymentsApi.create(),
);

/// CLI command that records a deployment in Raygun.
class DeploymentsCommand extends RaygunCommand {
  /// Creates a deployments command that sends requests through [api].
  const DeploymentsCommand({required this.api});

  /// API client used to create deployment records.
  final DeploymentsApi api;

  /// Name used to invoke this command from the top-level CLI parser.
  @override
  String get name => 'deployments';

  /// Builds the argument parser for deployment notification options.
  @override
  ArgParser buildParser() {
    return ArgParser()
      ..addFlag(
        'help',
        abbr: 'h',
        negatable: false,
        help: 'Print deployments usage information',
      )
      ..addOption('token', mandatory: true, help: 'Raygun access token')
      ..addOption(
        'api-key',
        mandatory: true,
        help: 'API key from the Raygun account you are deploying to',
      )
      ..addOption(
        'version',
        mandatory: true,
        help:
            'Version of the software you are deploying and want Raygun to know about',
      )
      ..addOption(
        'scm-type',
        mandatory: false,
        allowed: ['GitHub', 'Bitbucket', 'GitLab', 'AzureDevOps'],
        help:
            'Type of the source control management system you are deploying from - if provided, one of [GitHub, Bitbucket, GitLab, AzureDevOps]',
      )
      ..addOption(
        'scm-identifier',
        mandatory: false,
        help: 'Commit that this deployment is based on',
      )
      ..addOption(
        'owner-name',
        mandatory: false,
        help: 'Name of the person deploying the software',
      )
      ..addOption(
        'email-address',
        mandatory: false,
        help: 'Email address of the person deploying the software',
      )
      ..addOption('comment', mandatory: false, help: 'Deployment comment');
  }

  /// Executes the deployment command and exits with a process status code.
  @override
  void execute(ArgResults command, bool verbose) {
    if (command.wasParsed('help')) {
      print('Usage: raygun-cli $name <arguments>');
      print(buildParser().usage);
      exit(0);
    }

    Deployments(command: command, verbose: verbose, deploymentsApi: api)
        .notify()
        .then((success) {
          if (success) {
            exit(0);
          } else {
            exit(1);
          }
        })
        .catchError((error) {
          print('Error creating deployment: $error');
          exit(2);
        });
  }
}
