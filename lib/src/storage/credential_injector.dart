/// Credential injection for E2E testing with Solid POD authentication.
///
/// This allows E2E tests to run authenticated without manual login.
///
/// Copyright (C) 2025, Software Innovation Institute, ANU.
///
/// Licensed under the GNU General Public License, Version 3 (the "License").
///
/// License: https://opensource.org/license/gpl-3-0.

// ignore_for_file: avoid_print

library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../automation/pod_auth_automator.dart';
import '../config/pod_config.dart';
import '../config/test_credentials.dart';

/// Storage key used by solidpod package to store complete auth data.
const authDataSecureStorageKey = '_solid_auth_data';

/// Injects test credentials for authenticated E2E testing.
class CredentialInjector {
  /// Injects complete auth data directly into secure storage.
  ///
  /// This method injects the COMPLETE auth data structure that was extracted
  /// from a real login session. This includes:
  /// - RSA keypair for DPoP token generation
  /// - Complete Credential object
  /// - Client metadata
  /// - Logout URL
  ///
  /// This is stored under the '_solid_auth_data' key that solidpod's
  /// AuthDataManager expects.
  static Future<void> injectCompleteAuthData(
    Map<String, dynamic> authData,
  ) async {
    final storage = _createSecureStorage();

    print('Injecting complete auth data into secure storage...');

    // The auth data is already in the correct format from extraction.
    // We just need to serialize it and store it under the correct key.
    final authDataJson = jsonEncode(authData);

    await storage.write(
      key: authDataSecureStorageKey,
      value: authDataJson,
    );

    print('  Stored complete auth data under $authDataSecureStorageKey');
    print('  WebID: ${authData['web_id']}');
    print('  Contains RSA keys: ${authData.containsKey('rsa_info')}');
    print(
      '  Contains auth response: ${authData.containsKey('auth_response')}',
    );

    print('Complete auth data injected successfully');
  }

  /// Full authentication injection using complete auth data.
  ///
  /// This is the recommended approach for E2E testing with real POD auth.
  /// It injects the complete auth data structure including RSA keys for DPoP.
  ///
  /// If [autoRegenerateOnFailure] is true, will automatically regenerate tokens
  /// if they are expired or if the auth data file is missing.
  static Future<void> injectFullAuth({
    PodConfig? config,
    bool autoRegenerateOnFailure = false,
  }) async {
    final podConfig = config ?? PodConfig.solidCommunityAu();
    print('Loading complete auth data...');

    Map<String, dynamic>? authData;
    bool needsRegeneration = false;

    try {
      // Try loading complete auth data first.
      authData = await loadCompleteAuthData(podConfig.authDataPath);
      print('Complete auth data loaded');

      // Check if tokens are expired.
      if (_isTokenExpired(authData)) {
        print('Auth tokens have expired');
        if (autoRegenerateOnFailure) {
          needsRegeneration = true;
        } else {
          throw Exception(
            'Auth tokens expired. Run: dart run solid_test:generate_auth',
          );
        }
      }
    } catch (e) {
      print('Complete auth data not found or invalid: $e');

      if (autoRegenerateOnFailure) {
        needsRegeneration = true;
      } else {
        rethrow;
      }
    }

    // Regenerate tokens if needed.
    if (needsRegeneration) {
      print('Auto-regenerating tokens with browser automation...');
      await _regenerateTokens(podConfig);

      // Load the freshly generated auth data.
      authData = await loadCompleteAuthData(podConfig.authDataPath);
      print('Complete auth data auto-regenerated and loaded');
    }

    // Inject the complete auth data structure.
    if (authData != null) {
      await injectCompleteAuthData(authData);
      print('Full authentication injected successfully');
    } else {
      throw Exception('Auth data is null after loading');
    }
  }

  /// Loads complete auth data from file.
  static Future<Map<String, dynamic>> loadCompleteAuthData(String path) async {
    final file = File(path);
    if (!await file.exists()) {
      throw Exception(
        'Complete auth data file not found: $path\n'
        'Run: dart run solid_test:generate_auth',
      );
    }

    final contents = await file.readAsString();
    return jsonDecode(contents) as Map<String, dynamic>;
  }

