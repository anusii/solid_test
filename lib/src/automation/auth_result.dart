// Result of POD authentication automation.
//
// Copyright (C) 2025, Software Innovation Institute, ANU.
//
// Licensed under the GNU General Public License, Version 3 (the "Licence").
//
// Licence: https://opensource.org/license/gpl-3-0.

library;

/// Result of POD authentication automation.

class AuthResult {
  /// Whether authentication was successful.

  final bool success;

  /// OAuth tokens (access_token, refresh_token, id_token, etc.)

  final Map<String, dynamic>? tokens;

  /// Complete auth data structure for solidpod's AuthDataManager.

  final Map<String, dynamic>? completeAuthData;

  /// Error message if authentication failed.

  final String? error;

  /// Creates an auth result.

  AuthResult({
    required this.success,
    this.tokens,
    this.completeAuthData,
    this.error,
  });
}
