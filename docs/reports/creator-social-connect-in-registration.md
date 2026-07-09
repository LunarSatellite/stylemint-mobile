# Proposal — Connect creator socials during registration

**Author:** Smit · **Date:** 6 Jul 2026 · **Status:** for team + backend review
**Scope:** `creator/apply` (registration wizard) + `creator/social_connect` (OAuth) + `POST /v1/creator/apply`

---

## 1. Why this proposal

The team wants creators to **connect their real social accounts during registration**, not just
self-declare them. This note captures the current state, the proposed flow, and the decisions we
need from backend before building.

## 2. Current state (verified against code + live Swagger)

There are **two separate concepts** today, and only one is wired into registration:

| Concept | What it is | Where | Status |
|---------|-----------|-------|--------|
| Apply `socials` | **Self-declared** platform + handle + follower count (no OAuth). Part of `POST /v1/creator/apply`. | Apply wizard, step 2 | Wired, but "connect" is just a tap-to-select toggle — `handle` is sent **empty**, follower count is whatever the user typed. |
| Real social connection | **OAuth-linked** accounts (`/v1/social/*`): connect / list / refresh / disconnect / pull content / publish scopes. | `creator/social_connect` feature | **Fully built** (screen + data layer + OAuth deep-link return in `main.dart`) but **has no entry point** — nothing in the app navigates to it. |

Consequences of the gap:
- Creators **cannot link a real social account anywhere** in the app right now.
- Reel import (`/v1/social/accounts/{provider}/content`) has no connected accounts to pull from.
- Apply submits an **empty `handle`** because there's no real connection behind the toggle.

## 3. Proposed flow

Bring the existing `social_connect` OAuth step **into the apply wizard's social step** (reuse, don't
rebuild):

1. Step 2 "Connect Social Media" → real **Connect** buttons (via `POST /v1/social/connect/{provider}/begin`).
2. OAuth opens the in-app browser; backend redirects back to `stylemint://social-connected?...`
   (already handled in `main.dart`).
3. On return, the wizard shows the connected account(s) with the **verified handle + follower count**.
4. On submit, populate the apply `socials` payload **from the connected accounts** → the empty-`handle`
   gap disappears automatically.

This is feasible because the creator apply flow runs **after login** — the account already exists and
is authenticated, so `/v1/social/connect` works mid-registration.

## 4. Decisions we need from backend

1. **Source of truth.** Once a creator OAuth-connects during registration, the backend already has it
   via `/v1/social/*`. Should `POST /v1/creator/apply` still carry the self-declared `socials` array,
   or should it be **derived from the connected accounts** (and we stop sending the self-declared one)?
2. **Mandatory vs optional.** Must a creator connect ≥1 account to finish registration, or can they
   skip and connect later from profile?
3. **Provider identifier mismatch.** Connect uses a provider **slug** (`instagram`); apply uses a
   provider **int enum** (1–4). Please confirm the canonical slugs and the slug↔enum mapping.
4. **Provider coverage.** Confirm `/v1/social/*` supports the same 4 platforms the apply enum allows
   (Instagram, TikTok, YouTube, Facebook).

## 5. Technical note (frontend)

OAuth leaves the app and returns via deep link **mid-wizard**. The wizard's form state
(`creatorFormProvider`) must survive the browser round-trip and resume on the social step. The
provider is in-memory and the app stays alive during an in-app browser session, so this is doable —
but it needs deliberate handling so a returning user lands back on the right step with their data
intact.

## 6. Effort (contingent on §4)

- If **connected accounts become the source of truth** (Q1) and connect is **optional** (Q2):
  ~1–1.5 days frontend — wire `social_connect` into step 2, resume-on-return handling, map connected
  accounts → apply payload.
- If backend wants **changes to the apply contract** (e.g. accept connection references instead of
  self-declared socials): add backend work + a contract update before frontend can finish.

## 7. Recommendation

Proceed. The connect feature is already built; the main work is (a) wiring it into the apply social
step with resume-on-return handling, and (b) the four backend confirmations above — primarily Q1,
which decides whether this is a ~1-day integration or a contract change.
