/// PKCE (Proof Key for Code Exchange) utilities.
///
/// Implements RFC 7636 for secure OAuth authorization code flow.
///
/// Copyright (C) 2025, Software Innovation Institute, ANU.
///
/// Licensed under the GNU General Public License, Version 3 (the "License").
///
/// License: https://opensource.org/license/gpl-3-0.

library;

import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

/// Generates a random code verifier for PKCE.
///
/// The code verifier is a high-entropy cryptographic random string
/// used to prove possession of the original authorization request.
///
/// Returns a base64url-encoded string without padding.
String generateCodeVerifier() {
  final random = Random.secure();
  final values = List<int>.generate(32, (i) => random.nextInt(256));
  return base64UrlEncode(values).replaceAll('=', '');
}

/// Generates a code challenge from the code verifier using SHA-256.
///
/// The code challenge is sent in the authorization request.
/// The code verifier is sent in the token request to prove possession.
///
/// Uses the S256 challenge method (SHA-256 hash, base64url-encoded).
String generateCodeChallenge(String verifier) {
  final bytes = utf8.encode(verifier);
  final digest = sha256.convert(bytes);
  return base64UrlEncode(digest.bytes).replaceAll('=', '');
}

/// PKCE pair containing verifier and challenge.
class PkcePair {
  /// The code verifier (kept secret, sent in token request).
  final String verifier;

  /// The code challenge (sent in authorization request).
  final String challenge;

  /// Creates a PKCE pair.
  const PkcePair({required this.verifier, required this.challenge});

  /// Generates a new PKCE pair.
  factory PkcePair.generate() {
    final verifier = generateCodeVerifier();
    final challenge = generateCodeChallenge(verifier);
    return PkcePair(verifier: verifier, challenge: challenge);
  }
}
