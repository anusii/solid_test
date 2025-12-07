// OAuth token exchange utilities.
//
// Copyright (C) 2025, Software Innovation Institute, ANU.
//
// Licensed under the GNU General Public License, Version 3 (the "Licence").
//
// Licence: https://opensource.org/license/gpl-3-0.

// ignore_for_file: avoid_print

library;

import 'dart:convert';

import 'package:puppeteer/puppeteer.dart';
import 'package:solid_test/src/config/pod_config.dart';

/// Exchanges authorization code for OAuth tokens.
///
/// Returns a map with success status and tokens/error.

Future<Map<String, dynamic>> exchangeCodeForTokens(
  Page page,
  PodConfig config, {
  required String authorizationCode,
  required String clientId,
  required String codeVerifier,
}) async {
  try {
    // Prepare token request body.

    final tokenRequest = {
      'grant_type': 'authorization_code',
      'code': authorizationCode,
      'client_id': clientId,
      'code_verifier': codeVerifier,
      'redirect_uri': config.redirectUriString,
    };

    // Use fetch API to exchange code for tokens.

    final result = await page.evaluate(
      '''
        async (endpoint, data) => {
          try {
            // Convert data to URL-encoded form
            const formBody = Object.keys(data)
              .map(key => encodeURIComponent(key) + '=' + encodeURIComponent(data[key]))
              .join('&');

            const response = await fetch(endpoint, {
              method: 'POST',
              headers: {
                'Content-Type': 'application/x-www-form-urlencoded',
              },
              body: formBody,
            });

            if (!response.ok) {
              const errorText = await response.text();
              return {
                success: false,
                error: 'HTTP ' + response.status + ': ' + errorText
              };
            }

            const json = await response.json();
            return { success: true, tokens: json };
          } catch (err) {
            return { success: false, error: err.toString() };
          }
        }
      ''',
      args: [config.tokenEndpoint, tokenRequest],
    );

    if (result is Map && result['success'] == true) {
      return {
        'success': true,
        'tokens': result['tokens'] as Map,
      };
    } else {
      return {
        'success': false,
        'error': result['error']?.toString() ?? 'Unknown error',
      };
    }
  } catch (e) {
    print('Error exchanging code for tokens: $e');
    return {
      'success': false,
      'error': e.toString(),
    };
  }
}

/// Extracts WebID from ID token JWT.
///
/// ID tokens are JWTs with 3 parts: header.payload.signature
/// The payload contains the webid claim (or sub claim as fallback).

String? extractWebIdFromIdToken(String idToken) {
  try {
    // Split JWT into parts.

    final parts = idToken.split('.');
    if (parts.length != 3) {
      print('Invalid ID token format');
      return null;
    }

    // Decode payload (base64url).

    final payload = parts[1];

    // Add padding if needed for base64 decoding.

    var normalized = payload.replaceAll('-', '+').replaceAll('_', '/');
    while (normalized.length % 4 != 0) {
      normalized += '=';
    }

    // Decode base64.

    final decoded = utf8.decode(base64.decode(normalized));
    final json = jsonDecode(decoded) as Map<String, dynamic>;

    // Extract webid claim (or sub as fallback).
    
    final webId = json['webid'] as String? ?? json['sub'] as String?;
    return webId;
  } catch (e) {
    print('Error extracting WebID from ID token: $e');
    return null;
  }
}
