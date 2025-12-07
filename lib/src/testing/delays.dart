// Constant delays for integration testing.
//
// Copyright (C) 2025, Software Innovation Institute, ANU.
//
// Licensed under the GNU General Public License, Version 3 (the "Licence").
//
// Licence: https://opensource.org/license/gpl-3-0.

library;

/// Interactive delay duration controlled by INTERACT environment variable.
///
/// Use an [interact] duration to optionally allow the tester to view the testing
/// interactively. A 2s delay is good for a quicker interactive, 5s is good to
/// review each screen, 10s is useful for development. Set as 0s for no interact
/// as we do in the quick tests.
///
/// The interact should not be required for the test to succeed and is handy only
/// when running interactively. The INTERACT environment variable can be used to
/// override the default.
///
/// ```bash
/// flutter test --device-id linux --dart-define=INTERACT=0 integration_test/app_test.dart
/// ```
///
/// If a test works when [interact] is non-zero but fails when it is zero then you
/// probably need to use a delay or a hack rather than an [interact].
const String envINTERACT = String.fromEnvironment(
  'INTERACT',
  defaultValue: '0',
);

/// Interactive delay duration parsed from INTERACT environment variable.

final Duration interact = Duration(seconds: int.parse(envINTERACT));

/// Default delay duration (2 seconds).
///
/// Use this where a delay is always useful and 2 seconds is sufficient.

const Duration delay = Duration(seconds: 2);

/// Hack delay for operations that need more time (10 seconds).
///
/// Use when you need to wait for async operations that take longer.
/// By naming the delay as a "hack" we mark it as a delay that we want
/// to come back and fix eventually.

const Duration hack = Duration(seconds: 10);

/// Long hack delay for very slow operations (25 seconds).
///
/// Use sparingly and prefer multiple [hack] delays when possible.

const Duration longHack = Duration(seconds: 25);
