# Profile API — Frontend Contract

What the mobile app sends and expects for every Profile-feature endpoint.
Use this to align the backend responses with what the UI consumes.

**Conventions**
- All timestamps are ISO 8601 **UTC** (e.g. `2026-06-10T10:17:43.021660Z` or `+00:00`).
- Money/handles follow existing app conventions — not relevant here.
- `🟢 returned today` = present in current response · `🔴 NEEDED` = UI uses it but backend does not return it yet.

---

## 1. Get profile — `GET /v1/accounts/{accountId}`

Used for both the profile header and the full/edit profile. `{accountId}` is the
signed-in account id (the app substitutes it; it must not be a literal).

### Current response (what we receive today)
```json
{
  "id": "e2ffde08-a658-4a1b-8822-0e67ae36d5e3",
  "displayName": "smit",
  "locale": "en-US",
  "timezone": "Asia/Kathmandu",
  "status": 1,
  "dateOfBirth": null,
  "gender": null,
  "avatarUrl": null,
  "countryCode": null,
  "emailVerifiedUtc": "2026-06-10T10:23:01.586928+00:00",
  "phoneVerifiedUtc": "2026-06-10T10:23:15.024549+00:00",
  "lastActiveUtc": null,
  "createdUtc": "2026-06-10T10:17:43.02166+00:00",
  "updatedUtc": "2026-06-10T10:23:15.024549+00:00",
  "createdById": "e2ffde08-a658-4a1b-8822-0e67ae36d5e3",
  "updatedById": "e2ffde08-a658-4a1b-8822-0e67ae36d5e3",
  "rowVersion": "wydTWtf2FWU="
}
```

### Fields the app actually uses
| Field | Type | Status | Maps to (app) | Notes |
|---|---|---|---|---|
| `id` | string (uuid) | 🟢 | `id` | |
| `displayName` | string | 🟢 | `displayName` | |
| `avatarUrl` | string \| null | 🟢 | `avatarUrl` | null is fine |
| `gender` | string \| null | 🟢 | `gender` | |
| `dateOfBirth` | string(date) \| null | 🟢 | `dateOfBirth` | |
| `locale` | string | 🟢 | `language` | e.g. `en-US` |
| `createdUtc` | string(datetime) | 🟢 | `dateJoined` | |
| `email` | string | 🔴 **NEEDED** | `email` | shown in profile header |
| `phone` | string \| null | 🔴 **NEEDED** | `phone` | shown in edit profile |
| `bio` | string \| null | 🔴 **NEEDED** | `bio` | editable field — see §2 |
| `website` | string \| null | 🔴 **NEEDED** | `website` | editable field — see §2 |

All other keys (`status`, `timezone`, `countryCode`, `*VerifiedUtc`,
`lastActiveUtc`, `updatedUtc`, `createdById`, `updatedById`, `rowVersion`) are
ignored by the app — fine to keep, we just don't read them.

### Response we'd like (current + the 🔴 fields added)
```json
{
  "id": "e2ffde08-a658-4a1b-8822-0e67ae36d5e3",
  "displayName": "smit",
  "email": "smit@example.com",
  "phone": "+9779800000000",
  "bio": "Streetwear curator.",
  "website": "https://smit.example",
  "avatarUrl": null,
  "gender": null,
  "dateOfBirth": null,
  "locale": "en-US",
  "createdUtc": "2026-06-10T10:17:43.021660Z"
}
```

---

## 2. Update profile — `PATCH /v1/accounts/{accountId}`

Partial update — only the changed keys are sent (all optional).

### Request body
```json
{
  "displayName": "smit",
  "bio": "Streetwear curator.",
  "website": "https://smit.example",
  "avatarPath": "uploads/avatars/abc123.jpg",
  "gender": "male",
  "dateOfBirth": "1999-05-20"
}
```

| Field | Type | Notes |
|---|---|---|
| `displayName` | string | optional |
| `bio` | string | optional |
| `website` | string | optional |
| `avatarPath` | string | optional — storage path/key from the upload step |
| `gender` | string | optional |
| `dateOfBirth` | string(date) | optional, `YYYY-MM-DD` |

### Response
Same shape as §1 (the updated account, ideally **including** `email`, `phone`,
`bio`, `website` so the UI reflects the save immediately).

> ⚠️ **Round-trip gap:** the app sends `bio` and `website` here, but `GET` (§1)
> does not return them. Please persist and return these on both GET and PATCH.

---

## 3. Following list — `GET /v1/connections`

People the signed-in user follows. Cursor-paginated.

### Query params
| Param | Type | Notes |
|---|---|---|
| `limit` | int | default 20 |
| `search` | string | optional — name/handle filter |
| `cursor` | string | optional — opaque, echo back `nextCursor` from prior page |

### Expected response
```json
{
  "items": [
    {
      "id": "a1b2c3d4-0000-0000-0000-000000000001",
      "displayName": "Aashna",
      "avatarUrl": "https://cdn.example/a.jpg",
      "handle": "aashna",
      "isFollowing": true,
      "followerCount": 1280
    }
  ],
  "totalCount": 1,
  "pageSize": 20,
  "nextCursor": "eyJvZmZzZXQiOjIwfQ==",
  "previousCursor": null,
  "hasMore": false
}
```

| Field | Type | Notes |
|---|---|---|
| `items[].id` | string (uuid) | |
| `items[].displayName` | string | |
| `items[].avatarUrl` | string | empty string if none |
| `items[].handle` | string | without `@` |
| `items[].isFollowing` | bool | |
| `items[].followerCount` | int | |
| `totalCount` | int | |
| `pageSize` | int | |
| `nextCursor` | string \| null | opaque; null when no more pages |
| `previousCursor` | string \| null | |
| `hasMore` | bool | |

---

## 4. Unfollow — `DELETE /v1/connections/{userId}`

No request body. Success = `204 No Content` (or `200`). No response body needed.

---

## 5. Profile counters & push (header stats) — **source TBD**

The profile header shows three counters and a push toggle that **no profile
endpoint currently returns**. The app defaults them to `0` / `true` today.

| App field | Type | Where shown |
|---|---|---|
| `savedItemsCount` | int | stats row |
| `followingCount` | int | stats row |
| `ordersCount` | int | stats row |
| `pushEnabled` | bool | settings row |

**Please pick one and confirm:**

**Option A — add to the account response (§1):**
```json
{
  "savedItemsCount": 12,
  "followingCount": 34,
  "ordersCount": 5
}
```

**Option B — dedicated summary endpoint** `GET /v1/accounts/{accountId}/summary`:
```json
{
  "savedItemsCount": 12,
  "followingCount": 34,
  "ordersCount": 5,
  "pushEnabled": true
}
```

(`pushEnabled` more naturally belongs with notification preferences —
`/v1/notifications/preferences` — if that's where it already lives, say so and
we'll read it from there instead.)

---

## Summary of asks for backend
1. **§1 GET** — add `email`, `phone`, `bio`, `website` to the account response.
2. **§2 PATCH** — persist + return `bio` and `website` (round-trip them).
3. **§5 counters** — decide Option A vs B for `savedItemsCount` /
   `followingCount` / `ordersCount`, and confirm where `pushEnabled` lives.
4. **§3 connections** — confirm the response matches the shape above
   (`items` + cursor fields).
