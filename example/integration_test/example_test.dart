// Example integration test using solid_test package.
//
// This demonstrates how to set up authenticated integration tests
// for a Solid POD Flutter application.
//
// Before running:
// 1. Copy test_credentials.json.template to test_credentials.json
// 2. Fill in your POD credentials
// 3. Run: dart run solid_test:generate_auth
// 4. Run: flutter test integration_test/example_test.dart -d linux

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:solid_test/testing.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // Configure for your POD provider.
  final config = PodConfig.solidCommunityAu(
    clientName: 'Example App E2E Tests',
  );

  group('Authenticated POD Tests', () {
    setUpAll(() async {
      // Inject POD credentials before tests run.
      // This will:
      // 1. Load auth data from integration_test/fixtures/complete_auth_data.json
      // 2. Check if tokens are expired
      // 3. Auto-regenerate if needed (when AUTO_REGENERATE=true)
      // 4. Inject into flutter_secure_storage
      await AuthTestSetup.setUp(config: config);
    });

    tearDownAll(() async {
      // Clean up credentials after tests complete.
      await AuthTestSetup.tearDown();
    });

    testWidgets('credentials are injected successfully', (tester) async {
      // Verify that credential injection worked.
      final injected = await CredentialInjector.verifyInjection();
      expect(injected, isTrue, reason: 'Credentials should be injected');
    });

    // Add your app-specific tests here.
    // Example:
    //
    // testWidgets('app loads with authenticated state', (tester) async {
    //   app.main();
    //   await tester.pumpAndSettle(const Duration(seconds: 5));
    //
    //   // Verify user is logged in
    //   expect(find.text('Welcome'), findsOneWidget);
    //   expect(find.byIcon(Icons.logout), findsOneWidget);
    // });
  });

  group('Widget Helper Examples', () {
    testWidgets('demonstrates widget helpers', (tester) async {
      // These are examples of the widget helper extensions.
      // In a real test, you'd use these with your actual app.

      // Example: Wait for a widget with timeout
      // final found = await tester.waitForWidget(
      //   find.text('Loading...'),
      //   timeout: const Duration(seconds: 10),
      // );

      // Example: Tap by text
      // await tester.tapByText('Submit');

      // Example: Enter text in field
      // await tester.enterTextInField('search query');

      // Example: Tap icon if exists
      // await tester.tapIconIfExists(Icons.menu);

      // For this demo, we just pass
      expect(true, isTrue);
    });
  });
}
