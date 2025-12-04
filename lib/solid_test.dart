/// Generic integration test utilities for Solid POD Flutter applications.
///
/// This package provides OAuth automation, credential injection, and widget
/// test helpers for testing apps that use Solid POD authentication.
///
/// Copyright (C) 2025, Software Innovation Institute, ANU.
///
/// Licensed under the GNU General Public License, Version 3 (the "License").
///
/// License: https://opensource.org/license/gpl-3-0.

library;

// Configuration
export 'src/config/pod_config.dart';
export 'src/config/test_credentials.dart';

// OAuth helpers
export 'src/oauth/pkce.dart';
export 'src/oauth/dpop.dart';
export 'src/oauth/oauth_client.dart';
export 'src/oauth/token_exchange.dart';

// Browser automation
export 'src/automation/pod_auth_automator.dart';
export 'src/automation/browser_helpers.dart';

// Storage
export 'src/storage/credential_injector.dart';
export 'src/storage/auth_data_builder.dart';

// Testing utilities
export 'src/testing/auth_test_setup.dart';
export 'src/testing/widget_helpers.dart';
export 'src/testing/delays.dart';
