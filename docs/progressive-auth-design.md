# Design: Inline Progressive Auth (fingerprint-first, just-in-time)

**Status:** Draft. The *full* flow depends on backend issues **#20** (passkey →
tokens), **#21** (usernameless passkey), **#22** (optional password), **#23**
(passkey-only / progressive accounts). The client `ensureAuth` plumbing can be
built **now** with a routing fallback, so call sites don't change when the
backend lands.

---

## 1. Principle

Let guests browse freely. Auth is requested **only at the moment a protected
action is taken**, via an **inline bottom sheet** (not a full-screen detour),
fingerprint-first. After auth, ask for profile info (email/phone/KYC) **only if
that specific action mandates it** — never a big form up front.

Two independent gates, composed:

1. **`ensureAuth(reason)`** — "are you signed in?" (passkey-first sheet).
2. **`ensureProfile(requirements)`** — "do you have the fields this action
   needs?" (just-in-time field prompts, skippable unless mandatory).

A protected action runs only after both pass.

---

## 2. The single entry point

Every protected action funnels through one helper (a Riverpod extension or a
provider method), so behavior + copy are consistent and there's one place to
swap implementations when the backend lands.

```dart
// returns true if the user ended up authenticated, false if they dismissed
Future<bool> ensureAuth(
  BuildContext context,
  WidgetRef ref, {
  required AuthReason reason,   // drives the sheet copy
});

enum AuthReason { addToCart, like, comment, follow, save, checkout, tip, general }
```

Call-site pattern (replaces today's scattered `_requireAuth`):

```dart
onTap: () async {
  if (!await ensureAuth(context, ref, reason: AuthReason.addToCart)) return;
  if (!await ensureProfile(context, ref, [ProfileField.shippingAddress])) return;
  await cart.add(productId);   // the real action — runs only when ready
}
```

---

## 3. `ensureAuth` flow

```
ensureAuth(reason)
 ├─ session authenticated?            → return true (no UI)
 ├─ persisted-but-locked session?     → biometric unlock (local_auth) → true/false
 └─ no session                        → show AuthPromptSheet(reason)
```

### AuthPromptSheet (modal bottom sheet)
- **Header:** contextual line from `reason` ("Sign in to add to cart",
  "Sign in to like", …) + 1-line subtext.
- **Primary:** big **Continue with Fingerprint** (auto-invokes the passkey
  ceremony on open; re-tappable).
- **"More ways to continue":** reveals Plan B — Email / Phone / Social /
  **Create account** (these are multi-step, so they route to the full flow and
  the sheet resolves `false`/closes; the user returns to the action afterward).
- **Dismiss:** swipe/backdrop → resolve `false` (action silently cancelled).

### Sheet state machine
`idle → authenticating → success | unsupported | failed`
- `success` → pop(true).
- `unsupported`/`failed` → auto-expand Plan B + short message.

---

## 4. `ensureProfile` flow (just-in-time, skippable)

After auth, read the backend **profile-completeness signal** (#23) to see which
fields the account already has/verified. For the action's required fields:

```
ensureProfile([fields])
 ├─ all required fields present/verified → return true
 └─ missing → show ProfilePromptSheet(missingFields)
       • collect ONLY the missing mandatory fields (e.g. email+OTP, phone+OTP,
         shipping address, or Creator/Vendor KYC)
       • "Skip" allowed ONLY when the field isn't mandatory for this action
       • on complete → return true; on skip-not-allowed → stays
```

Field → reuse existing verify endpoints (`verify-email`, `verify-phone`) and the
shipping/KYC screens. Creator/Vendor KYC is the same mechanism with a heavier
field set, gated at the role-upgrade action — not at first sign-in.

---

## 5. Backend calls per step

| Step | Today | After backend #20–#23 |
|---|---|---|
| passkey login | ❌ not possible (no token, not usernameless) → **fall back to full auth route** | `POST /v1/auth/passkeys/authenticate/{options,complete}` (usernameless) → AuthResponseVm |
| new user via passkey | ❌ → route to Create account | `POST /v1/auth/passkeys/register/bootstrap` → account + AuthResponseVm |
| profile completeness | ❌ no signal → assume complete / rely on 4xx | `GET` completeness signal (#23) |
| add email/phone later | exists (`verify-email`/`verify-phone`) but needs an account | same, on a partial account |

**Interim behavior (build now):** `ensureAuth`'s passkey path detects it can't
complete server-side and **routes to the existing fingerprint-first entry**
(`RouteNames.signInMethod`), returning `false`. The call sites and the sheet UI
are final; only the sheet's "authenticate" internals get swapped later.

---

## 6. Call sites to migrate onto `ensureAuth`

Standardize all of these (several already have ad-hoc guards):

- **Reels:** like / comment / share / save — `reel_actions.dart` already has a
  `_requireAuth(VoidCallback)`; generalize it into `ensureAuth`.
- **Commerce:** Add to Cart (tagged-product cards, product detail), Checkout,
  saved items.
- **Social:** Follow creator, Tips, group/drop-party joins, recommendations.
- **Creator/Vendor:** "Become a Creator/Vendor" → `ensureAuth` then
  `ensureProfile(KYC)`.

Audit: `grep -rn "_requireAuth\|context.push(RouteNames.signInMethod)" lib` and
replace each with the helper.

---

## 7. Riverpod wiring

- `authGateProvider` (or a `WidgetRef` extension) exposing `ensureAuth` /
  `ensureProfile`; reads `sessionControllerProvider` + `localAuthServiceProvider`
  + (future) a passkey-login provider built on `PasskeyService`.
- The sheets are presented via `showModalBottomSheet`; results bubble back
  through the `Future<bool>`.
- No change to the router guard — guest browsing stays as-is; the gate is
  action-level, not route-level.

---

## 8. Build plan

1. **Now:** `AuthReason`/`ProfileField` enums, `ensureAuth`/`ensureProfile`
   helpers, `AuthPromptSheet` (passkey CTA routes to full flow as interim) +
   `ProfilePromptSheet`. Migrate the existing `reel_actions` guard + Add-to-Cart
   onto it. Ship — call sites become final.
2. **When #20/#21 land:** implement real usernameless passkey login inside the
   sheet (returns tokens) — no call-site changes.
3. **When #22/#23 land:** passkey-only account bootstrap + the completeness
   signal → true skip-and-continue; `ensureProfile` becomes fully data-driven.

---

## 9. UX guardrails

- Never gate scrolling/viewing — only mutating/identity actions.
- One sheet at a time; debounce rapid taps.
- Optimistic UI (e.g. like) is **not** used pre-auth — auth first, then act, to
  avoid rollback flicker.
- Copy is short and contextual; the fingerprint is always the top option.
