# Backend changes the mobile app must adopt (2026-06-16)

This session reworked **creator onboarding**, **social connect**, **auth/role handling**, and the
**creator dashboard**. Below is exactly what changed and what the Flutter app
(`stylemint_mobile_frontend`) needs to do. Base URL: `https://stylemint.voyageritnepal.com`.

---

## 1. Creator onboarding is now ONE instant call — `POST /v1/creator/activate`

The old multi-step creator application (manual handle, self-reported socials + follower counts,
document upload, 3-day admin review) is **gone**. Anyone becomes a creator instantly.

**Remove from the creator-onboarding screens:**
- ❌ document upload (was never a real backend requirement)
- ❌ manual handle entry (auto-generated server-side; editable later)
- ❌ manual social handle + follower-count fields (imported via OAuth — see §2)
- ❌ "under review / pending approval" state and the 1–3 day SLA copy
- ❌ re-collecting name/email (already on the account)

**New call** (authenticated; send `Idempotency-Key`):
```
POST /v1/creator/activate
Authorization: Bearer <jwt>
Idempotency-Key: <uuid>
Content-Type: application/json

{ "bio": "optional short bio", "expression": "free text: what do you create" }
```
Both fields optional. `bio` ≤ 500 chars, `expression` ≤ 140 chars.

**Response 200:**
```json
{ "creatorProfileId": "…", "profileApproved": true, "creatorRoleActive": true }
```
Idempotent — calling again for an existing creator returns the same result.

> `expression` is free text ("what do you create / what are you about"). The backend maps it to
> categories with AI — the app should **encourage typing**, not force a category picker. (You may
> still *show* suggested categories, but the text box is the primary input.)

**CRITICAL — re-auth after activation:** JWT roles are baked at token-issue time. After
`activate` succeeds you MUST get a **fresh token** (re-login, or refresh) before calling any
`/v1/creator/*` endpoint — otherwise the old token is still `["Customer"]` and you'll get 403.
Decode the new token's `roles`; it should now include `"Creator"`.

---

## 2. Social connect = OAuth, not manual entry

Creators link Instagram / Facebook / TikTok / YouTube via OAuth; the backend imports handle +
followers. See the companion doc `SOCIAL_CONNECT_OAUTH.md` for the full Flutter wiring.

**Flow:**
1. `POST /v1/social/connect/{provider}/begin` (auth; `Idempotency-Key`; body `{}`) →
   ```json
   { "url": "https://www.instagram.com/oauth/authorize?client_id=…", "state": "…", "expiresUtc": "…", "provider": 1 }
   ```
   `provider` ∈ `instagram` / `facebook` / `tiktok` / `youtube`.
2. Open `url` in an **in-app browser** (Custom Tab / `SFSafariViewController`) — not the external browser.
3. Backend exchanges the code server-side, then **302-redirects to the deep link**
   `stylemint://social-connected?provider=<p>&status=ok|error` (the app already registers the
   `stylemint://` scheme). Catch it via the existing `app_links` listener (or `flutter_web_auth_2`),
   close the browser, and refresh.
4. `GET /v1/social/accounts` → list of connected accounts (imported handle + follower count).
5. Disconnect: `DELETE /v1/social/accounts/{provider}` — **verify the exact path param** against
   Swagger (the current mobile code uses `{accountId}`; confirm before shipping).

Connecting a platform is **optional** to finish creator onboarding.

**Status today:** only providers with a registered app are live (Instagram + Facebook on UAT).
A disabled provider returns `PROVIDER_UNAVAILABLE` (clean error) — gate the buttons or handle it.

---

## 3. Auth / role handling

- **Don't call `/v1/creator/*` unless the JWT has `Creator`.** A Customer-only token correctly gets
  **403 `auth.forbidden`**. Gate creator screens on the decoded `roles` claim and show a
  "Become a creator" CTA instead of firing the call and showing a generic error.
- **OTP login verify** requires device binding: send `deviceFingerprint` (+ `devicePlatform`),
  and **omit `deviceId`** to auto-register a device. Sending a random `deviceId` → 404
  "Device not found". (UAT master OTP is `12345`.)
  ```json
  POST /v1/auth/login-otp/verify
  { "identifierType": 1, "identifier": "<email>", "code": "12345",
    "deviceFingerprint": "<stable-id>", "devicePlatform": 2 }
  ```
  `identifierType`: 1 = Email, 2 = Phone (enums are integers — no string-enum). `devicePlatform`:
  0 Unknown / 1 iOS / 2 Android / 3 Web.
- After any role change (e.g. `activate`), **re-login or refresh** so the new token carries the role.

---

## 4. Creator dashboard — `GET /v1/creator/analytics/dashboard`

Requires the `Creator` role (see §3). Returns (verified, zeros for a new creator):
```json
{
  "window": { "fromUtc": "…", "toUtc": "…", "durationDays": 30 },
  "totalEarnings":  { "current": {"amount":0,"currency":"NPR"}, "previous": {…}, "deltaPercent": null },
  "totalSales":     { "current": 0, "previous": 0, "deltaPercent": null },
  "conversionRate": { "current": 0, "previous": 0, "deltaPercent": null },
  "totalViews":     { "current": 0, "previous": 0, "deltaPercent": null },
  "pendingBalance": { "amount": 0, "currency": "NPR" },
  "topReels":    [ { "reelId","title","thumbnailUrl","publishedAtUtc","views","likes","impressions","shares","comments","sales","earnings" } ],
  "topProducts": [ { "productId","name","thumbnailUrl","totalSales","totalCommission","commissionRatePercent","avgCommissionPerSale" } ]
}
```

Resolve the remaining placeholders:
- ✅ **Reel titles** — already here: `topReels[].title` (+ thumbnail + metrics). **Delete the mock now.**
- ❌ **Clicks** — NOT available. Backend doesn't track clicks yet (hardcoded 0 pending the signals
  pipeline). Hide it or render 0; do not expect real data.
- ⏳ **Reels count** — not in the payload yet; backend will add it (lifetime vs window TBD).
- ⏳ **Recent Activity** — use the notifications inbox: **`GET /api/v1/notifications/inbox`**
  (note the **`api/` prefix**, unlike other `/v1/...` routes). Query `before` (DateTimeOffset cursor)
  + `pageSize` (default 20); returns a plain list (no `nextCursor` — page by the last item's `queuedUtc`).
  Item = `NotificationDispatchDto` (`id, eventName, channel, category, state, queuedUtc, readUtc,
  variablesJson, …`); display text is rendered from `templateKey` + `variablesJson`. Mark read:
  `POST /api/v1/notifications/inbox/{id}/read` and `.../read-all`.
  ⚠️ Inbox is currently affected by a known backend auth-helper bug (returns empty for real users)
  until that's fixed — coordinate before wiring it as the primary activity source.

---

## 5. Net client changes
1. Replace the multi-step creator application UI with the single `POST /v1/creator/activate` call
   (optional bio + expression), then the OAuth social-connect step (§2), then **re-login**.
2. Gate `/v1/creator/*` on the `Creator` role claim; CTA when absent.
3. Fix OTP verify payload (fingerprint + platform, no random deviceId).
4. Dashboard: drop the reel-title mock, hide Clicks, wire Recent Activity to the notifications inbox
   (pending the backend auth fix), keep Reels-count mocked until the backend adds the field.
5. Social connect: open the authorize URL in an in-app browser and handle the `stylemint://social-connected`
   return (see `SOCIAL_CONNECT_OAUTH.md`).

Questions or shape mismatches → check Swagger (`/swagger`) on UAT, or ping backend.
