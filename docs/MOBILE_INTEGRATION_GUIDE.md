# Mobile Integration Guide — Creator onboarding, social connect, dashboard (current)

Definitive guide for the changes the Flutter app (`stylemint_mobile_frontend`) must make after the
2026-06-16 backend work. Supersedes `BACKEND_CHANGES_2026-06-16.md` (kept for history).
Base URL: `https://stylemint.voyageritnepal.com`. Check `/swagger` on UAT for live schemas.

---

## 0. TL;DR of client work
1. Replace the multi-step creator application with **one call**: `POST /v1/creator/activate`, then the
   OAuth social-connect step. No docs, no handle entry, no manual socials, no "pending review".
2. **Re-login after activation** so the JWT carries the `Creator` role.
3. **Gate** all `/v1/creator/*` screens on the `Creator` role claim.
4. Social connect = OAuth in an in-app browser + `stylemint://social-connected` deep-link return.
5. Dashboard: reel titles are real (drop the mock), Clicks is N/A, Recent Activity = notifications inbox.
6. Fix the OTP-verify device payload.

---

## 1. Creator onboarding — instant, one call

### `POST /v1/creator/activate`
Authenticated (any customer). Headers: `Authorization: Bearer <jwt>`, `Idempotency-Key: <uuid>`.
```json
{ "bio": "optional, ≤500 chars", "expression": "optional free text, ≤140 chars — what you create" }
```
Both optional. **Response 200:**
```json
{ "creatorProfileId": "…", "profileApproved": true, "creatorRoleActive": true }
```
Idempotent. What the backend does automatically (no client input needed):
- **Auto-generates a unique @handle** from the account display name (editable later — see §6).
- Creates an **already-approved** creator profile + activates the **Creator role**.
- **AI-maps `expression` → categories** asynchronously (creator specializations) — so encourage the
  user to *describe themselves in words*; you may still show category chips as hints, but the text box
  is primary. Categories appear shortly after (async), not in the activate response.
- If the account has **neither a verified email nor phone**, it's flagged for admin review in the
  background — invisible to the user, activation still succeeds.

### Remove from the old creator screens
❌ document upload · ❌ manual handle field · ❌ manual social handle + follower-count fields ·
❌ "under review / 1–3 day SLA" copy · ❌ re-collecting name/email.

### ⚠️ Re-auth after activation (required)
JWT roles are baked at token issue. After `activate` returns 200, **re-login (or refresh)** before
calling any `/v1/creator/*` endpoint, or the stale token (still `["Customer"]`) gives 403. Confirm the
new token's `roles` includes `"Creator"`.

---

## 2. Social connect (OAuth) — import, don't type

See `SOCIAL_CONNECT_OAUTH.md` for full Flutter wiring. Summary:
1. `POST /v1/social/connect/{provider}/begin` (auth, `Idempotency-Key`, body `{}`) →
   `{ "url": "...", "state": "...", "expiresUtc": "...", "provider": <int> }`.
   `{provider}` ∈ `instagram` / `facebook` / `tiktok` / `youtube`.
2. Open `url` in an **in-app browser** (Custom Tab / `SFSafariViewController`), watching the
   already-registered `stylemint://` scheme.
3. Backend exchanges the code, **imports handle + follower count from the platform API**, then
   **302-redirects to `stylemint://social-connected?provider=<p>&status=ok|error`**. Catch it
   (existing `app_links` listener), close the browser, refresh.
4. `GET /v1/social/accounts` → connected accounts with imported `handle`, `displayName`,
   `followerCount`, `avatarUrl`. Disconnect: `DELETE /v1/social/accounts/{provider}` (verify path
   param against Swagger).

Connecting is **optional** to finish onboarding. Only providers with a registered+enabled app work;
others return `PROVIDER_UNAVAILABLE` (gate the buttons or handle the error). Live on UAT: Instagram, Facebook.

---

## 3. Auth / role handling
- **Gate `/v1/creator/*` on the `Creator` claim.** Customer-only token → 403 `auth.forbidden` (correct).
  Show a "Become a creator" CTA instead of calling and erroring.
- **OTP login verify** needs device binding: send `deviceFingerprint` (+ `devicePlatform`) and
  **omit `deviceId`** (random id → 404 "Device not found"). Enums are integers.
  ```json
  POST /v1/auth/login-otp/verify
  { "identifierType": 1, "identifier": "<email>", "code": "<otp>",
    "deviceFingerprint": "<stable-id>", "devicePlatform": 2 }
  ```
  `identifierType`: 1=Email, 2=Phone · `devicePlatform`: 0 Unknown / 1 iOS / 2 Android / 3 Web ·
  (UAT master OTP `12345`).
- Re-login/refresh after any role change so the token reflects it.

---

## 4. Creator dashboard — `GET /v1/creator/analytics/dashboard`
Requires `Creator` role (§3). Shape (zeros for a new creator):
```json
{
  "window": { "fromUtc","toUtc","durationDays" },
  "totalEarnings":  { "current": {"amount","currency"}, "previous": {…}, "deltaPercent" },
  "totalSales":     { "current","previous","deltaPercent" },
  "conversionRate": { "current","previous","deltaPercent" },
  "totalViews":     { "current","previous","deltaPercent" },
  "pendingBalance": { "amount","currency" },
  "topReels":    [ { "reelId","title","thumbnailUrl","publishedAtUtc","views","likes","impressions","shares","comments","sales","earnings" } ],
  "topProducts": [ { "productId","name","thumbnailUrl","totalSales","totalCommission","commissionRatePercent","avgCommissionPerSale" } ]
}
```
- ✅ **Reel titles** — already here (`topReels[].title`). **Delete the mock.**
- ❌ **Clicks** — not tracked; hide or render 0.
- ⏳ **Reels count** — not in payload yet; keep mocked until backend adds it.
- **Recent Activity** → `GET /api/v1/notifications/inbox` (**note the `api/` prefix**). Query
  `before` (cursor) + `pageSize` (default 20); plain list (no `nextCursor` — page by the last item's
  `queuedUtc`). Item = `NotificationDispatchDto` (`id, eventName, channel, category, state, queuedUtc,
  readUtc, variablesJson, …`); render display text from `templateKey` + `variablesJson`. Mark read:
  `POST /api/v1/notifications/inbox/{id}/read`, `.../read-all`.

---

## 5. Creator profile after activation
- The account now has a **Creator role-profile** and a **CreatorProfile** (approved).
- An **auto @handle** exists (display it on the creator profile).
- **Specializations** (AI-derived categories) populate shortly after activation — fetch via the
  creator-specializations endpoint (`GET /v1/accounts/{accountId}/creator-specializations`) to show them.

## 6. Handle is editable later
The auto-handle can be changed in profile settings via the account-handle endpoints
(`/v1/accounts/{accountId}/...handles`, register/activate; uniqueness enforced server-side). Offer a
"change handle" affordance; don't force handle entry during onboarding.

---

## 7. Net client change-list
1. New instant-activation flow (optional bio + expression) → OAuth social-connect → **re-login**.
2. Gate `/v1/creator/*` on the `Creator` claim; CTA when absent.
3. Social connect: in-app browser + `stylemint://social-connected` handling.
4. OTP verify payload: `deviceFingerprint` + `devicePlatform`, no random `deviceId`.
5. Dashboard: drop reel-title mock, hide Clicks, wire Recent Activity to notifications inbox, keep
   Reels-count mocked.
6. Show auto @handle + AI specializations on the creator profile; add a "change handle" option.

Mismatches → `/swagger` on UAT or ping backend.
