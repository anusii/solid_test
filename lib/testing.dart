/// Testing-focused exports for Solid POD integration tests.
///
/// Import this file in your integration tests:
/// ```dart
/// import 'package:solid_test/testing.dart';
/// ```
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

// Storage (for credential injection)
export 'src/storage/credential_injector.dart';

// Testing utilities
export 'src/testing/auth_test_setup.dart';
export 'src/testing/widget_helpers.dart';
export 'src/testing/delays.dart';
