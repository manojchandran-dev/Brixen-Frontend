# Forgot PIN API

The app's lock screen now has a **Forgot PIN?** link. The user verifies a code sent to their account email, then sets a new PIN without needing the old one. Today `POST /auth/pin` requires `currentPin` when a PIN exists, so this needs three new endpoints.

The user is still signed in on the device. The lock screen only has the **refresh token**, and the access token may have expired. So the first two calls identify the user by `refreshToken`, the same way `POST /auth/pin/verify` does.

All three use the usual `{ "data": ... }` response format. Error bodies should include a `message` field, because the app shows that text to the user.

## 1. Send the code: `POST /api/v1/auth/pin/forgot`

```json
{ "refreshToken": "…" }
```

This emails a 6-digit OTP to the account's email address. The email should say it's for resetting the **app PIN**, not the password.

```json
{ "data": { "email": "m***@gmail.com" } }
```

The app shows this masked email as "Enter the code sent to m***@gmail.com". It lets the user resend after 30 seconds.

## 2. Verify the code: `POST /api/v1/auth/pin/forgot/verify`

```json
{ "refreshToken": "…", "otp": "123456" }
```

```json
{ "data": { "resetToken": "…" } }
```

- **Reset token:** single-use and short-lived. About 10 minutes is enough.
- **Wrong or expired code:** return `400` with a `message`. The app shows it and clears the code for another try.

## 3. Set the new PIN: `POST /api/v1/auth/pin/reset`

```json
{ "resetToken": "…", "pin": "654321" }
```

This stores the new PIN hash and makes the reset token unusable. It returns a fresh session in the same format as `/auth/pin/verify`:

```json
{ "data": { "accessToken": "…", "refreshToken": "…", "user": { "role": "superadmin" } } }
```

## Errors

| Status | When | What the app does |
|---|---|---|
| `400` | Wrong or expired OTP, bad PIN format, used or expired reset token | Shows `message` |
| `401` | Refresh token missing, expired or revoked | Clears the session and sends the user to Sign in |
| `429` | Too many codes or attempts (please rate-limit) | Shows `message` |

## Suggested limits

- 5 codes per hour per user.
- 5 wrong OTP attempts per code.
- A code expires after 10 minutes.
- Record `pin_reset` in `activity_logs`.
