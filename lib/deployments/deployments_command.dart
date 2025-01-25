import 'dart:io';

import 'package:args/args.dart';
import 'package:raygun_cli/deployments/deployments.dart';

import '../config_props.dart';

const kDeploymentsCommand = 'deployments';

ArgParser buildParserDeployments() {
  return ArgParser()
    ..addFlag(
      'help',
      abbr: 'h',
      negatable: false,
      help: 'Print deployments usage information',
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
      'api-key',
      mandatory: true,
      help: 'API key from the Raygun account you are deploying to',
    )
    ..addOption(
      'version',
      mandatory: true,
      help: 'Version of the software you are deploying and want Raygun to know about',
    )
    ..addOption(
      'scm-type',
      mandatory: false,
      allowed: ['GitHub', 'Bitbucket', 'GitLab', 'AzureDevOps'],
      help: 'Type of the source control management system you are deploying from - if provided, one of [GitHub, Bitbucket, GitLab, AzureDevOps]',
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
    ..addOption(
      'comment',
      mandatory: false,
      help: 'Deployment comment',
    );
}

void parseDeploymentsCommand(ArgResults command, bool verbose) {
  if (command.wasParsed('help')) {
    print('Usage: raygun-cli deployments <arguments>');
    print(buildParserDeployments().usage);
    exit(0);
  }

  final configProps = ConfigProps.load(command, verbose: verbose);

  Deployments(
    command: command,
    verbose: verbose,
    config: configProps,
  ).notify();
  
}
