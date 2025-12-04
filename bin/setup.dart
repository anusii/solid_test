#!/usr/bin/env dart
// Interactive setup wizard for solid_test.
//
// Creates fixtures directory and credentials file for POD integration tests.
//
// Usage:
//   dart run solid_test:setup
//
// Copyright (C) 2025, Software Innovation Institute, ANU.
//
// Licensed under the GNU General Public License, Version 3 (the "License").
//
// License: https://opensource.org/license/gpl-3-0.

// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';

const defaultIssuer = 'https://pods.dev.solidcommunity.au';
const fixturesPath = 'integration_test/fixtures';
const credentialsFile = '$fixturesPath/test_credentials.json';
const gitignoreFile = '$fixturesPath/.gitignore';

void main(List<String> args) async {
  print('');
  print('=== solid_test Setup ===');
  print('');
  print('This wizard will set up integration test fixtures for POD authentication.');
  print('');

  // Check for --help flag.
  if (args.contains('--help') || args.contains('-h')) {
    _printHelp();
    return;
  }

  // 1. Check prerequisites.
  if (!await _checkPrerequisites()) {
    exit(1);
  }

  // 2. Create directory structure.
  await _createFixturesDirectory();

  // 3. Check if credentials already exist.
  if (await File(credentialsFile).exists()) {
    print('');
    print('Credentials file already exists: $credentialsFile');
    final overwrite = _prompt('Overwrite? (y/n)', defaultValue: 'n');
    if (overwrite.toLowerCase() != 'y') {
      print('Keeping existing credentials.');
      await _offerGenerateAuth();
      return;
    }
  }

  // 4. Prompt for credentials.
  print('');
  print('Enter your POD credentials:');
  print('');

  final credentials = await _promptCredentials();

  // 5. Write credentials file.
  await _writeCredentialsFile(credentials);

  // 6. Optionally run generate_auth.
  await _offerGenerateAuth();

  // 7. Print next steps.
  _printNextSteps();
}

Future<bool> _checkPrerequisites() async {
  print('Checking project structure...');

  // Check for pubspec.yaml.
  final pubspec = File('pubspec.yaml');
  if (!await pubspec.exists()) {
    print('  Error: pubspec.yaml not found.');
    print('  Please run this command from your Flutter project root.');
    return false;
  }
  print('  Flutter project detected');

  // Check if solid_test is a dependency.
  final content = await pubspec.readAsString();
  if (!content.contains('solid_test')) {
    print('');
    print('  Warning: solid_test not found in pubspec.yaml');
    print('  Add it to your dev_dependencies:');
    print('');
    print('    dev_dependencies:');
    print('      solid_test:');
    print('        git:');
    print('          url: https://github.com/anusii/solid_test');
    print('          ref: main');
    print('');
    final cont = _prompt('Continue anyway? (y/n)', defaultValue: 'y');
    if (cont.toLowerCase() != 'y') {
      return false;
    }
  } else {
    print('  solid_test dependency found');
  }

  return true;
}

Future<void> _createFixturesDirectory() async {
  print('');
  print('Creating fixtures directory...');

  // Create directory.
  final dir = Directory(fixturesPath);
  if (!await dir.exists()) {
    await dir.create(recursive: true);
    print('  Created $fixturesPath/');
  } else {
    print('  $fixturesPath/ already exists');
  }

  // Create .gitignore.
  final gitignore = File(gitignoreFile);
  if (!await gitignore.exists()) {
    await gitignore.writeAsString('''# Ignore credential files - these contain secrets
test_credentials.json
complete_auth_data.json
''');
    print('  Created $gitignoreFile');
  } else {
    print('  $gitignoreFile already exists');
  }
}

