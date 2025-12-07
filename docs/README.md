# solid_test Documentation

Quick reference for Solid POD integration testing.

## Documentation

- [Concepts](concepts.md) - OAuth, DPoP, PKCE basics
- [Testing Patterns](testing-patterns.md) - Writing tests with solid_test
- [Troubleshooting](troubleshooting.md) - Common errors and fixes
- [CI/CD](ci-cd.md) - Continuous integration setup

## Prerequisites

- [ ] Chrome/Chromium installed
- [ ] Flutter desktop enabled (`flutter config --enable-linux-desktop`)
- [ ] Test POD account created at [solidcommunity.au](https://pods.dev.solidcommunity.au)
- [ ] `libsecret` installed (Linux only): `sudo apt-get install libsecret-1-dev`

## External Resources

**Solid:**
- [Solid Project](https://solidproject.org/)
- [Solid-OIDC Primer](https://solid.github.io/solid-oidc/)

**OAuth/Security RFCs:**
- [OAuth 2.0 (RFC 6749)](https://datatracker.ietf.org/doc/html/rfc6749)
- [PKCE (RFC 7636)](https://datatracker.ietf.org/doc/html/rfc7636)
- [DPoP (RFC 9449)](https://datatracker.ietf.org/doc/html/rfc9449)

**Flutter:**
- [Integration Testing](https://docs.flutter.dev/testing/integration-tests)
