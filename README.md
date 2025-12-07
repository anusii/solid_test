# solid_test

Generic integration test utilities for Solid POD Flutter applications.

This package provides OAuth automation, credential injection, and widget test helpers for testing apps that use Solid POD authentication.

> **Security Notice**: Only use **dedicated test accounts** with this package. Never use production credentials or accounts containing sensitive data. Test credentials are stored locally and transmitted during automated browser login.

## Features

- **Automated POD authentication** - Puppeteer-based OAuth flow automation
- **PKCE + DPoP support** - Secure OAuth with Proof Key for Code Exchange and Demonstrating Proof of Possession
- **Credential injection** - Inject auth tokens directly into `flutter_secure_storage`
- **Widget test helpers** - Common UI interaction utilities for integration tests
- **CLI tool** - Generate auth data from the command line

## Quick Start

### 1. Add the dependency

```yaml
dev_dependencies:
  solid_test:
    git:
      url: https://github.com/anusii/solid_test
      ref: main
```

### 2. Run the setup wizard

```bash
dart run solid_test:setup
```

This interactive wizard will:
1. Create `integration_test/fixtures/` directory
2. Create `.gitignore` for credential files
3. Prompt for your POD **test** credentials
4. Write `test_credentials.json`
5. Optionally run browser automation to generate auth tokens

### 3. Write your tests

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:solid_test/testing.dart';

import 'package:your_app/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  final config = PodConfig.solidCommunityAu();

  group('Authenticated Tests', () {
    setUpAll(() async {
      await AuthTestSetup.setUp(config: config);
    });

    tearDownAll(() async {
      await AuthTestSetup.tearDown();
    });

    testWidgets('app loads with authenticated state', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Your assertions here
      expect(find.text('Welcome'), findsOneWidget);
    });
  });
}
```

### 4. Run your tests

```bash
flutter test integration_test/ -d linux
```

## Manual Setup (Alternative)

If you prefer to set up manually instead of using the wizard:

<details>
<summary>Click to expand manual setup steps</summary>

1. Create fixtures directory:
   ```bash
   mkdir -p integration_test/fixtures
   ```

2. Create `integration_test/fixtures/test_credentials.json`:
   ```json
   {
     "email": "your-email@example.com",
     "password": "your-password",
     "securityKey": "your-security-key",
     "webId": "https://pods.dev.solidcommunity.au/your-pod/profile/card#me",
     "podUrl": "https://pods.dev.solidcommunity.au/your-pod/",
     "issuer": "https://pods.dev.solidcommunity.au"
   }
   ```

3. Create `integration_test/fixtures/.gitignore`:
   ```
   test_credentials.json
   complete_auth_data.json
   ```

4. Generate auth data:
   ```bash
   dart run solid_test:generate_auth
   ```

</details>

## Configuration

### PodConfig

```dart
// Use the pre-configured factory for solidcommunity.au
final config = PodConfig.solidCommunityAu();

// Or customize
final config = PodConfig.solidCommunityAu(
  redirectPort: 44008,  // Different port
  clientName: 'My App E2E Tests',
);

// Or fully custom
final config = PodConfig(
  issuerUrl: 'https://my-pod-server.example.com',
  redirectPort: 44007,
  clientName: 'My App E2E Tests',
  scopes: ['openid', 'profile'],
);
```

### Environment Variables

```bash
# Disable auto-regeneration for batch tests
flutter test integration_test/ --dart-define=AUTO_REGENERATE=false

# Set interactive delay for debugging
flutter test integration_test/ --dart-define=INTERACT=5
```

## CLI Tool

Generate auth data from the command line:

```bash
# Interactive mode (watch the browser)
dart run solid_test:generate_auth

# Headless mode (for CI/CD)
dart run solid_test:generate_auth --headless

# Custom paths
dart run solid_test:generate_auth \
  --credentials=my_creds.json \
  --output=my_auth.json

# Different POD server
dart run solid_test:generate_auth \
  --issuer=https://pods.prod.solidcommunity.au \
  --port=44008
```

## Widget Test Helpers

The package includes extension methods on `WidgetTester`:

```dart
import 'package:solid_test/testing.dart';

testWidgets('example', (tester) async {
  // Tap an icon if it exists
  await tester.tapIconIfExists(Icons.menu);

  // Enter text in a TextField
  await tester.enterTextInField('search query');

  // Tap by text label
  await tester.tapByText('Submit');

  // Wait for a widget to appear
  final found = await tester.waitForWidget(
    find.text('Success'),
    timeout: const Duration(seconds: 10),
  );

  // Dismiss a dialog
  await tester.dismissDialogByText('Cancel');
});
```

## Delay Constants

```dart
import 'package:solid_test/testing.dart';

// Interactive delay (controlled by INTERACT env var)
await tester.pumpAndSettle(interact);

// Default delay (2 seconds)
await tester.pumpAndSettle(delay);

// Hack delay for slow operations (10 seconds)
await tester.pumpAndSettle(hack);
```

## Prerequisites

- **Chrome/Chromium browser** - Required for Puppeteer
  - Windows: Chrome auto-detected
  - macOS: Chrome at `/Applications/Google Chrome.app`
  - Linux: `chromium-browser` or `google-chrome` in PATH

- **libsecret (Linux only)** - For secure storage
  ```bash
  sudo apt-get install libsecret-1-dev
  ```

## Documentation

See the [docs/](docs/) folder for detailed guides:

- [Concepts](docs/concepts.md) - OAuth, DPoP, PKCE basics
- [Testing Patterns](docs/testing-patterns.md) - Writing tests with solid_test
- [Troubleshooting](docs/troubleshooting.md) - Common errors and fixes
- [CI/CD](docs/ci-cd.md) - Continuous integration setup

## License

GNU General Public License, Version 3 (GPL-3.0)

Copyright (C) 2025, Software Innovation Institute, ANU.
