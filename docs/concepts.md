# Concepts

## Why Browser Automation?

Flutter integration tests can't intercept OAuth redirects that happen in external browsers. When a user logs into a Solid POD, the browser redirects to a callback URL that Flutter can't capture. Puppeteer automates this browser flow to obtain valid tokens.

## OAuth 2.0 + PKCE

Solid uses OAuth 2.0 Authorization Code Flow with PKCE (Proof Key for Code Exchange):

- **Authorization Code**: Temporary code exchanged for tokens
- **PKCE**: Security extension for public clients (no client secret)
  - App generates random `code_verifier`
  - Sends `code_challenge` (SHA-256 hash) with auth request
  - Server verifies verifier matches challenge when exchanging code

**Key tokens:**
| Token | Purpose | Lifetime |
|-------|---------|----------|
| Access Token | API requests | ~1 hour |
| ID Token | User identity (WebID) | ~1 hour |
| Refresh Token | Get new access tokens | Varies |

See [RFC 7636](https://datatracker.ietf.org/doc/html/rfc7636) for details.

## DPoP (Proof-of-Possession)

Standard Bearer tokens can be stolen and reused. DPoP binds tokens to a cryptographic keypair:

- **Bearer**: `Authorization: Bearer <token>` - anyone with token has access
- **DPoP**: `Authorization: DPoP <token>` + `DPoP: <proof>` - requires private key

Each API request includes a signed proof containing:
- HTTP method and target URL
- Timestamp (prevents replay)
- Unique request ID

The server verifies the signature matches the public key bound to the token.

See [RFC 9449](https://datatracker.ietf.org/doc/html/rfc9449) for details.

## RSA Keypairs

solid_test generates 2048-bit RSA keypairs for DPoP signing:

- **Private key**: Signs proofs, stored in `complete_auth_data.json`
- **Public key**: Sent to POD server during token exchange

Keys are stored in JWK (JSON Web Key) format for compatibility with the solidpod package.

## Auth Data Flow

```
1. Puppeteer launches browser
2. Navigates to POD login, fills credentials
3. Intercepts OAuth callback with auth code
4. Generates RSA keypair
5. Exchanges code for DPoP-bound tokens
6. Saves tokens + keys to complete_auth_data.json
7. Test injects auth data into flutter_secure_storage
8. App reads storage, thinks user is logged in
```