  /// Checks if the auth token is expired.
  ///
  /// Returns true if the token has expired or will expire within the next minute.
  static bool _isTokenExpired(Map<String, dynamic> authData) {
    try {
      final authResponse = authData['auth_response'] as Map<String, dynamic>?;
      if (authResponse == null) {
        print('  No auth_response found in auth data');
        return true;
      }

      DateTime? expiryTime;

      // Try CORRECT format: auth_response.token.expires_at
      final token = authResponse['token'] as Map<String, dynamic>?;
      if (token != null) {
        final expiresAt = token['expires_at'] as int?;
        if (expiresAt != null) {
          expiryTime = DateTime.fromMillisecondsSinceEpoch(expiresAt * 1000);
        }
      }

      // Fallback for old broken format: auth_response.response.expires_in
      if (expiryTime == null) {
        final response = authResponse['response'] as Map<String, dynamic>?;
        if (response != null) {
          final expiresAt = response['expires_at'] as int?;
          if (expiresAt != null) {
            expiryTime = DateTime.fromMillisecondsSinceEpoch(expiresAt * 1000);
          } else {
            final expiresIn = response['expires_in'] as int?;
            if (expiresIn != null) {
              expiryTime = DateTime.now().add(Duration(seconds: expiresIn));
              print(
                '  Using expires_in ($expiresIn seconds) to estimate expiry',
              );
            }
          }
        }
      }

      if (expiryTime == null) {
        print('  No expiry info found in token');
        return true;
      }

      // Check if token is expired or expires within the next minute.
      final now = DateTime.now();
      final bufferTime = now.add(const Duration(minutes: 1));

      if (expiryTime.isBefore(bufferTime)) {
        print('  Token expired at: ${expiryTime.toIso8601String()}');
        print('  Current time: ${now.toIso8601String()}');
        return true;
      }

      print('  Token valid until: ${expiryTime.toIso8601String()}');
      return false;
    } catch (e) {
      print('  Error checking token expiry: $e');
      return true;
    }
  }

  /// Automatically regenerates auth data using browser automation.
  static Future<void> _regenerateTokens(PodConfig config) async {
    print('Regenerating auth data using browser automation...');

    // Load test credentials.
    final credentials = await TestCredentials.load(config.credentialsPath);

    // Perform automated browser login.
    print('  Authenticating with POD provider...');
    final result = await PodAuthAutomator.authenticate(
      credentials: credentials,
      config: config,
      headless: true,
    );

    if (!result.success || result.completeAuthData == null) {
      throw Exception(
        'Failed to regenerate auth data: ${result.error}',
      );
    }

    // Save complete auth data to file.
    print('  Saving complete auth data to ${config.authDataPath}...');
    final completeAuthFile = File(config.authDataPath);
    await completeAuthFile.parent.create(recursive: true);
    await completeAuthFile.writeAsString(
      const JsonEncoder.withIndent('  ').convert(result.completeAuthData),
    );

    print('Complete auth data regenerated and saved successfully');
  }

  /// Clears injected credentials (for test cleanup).
  static Future<void> clearCredentials() async {
    final storage = _createSecureStorage();

    // Clear complete auth data (solidpod package's storage key).
    await storage.delete(key: authDataSecureStorageKey);

    // Clear OAuth tokens (legacy).
    await storage.delete(key: 'webId');
    await storage.delete(key: 'accessToken');
    await storage.delete(key: 'idToken');
    await storage.delete(key: 'refreshToken');
    await storage.delete(key: 'tokenType');
    await storage.delete(key: 'expiresAt');
    await storage.delete(key: 'clientId');

    // Clear basic credentials.
    await storage.delete(key: 'podUrl');
    await storage.delete(key: 'issuer');

    // Clear OpenID Connect auth response.
    await storage.delete(key: 'openidconnect_auth_response_info');

    // Clear cookies.
    await storage.delete(key: 'cookies');

    print('Cleared all injected credentials and tokens');
  }

  /// Verifies that credentials are properly injected.
  static Future<bool> verifyInjection() async {
    try {
      final storage = _createSecureStorage();
      final authDataJson = await storage.read(key: authDataSecureStorageKey);

      if (authDataJson == null || authDataJson.isEmpty) {
        return false;
      }

      final authData = jsonDecode(authDataJson) as Map<String, dynamic>;
      final webId = authData['web_id'] as String?;

      return webId != null && webId.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Creates a FlutterSecureStorage instance with platform-specific options.
  static FlutterSecureStorage _createSecureStorage() {
    return const FlutterSecureStorage(
      aOptions: AndroidOptions(
        encryptedSharedPreferences: true,
      ),
      iOptions: IOSOptions(
        accessibility: KeychainAccessibility.first_unlock,
      ),
      mOptions: MacOsOptions(
        synchronizable: false,
      ),
      lOptions: LinuxOptions(),
      wOptions: WindowsOptions(),
    );
  }
}
