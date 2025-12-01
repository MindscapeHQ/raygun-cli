import 'dart:io';

import 'package:args/args.dart';
import 'package:raygun_cli/src/core/raygun_command.dart';
import 'package:raygun_cli/src/deployments/deployments.dart';
import 'package:raygun_cli/src/deployments/deployments_api.dart';

final DeploymentsCommand deploymentsCommand = DeploymentsCommand(
  api: DeploymentsApi.create(),
);

class DeploymentsCommand extends RaygunCommand {
  const DeploymentsCommand({required this.api});

  final DeploymentsApi api;

  @override
  String get name => 'deployments';

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
