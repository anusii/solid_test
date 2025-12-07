# Troubleshooting

## Quick Checklist

When tests fail, check in order:

1. [ ] Test file ends with `_test.dart`
2. [ ] Auth data is fresh (< 1 hour old)
3. [ ] Chrome/Chromium is installed
4. [ ] `test_credentials.json` exists and is correct
5. [ ] Desktop platform enabled (`flutter devices` shows device)
6. [ ] Not running batch mode on desktop (run tests individually)

---

## Common Errors

### `invalid_grant`

```
AuthDataManager => _getTokenResponse() failed: OpenIdException(invalid_grant)
```

**Cause:** Tokens expired or incomplete auth data.

**Fix:** Regenerate auth data:
```bash
dart run solid_test:generate_auth
```

---

### Browser Automation Timeout

**Cause:** Chrome not found, login failed, or network issues.

**Debug:** Run with visible browser:
```bash
dart run solid_test:generate_auth --no-headless
```

**Check:**
- Chrome/Chromium installed
- Credentials correct in `test_credentials.json`
- POD server accessible: `curl https://pods.dev.solidcommunity.au/.well-known/openid-configuration`

---

### No Device Found

```
No desktop device found. Please ensure you have the correct desktop platform enabled.
```

**Fix:**
```bash
flutter config --enable-linux-desktop  # or --enable-windows-desktop
flutter devices  # verify device appears
```

---

### Tests Pass with INTERACT but Fail Without

**Cause:** Timing issue - test relies on visual delays for functionality.

**Fix:**
- Use `await tester.pumpAndSettle()` for animations/futures
- Use `delay` (2s) for required network waits
- Use `hack` (10s) as temporary workaround with TODO comment

```dart
await tester.pumpAndSettle();
await Future.delayed(delay);  // Required for network
```

---

### Batch Test Failures (Desktop)

```
Error waiting for a debug connection: The log reader stopped unexpectedly
```

**Cause:** Flutter desktop limitation - can't run multiple integration tests in batch.

**Fix:** Run tests individually:
```bash
flutter test integration_test/app_test.dart -d linux
flutter test integration_test/other_test.dart -d linux
```

---

### Test Not Discovered

**Cause:** File doesn't end with `_test.dart`.

**Fix:** Rename file:
```bash
mv integration_test/my_test.dart integration_test/my_test_test.dart
```

---

## Still Stuck?

- Check [Concepts](concepts.md) for OAuth/DPoP understanding
- Review [Testing Patterns](testing-patterns.md) for usage examples
- File an issue at [github.com/anusii/solid_test](https://github.com/anusii/solid_test/issues)
