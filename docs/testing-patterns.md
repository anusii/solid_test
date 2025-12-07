# Testing Patterns

## Basic Test Setup

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:solid_test/testing.dart';

import 'package:your_app/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  final config = PodConfig.solidCommunityAu();

  setUpAll(() async {
    await AuthTestSetup.setUp(config: config);
  });

  tearDownAll(() async {
    await AuthTestSetup.tearDown();
  });

  testWidgets('app loads authenticated', (tester) async {
    app.main();
    await tester.pumpAndSettle(delay);

    expect(find.text('Welcome'), findsOneWidget);
  });
}
```

## Delay Constants

```dart
import 'package:solid_test/testing.dart';

// interact - Visual delay for debugging (controlled by INTERACT env var)
await tester.pumpAndSettle(interact);

// delay - Standard wait (2 seconds) for network/animations
await tester.pumpAndSettle(delay);

// hack - Long wait (10 seconds) for workarounds, mark with TODO
await tester.pumpAndSettle(hack);  // TODO: Fix async issue
```

Run with visual delays:
```bash
flutter test integration_test/app_test.dart -d linux --dart-define=INTERACT=5
```

## Widget Helpers

```dart
// Tap by text
await tester.tapByText('Submit');

// Tap icon if exists
await tester.tapIconIfExists(Icons.menu);

// Enter text in TextField
await tester.enterTextInField('search query');

// Wait for widget to appear
final found = await tester.waitForWidget(
  find.text('Success'),
  timeout: Duration(seconds: 10),
);

// Dismiss dialog
await tester.dismissDialogByText('Cancel');
```

## Test Organization

```
integration_test/
├── fixtures/
│   ├── test_credentials.json      # Login credentials
│   └── complete_auth_data.json    # Generated tokens (git-ignored)
├── app_test.dart                  # Main app tests
└── workflows/
    ├── login_test.dart            # Login flow tests
    └── feature_test.dart          # Feature-specific tests
```

## Tips

- Run tests individually on desktop (batch mode has issues)
- Use `--dart-define=INTERACT=5` to watch test execution
- Regenerate auth if tests fail with `invalid_grant`
- Use `pumpAndSettle()` before assertions to wait for animations