Future<Map<String, String>> _promptCredentials() async {
  // POD Provider / Issuer.
  final issuer = _prompt(
    '  POD Provider',
    defaultValue: defaultIssuer,
  );

  // Email.
  String email;
  while (true) {
    email = _prompt('  Email');
    if (email.isEmpty) {
      print('    Email is required.');
      continue;
    }
    if (!email.contains('@')) {
      print('    Please enter a valid email address.');
      continue;
    }
    break;
  }

  // Password.
  final password = _promptPassword('  Password');
  if (password.isEmpty) {
    print('    Warning: Empty password entered.');
  }

  // Security Key.
  final securityKey = _promptPassword('  Security Key');

  // Derive pod name from email (part before @).
  final podName = email.split('@').first.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');

  // WebID.
  final defaultWebId = '$issuer/$podName/profile/card#me';
  final webId = _prompt('  WebID', defaultValue: defaultWebId);

  // POD URL (derived from WebID).
  final defaultPodUrl = webId.contains('/profile/')
      ? webId.substring(0, webId.indexOf('/profile/') + 1)
      : '$issuer/$podName/';
  final podUrl = _prompt('  POD URL', defaultValue: defaultPodUrl);

  return {
    'email': email,
    'password': password,
    'securityKey': securityKey,
    'webId': webId,
    'podUrl': podUrl,
    'issuer': issuer,
  };
}

Future<void> _writeCredentialsFile(Map<String, String> credentials) async {
  print('');
  print('Writing credentials file...');

  final file = File(credentialsFile);
  final json = const JsonEncoder.withIndent('  ').convert(credentials);
  await file.writeAsString(json);

  print('  Created $credentialsFile');
}

Future<void> _offerGenerateAuth() async {
  print('');
  final generate = _prompt(
    'Would you like to generate auth data now? (y/n)',
    defaultValue: 'y',
  );

  if (generate.toLowerCase() != 'y') {
    print('');
    print('You can generate auth data later with:');
    print('  dart run solid_test:generate_auth');
    return;
  }

  print('');
  print('Running browser automation...');
  print('(A browser window will open for POD login)');
  print('');

  // Run generate_auth.
  final result = await Process.run(
    'dart',
    ['run', 'solid_test:generate_auth'],
    runInShell: true,
  );

  stdout.write(result.stdout);
  stderr.write(result.stderr);

  if (result.exitCode != 0) {
    print('');
    print('Auth generation failed. You can retry with:');
    print('  dart run solid_test:generate_auth');
  }
}

void _printNextSteps() {
  print('');
  print('=== Setup Complete! ===');
  print('');
  print('Next steps:');
  print('');
  print('  1. Write your integration tests:');
  print('');
  print('     import \'package:solid_test/testing.dart\';');
  print('');
  print('     void main() {');
  print('       final config = PodConfig.solidCommunityAu();');
  print('       setUpAll(() => AuthTestSetup.setUp(config: config));');
  print('       tearDownAll(() => AuthTestSetup.tearDown());');
  print('');
  print('       testWidgets(\'my test\', (tester) async {');
  print('         // Your test code here');
  print('       });');
  print('     }');
  print('');
  print('  2. Run tests:');
  print('     flutter test integration_test/ -d linux');
  print('');
}

void _printHelp() {
  print('''
solid_test Setup Wizard

Creates integration test fixtures for POD authentication.

Usage:
  dart run solid_test:setup [options]

Options:
  --help, -h    Show this help message

What it does:
  1. Creates integration_test/fixtures/ directory
  2. Creates .gitignore for credential files
  3. Prompts for your POD credentials
  4. Writes test_credentials.json
  5. Optionally runs generate_auth to get OAuth tokens

After setup, you can run your integration tests with:
  flutter test integration_test/ -d linux
''');
}

/// Prompts the user for input with an optional default value.
String _prompt(String message, {String? defaultValue}) {
  if (defaultValue != null) {
    stdout.write('$message [$defaultValue]: ');
  } else {
    stdout.write('$message: ');
  }

  final input = stdin.readLineSync()?.trim() ?? '';
  return input.isEmpty && defaultValue != null ? defaultValue : input;
}

/// Prompts for password input with masked characters.
String _promptPassword(String message) {
  stdout.write('$message: ');

  // Try to disable echo for password input.
  try {
    stdin.echoMode = false;
    final password = stdin.readLineSync() ?? '';
    stdin.echoMode = true;
    print(''); // New line after masked input.
    return password;
  } catch (e) {
    // echoMode not supported (e.g., in some IDEs).
    // Fall back to visible input.
    return stdin.readLineSync() ?? '';
  }
}
