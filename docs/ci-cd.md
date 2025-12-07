# CI/CD Integration

## Pre-generating Auth Tokens

For CI/CD, generate auth data before running tests:

```bash
dart run solid_test:generate_auth --headless
```

Tokens are valid for ~1 hour. For longer pipelines, regenerate before each test run.

## Environment Variables

```bash
# Disable auto-regeneration (fail if tokens expired)
flutter test integration_test/ --dart-define=AUTO_REGENERATE=false

# Set visual delay (0 for CI, >0 for debugging)
flutter test integration_test/ --dart-define=INTERACT=0
```

## GitHub Actions Example

```yaml
name: Integration Tests

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v4

      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.19.0'

      - name: Install dependencies
        run: |
          sudo apt-get update
          sudo apt-get install -y libsecret-1-dev chromium-browser
          flutter config --enable-linux-desktop
          flutter pub get

      - name: Setup test credentials
        run: |
          mkdir -p integration_test/fixtures
          echo '${{ secrets.TEST_CREDENTIALS }}' > integration_test/fixtures/test_credentials.json

      - name: Generate auth data
        run: dart run solid_test:generate_auth --headless

      - name: Run integration tests
        run: |
          flutter test integration_test/app_test.dart -d linux --dart-define=INTERACT=0
```

## Secrets Setup

Store `test_credentials.json` content as a GitHub secret:

1. Go to repo Settings > Secrets > Actions
2. Create `TEST_CREDENTIALS` with:
```json
{
  "email": "test@example.com",
  "password": "...",
  "securityKey": "...",
  "webId": "https://pods.dev.solidcommunity.au/test/profile/card#me",
  "podUrl": "https://pods.dev.solidcommunity.au/test/",
  "issuer": "https://pods.dev.solidcommunity.au"
}
```

## Headless Mode

Browser automation runs headless by default in CI. To debug:

```bash
# Local debugging with visible browser
dart run solid_test:generate_auth --no-headless
```
