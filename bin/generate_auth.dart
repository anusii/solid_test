#!/usr/bin/env dart
// CLI tool to generate POD authentication data for integration tests.
//
// Usage:
//   dart run solid_test:generate_auth
//   dart run solid_test:generate_auth --headless
//   dart run solid_test:generate_auth --credentials=path/to/credentials.json
//
// Copyright (C) 2025, Software Innovation Institute, ANU.
//
// Licensed under the GNU General Public License, Version 3 (the "License").
//
// License: https://opensource.org/license/gpl-3-0.

// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';

import 'package:solid_test/solid_test.dart';

void main(List<String> args) async {
  print('=== Solid POD Auth Data Generator ===\n');

  // Parse arguments.
  final headless = args.contains('--headless') || args.contains('-h');
  final credentialsPath = _getArgValue(args, '--credentials') ??
      _getArgValue(args, '-c') ??
      'integration_test/fixtures/test_credentials.json';
  final outputPath = _getArgValue(args, '--output') ??
      _getArgValue(args, '-o') ??
      'integration_test/fixtures/complete_auth_data.json';
  final issuerUrl = _getArgValue(args, '--issuer') ??
      'https://pods.dev.solidcommunity.au';
  final redirectPort = int.tryParse(_getArgValue(args, '--port') ?? '44007') ??
      44007;

  if (args.contains('--help')) {
    _printHelp();
    return;
  }

  // Create config.
  final config = PodConfig(
    issuerUrl: issuerUrl,
    redirectPort: redirectPort,
    credentialsPath: credentialsPath,
    authDataPath: outputPath,
  );

  // Load credentials.
  print('Loading credentials from: $credentialsPath');
  TestCredentials credentials;
  try {
    credentials = await TestCredentials.load(credentialsPath);
    print('  Email: ${credentials.email}');
    print('  WebID: ${credentials.webId}');
  } catch (e) {
    print('\nError: $e');
    print('\nMake sure you have a test_credentials.json file with format:');
    print('''
{
  "email": "your-email@example.com",
  "password": "your-password",
  "securityKey": "your-security-key",
  "webId": "https://pods.dev.solidcommunity.au/your-pod/profile/card#me",
  "podUrl": "https://pods.dev.solidcommunity.au/your-pod/",
  "issuer": "https://pods.dev.solidcommunity.au"
}
''');
    exit(1);
  }

  // Run authentication.
  print('\nAuthenticating with POD provider...');
  print('  Issuer: ${config.issuerUrl}');
  print('  Redirect port: ${config.redirectPort}');
  print('  Headless: $headless');
  print('');

  final result = await PodAuthAutomator.authenticate(
    credentials: credentials,
    config: config,
    headless: headless,
  );

  if (!result.success) {
    print('\nAuthentication failed: ${result.error}');
    exit(1);
  }

  // Save complete auth data.
  print('\nSaving complete auth data to: $outputPath');
  final outputFile = File(outputPath);
  await outputFile.parent.create(recursive: true);
  await outputFile.writeAsString(
    const JsonEncoder.withIndent('  ').convert(result.completeAuthData),
  );

  print('\n=== Success! ===');
  print('Auth data saved to: $outputPath');
  print('\nYou can now run your integration tests.');
}

String? _getArgValue(List<String> args, String key) {
  for (final arg in args) {
    if (arg.startsWith('$key=')) {
      return arg.substring(key.length + 1);
    }
  }
  return null;
}

void _printHelp() {
  print('''
Solid POD Auth Data Generator

Generates authentication data for integration tests by automating
the POD OAuth login flow using Puppeteer.

Usage:
  dart run solid_test:generate_auth [options]

Options:
  --headless, -h        Run browser in headless mode (default: false)
  --credentials, -c     Path to test credentials JSON (default: integration_test/fixtures/test_credentials.json)
  --output, -o          Path to save auth data (default: integration_test/fixtures/complete_auth_data.json)
  --issuer              POD issuer URL (default: https://pods.dev.solidcommunity.au)
  --port                OAuth redirect port (default: 44007)
  --help                Show this help message

Examples:
  # Interactive mode (watch the browser)
  dart run solid_test:generate_auth

  # Headless mode (for CI/CD)
  dart run solid_test:generate_auth --headless

  # Custom paths
  dart run solid_test:generate_auth --credentials=my_creds.json --output=my_auth.json
''');
}
