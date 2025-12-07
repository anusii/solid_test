// CLI-safe exports for solid_test - no Flutter dependencies.
//
// Use this in CLI tools like generate_auth that need to run
// without the Flutter framework.
//
// Copyright (C) 2025, Software Innovation Institute, ANU.
//
// Licensed under the GNU General Public License, Version 3 (the "Licence").
//
// Licence: https://opensource.org/license/gpl-3-0.

library;

// Configuration (no Flutter dependencies)

export 'src/config/pod_config.dart';
export 'src/config/test_credentials.dart';

// OAuth helpers (no Flutter dependencies)

export 'src/oauth/pkce.dart';
export 'src/oauth/dpop.dart';
export 'src/oauth/oauth_client.dart';
export 'src/oauth/token_exchange.dart';

// Browser automation (no Flutter dependencies)

export 'src/automation/auth_result.dart';
export 'src/automation/pod_auth_automator.dart';
export 'src/automation/browser_helpers.dart';

// Auth data builder (no Flutter dependencies)

export 'src/storage/auth_data_builder.dart';
