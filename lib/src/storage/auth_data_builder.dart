// Auth data builder for solidpod's AuthDataManager format.
//
// Copyright (C) 2025, Software Innovation Institute, ANU.
//
// Licensed under the GNU General Public License, Version 3 (the "Licence").
//
// Licence: https://opensource.org/license/gpl-3-0.

// ignore_for_file: avoid_print

library;

import 'dart:convert';

import 'package:pointycastle/export.dart';
import 'package:solid_test/src/oauth/dpop.dart';

/// Builds a Credential-compatible JSON structure from OAuth tokens.
///
/// This creates the EXACT structure that solidpod's AuthDataManager expects.
/// Format must match what manual extraction creates.

Future<Map<String, dynamic>> buildCredentialJson({
  required Map<String, dynamic> oauthTokens,
  required String clientId,
  required String issuerUrl,
}) async {
  print('Building Credential JSON structure...');

  // Calculate expires_at timestamp (Unix timestamp in seconds)

  final expiresIn = (oauthTokens['expires_in'] as int?) ?? 3600;
  final now = DateTime.now();
  final expiresAt = now.add(Duration(seconds: expiresIn));
  final expiresAtUnix = (expiresAt.millisecondsSinceEpoch / 1000).round();

  // Fetch issuer metadata from well-known endpoint

  print('  Fetching issuer metadata...');
  final issuerMetadata = _buildIssuerMetadata(issuerUrl);

  // Build the credential JSON in the format solidpod expects

  final credentialJson = {
    'issuer': issuerMetadata,
    'client_id': clientId,
    'client_secret': null, // Public client (no client secret)
    'token': {
      'expires_at': expiresAtUnix,
      'access_token': oauthTokens['access_token'],
      'expires_in': expiresIn,
      'id_token': oauthTokens['id_token'],
      'refresh_token': oauthTokens['refresh_token'],
      'scope': oauthTokens['scope'] ?? '',
      'token_type': oauthTokens['token_type'] ?? 'DPoP',
    },
    'nonce': null,
  };

  print('  Credential JSON built');
  print(
    '  Token expires at: ${expiresAt.toIso8601String()} (Unix: $expiresAtUnix)',
  );

  return credentialJson;
}

/// Builds issuer metadata structure.
///
/// This should ideally be fetched from ${issuerUrl}/.well-known/openid-configuration
/// but for now returns a static structure that matches the format.

Map<String, dynamic> _buildIssuerMetadata(String issuerUrl) {
  return {
    'authorization_endpoint': '$issuerUrl/.oidc/auth',
    'claims_parameter_supported': true,
    'claims_supported': ['azp', 'sub', 'webid', 'sid', 'auth_time', 'iss'],
    'code_challenge_methods_supported': ['S256'],
    'end_session_endpoint': '$issuerUrl/.oidc/session/end',
    'grant_types_supported': [
      'implicit',
      'authorization_code',
      'refresh_token',
      'client_credentials',
    ],
    'issuer': issuerUrl,
    'jwks_uri': '$issuerUrl/.oidc/jwks',
    'registration_endpoint': '$issuerUrl/.oidc/reg',
    'authorization_response_iss_parameter_supported': true,
    'response_modes_supported': ['form_post', 'fragment', 'query'],
    'response_types_supported': ['code id_token', 'code', 'id_token', 'none'],
    'scopes_supported': ['openid', 'profile', 'offline_access', 'webid'],
    'subject_types_supported': ['public'],
    'token_endpoint_auth_methods_supported': [
      'client_secret_basic',
      'client_secret_jwt',
      'client_secret_post',
      'private_key_jwt',
      'none',
    ],
    'token_endpoint_auth_signing_alg_values_supported': [
      'HS256',
      'RS256',
      'PS256',
      'ES256',
      'EdDSA',
    ],
    'token_endpoint': '$issuerUrl/.oidc/token',
    'id_token_signing_alg_values_supported': ['ES256'],
    'pushed_authorization_request_endpoint': '$issuerUrl/.oidc/request',
    'request_parameter_supported': false,
    'request_uri_parameter_supported': false,
    'introspection_endpoint': '$issuerUrl/.oidc/token/introspection',
    'dpop_signing_alg_values_supported': [
      'RS256',
      'RS384',
      'RS512',
      'PS256',
      'PS384',
      'PS512',
      'ES256',
      'ES256K',
      'ES384',
      'ES512',
      'EdDSA',
    ],
    'revocation_endpoint': '$issuerUrl/.oidc/token/revocation',
    'claim_types_supported': ['normal'],
  };
}

/// Builds the complete auth data structure for AuthDataManager.
///
/// This creates the exact format that AuthDataManager stores in secure storage
/// under the '_solid_auth_data' key.

Map<String, dynamic> buildCompleteAuthData({
  required String webId,
  required String logoutUrl,
  required Map<String, dynamic> rsaInfo,
  required Map<String, dynamic> credentialJson,
}) {
  print('Building complete auth data structure...');

  // AuthDataManager expects this format:
  // {
  //   'web_id': String,
  //   'logout_url': String,
  //   'rsa_info': jsonEncode({...}),
  //   'auth_response': Credential.toJson(),
  // }

  // Extract RSA keypair and serialize it.
  
  final keyPair = rsaInfo['rsa'] as AsymmetricKeyPair;
  final publicKey = keyPair.publicKey as RSAPublicKey;
  final privateKey = keyPair.privateKey as RSAPrivateKey;

  final completeAuthData = {
    'web_id': webId,
    'logout_url': logoutUrl,
    'rsa_info': jsonEncode({
      ...rsaInfo,
      // Override 'rsa' with serialized format compatible with fast_rsa.
      'rsa': {
        'public_key': serializePublicKey(publicKey),
        'private_key': serializePrivateKey(privateKey),
      },
    }),
    'auth_response': credentialJson,
  };

  print('  Complete auth data structure built');
  print('  - WebID: $webId');
  print('  - Logout URL: $logoutUrl');
  print('  - RSA keys: included');
  print('  - Auth response: included');

  return completeAuthData;
}
