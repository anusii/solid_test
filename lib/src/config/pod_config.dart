/// Configuration for Solid POD providers.
///
/// Copyright (C) 2025, Software Innovation Institute, ANU.
///
/// Licensed under the GNU General Public License, Version 3 (the "License").
///
/// License: https://opensource.org/license/gpl-3-0.

library;

/// Configuration for a Solid POD provider.
///
/// Use the factory constructors for common providers:
/// ```dart
/// final config = PodConfig.solidCommunityAu();
/// ```
///
/// Or create a custom configuration:
/// ```dart
/// final config = PodConfig(
///   issuerUrl: 'https://my-pod-server.example.com',
///   redirectPort: 44007,
///   clientName: 'My App E2E Tests',
/// );
/// ```
class PodConfig {
  /// Base URL of the POD provider.
  ///
  /// Example: 'https://pods.dev.solidcommunity.au'
  final String issuerUrl;

  /// Port for OAuth redirect URI.
  ///
  /// The redirect URI will be: http://localhost:{redirectPort}/
  final int redirectPort;

  /// OAuth client name shown in consent screen.
  final String clientName;

  /// OAuth scopes to request.
  final List<String> scopes;

  /// Timeout for page loads and element waits.
  final Duration timeout;

  /// Path to test credentials JSON file.
  final String credentialsPath;

  /// Path to complete auth data JSON file.
  final String authDataPath;

  /// Creates a POD configuration.
  const PodConfig({
    required this.issuerUrl,
    this.redirectPort = 44007,
    this.clientName = 'Flutter E2E Test Client',
    this.scopes = const ['openid', 'profile'],
    this.timeout = const Duration(seconds: 30),
    this.credentialsPath = 'integration_test/fixtures/test_credentials.json',
    this.authDataPath = 'integration_test/fixtures/complete_auth_data.json',
  });

  /// Creates configuration for solidcommunity.au (development server).
  ///
  /// This is the default POD provider for ANU-SII apps.
  factory PodConfig.solidCommunityAu({
    int redirectPort = 44007,
    String clientName = 'Flutter E2E Test Client',
    List<String> scopes = const ['openid', 'profile'],
    Duration timeout = const Duration(seconds: 30),
    String credentialsPath = 'integration_test/fixtures/test_credentials.json',
    String authDataPath = 'integration_test/fixtures/complete_auth_data.json',
  }) {
    return PodConfig(
      issuerUrl: 'https://pods.dev.solidcommunity.au',
      redirectPort: redirectPort,
      clientName: clientName,
      scopes: scopes,
      timeout: timeout,
      credentialsPath: credentialsPath,
      authDataPath: authDataPath,
    );
  }

  /// Gets the OAuth redirect URI.
  Uri get redirectUri => Uri.parse('http://localhost:$redirectPort/');

  /// Gets the OAuth redirect URI as a string.
  String get redirectUriString => 'http://localhost:$redirectPort/';

  /// Gets the OAuth authorization endpoint.
  String get authEndpoint => '$issuerUrl/.oidc/auth';

  /// Gets the OAuth token endpoint.
  String get tokenEndpoint => '$issuerUrl/.oidc/token';

  /// Gets the OAuth registration endpoint.
  String get registrationEndpoint => '$issuerUrl/.oidc/reg';

  /// Gets the logout URL.
  String get logoutUrl => '$issuerUrl/logout';

  /// Gets the scope string.
  String get scopeString => scopes.join(' ');
}
