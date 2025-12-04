/// OAuth client registration for Solid POD providers.
///
/// Copyright (C) 2025, Software Innovation Institute, ANU.
///
/// Licensed under the GNU General Public License, Version 3 (the "License").
///
/// License: https://opensource.org/license/gpl-3-0.

// ignore_for_file: avoid_print

library;

import 'package:puppeteer/puppeteer.dart';

import '../config/pod_config.dart';

/// Registers an OAuth client dynamically with the Solid POD server.
///
/// Uses dynamic client registration (RFC 7591) to register a public OAuth
/// client with the POD provider.
///
/// Returns the client_id if successful, null otherwise.
Future<String?> registerOAuthClient(Page page, PodConfig config) async {
  try {
    // Prepare registration request.
    final registrationData = {
      'client_name': config.clientName,
      'redirect_uris': [config.redirectUriString],
      'response_types': ['code'], // Authorization code flow only
      'grant_types': ['authorization_code'],
      'scope': config.scopeString,
      'application_type': 'web',
      'token_endpoint_auth_method': 'none', // Public client (no client secret)
    };

    // Use fetch API to register client.
    final result = await page.evaluate(
      '''
        async (endpoint, data) => {
          try {
            const response = await fetch(endpoint, {
              method: 'POST',
              headers: {
                'Content-Type': 'application/json',
              },
              body: JSON.stringify(data),
            });

            if (!response.ok) {
              return { success: false, error: await response.text() };
            }

            const json = await response.json();
            return { success: true, data: json };
          } catch (err) {
            return { success: false, error: err.toString() };
          }
        }
      ''',
      args: [config.registrationEndpoint, registrationData],
    );

    if (result is Map && result['success'] == true) {
      final data = result['data'] as Map;
      return data['client_id']?.toString();
    } else {
      print('Client registration failed: ${result['error']}');
      return null;
    }
  } catch (e) {
    print('Error registering OAuth client: $e');
    return null;
  }
}

/// Builds the OAuth authorization URL with proper parameters including PKCE.
String buildAuthorizationUrl(
  PodConfig config, {
  required String clientId,
  required String codeChallenge,
}) {
  // Generate a random state for CSRF protection.
  final state = DateTime.now().millisecondsSinceEpoch.toString();

  // Build the URL with proper encoding including PKCE parameters.
  final params = {
    'response_type': 'code',
    'client_id': clientId,
    'redirect_uri': config.redirectUriString,
    'scope': config.scopeString,
    'state': state,
    'code_challenge': codeChallenge,
    'code_challenge_method': 'S256', // SHA-256
    'prompt': 'consent', // Force consent screen
  };

  final queryString = params.entries
      .map(
        (e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}',
      )
      .join('&');

  return '${config.authEndpoint}?$queryString';
}
