/// Test credentials model for POD authentication.
///
/// Copyright (C) 2025, Software Innovation Institute, ANU.
///
/// Licensed under the GNU General Public License, Version 3 (the "License").
///
/// License: https://opensource.org/license/gpl-3-0.

library;

import 'dart:convert';
import 'dart:io';

/// Credentials for POD login used in E2E tests.
///
/// Load from a JSON file:
/// ```dart
/// final credentials = await TestCredentials.load(
///   'integration_test/fixtures/test_credentials.json',
/// );
/// ```
///
/// JSON format:
/// ```json
/// {
///   "email": "test@example.com",
///   "password": "your-password",
///   "securityKey": "your-security-key",
///   "webId": "https://pods.dev.solidcommunity.au/test/profile/card#me",
///   "podUrl": "https://pods.dev.solidcommunity.au/test/",
///   "issuer": "https://pods.dev.solidcommunity.au"
/// }
/// ```
class TestCredentials {
  /// Email address for login.
  final String email;

  /// Password for login.
  final String password;

  /// Security key (encryption key) for POD.
  final String securityKey;

  /// WebID of the test user.
  final String webId;

  /// Base URL of the user's POD.
  final String podUrl;

  /// Issuer URL of the POD provider.
  final String issuer;

  /// Creates test credentials.
  const TestCredentials({
    required this.email,
    required this.password,
    required this.securityKey,
    required this.webId,
    required this.podUrl,
    required this.issuer,
  });

  /// Creates test credentials from JSON.
  factory TestCredentials.fromJson(Map<String, dynamic> json) {
    return TestCredentials(
      email: json['email'] as String,
      password: json['password'] as String,
      securityKey: json['securityKey'] as String,
      webId: json['webId'] as String,
      podUrl: json['podUrl'] as String,
      issuer: json['issuer'] as String,
    );
  }

  /// Loads test credentials from a JSON file.
  ///
  /// Throws [Exception] if the file cannot be loaded or parsed.
  static Future<TestCredentials> load(String path) async {
    final file = File(path);
    if (!await file.exists()) {
      throw Exception(
        'Test credentials file not found: $path\n'
        'Create this file with your POD login credentials.\n'
        'See the package README for the expected format.',
      );
    }

    try {
      final contents = await file.readAsString();
      final json = jsonDecode(contents) as Map<String, dynamic>;
      return TestCredentials.fromJson(json);
    } catch (e) {
      throw Exception('Failed to parse test credentials from $path: $e');
    }
  }

  /// Converts to JSON map.
  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'password': password,
      'securityKey': securityKey,
      'webId': webId,
      'podUrl': podUrl,
      'issuer': issuer,
    };
  }
}
