# Figma Node Map — Style Mint Mobile App

Single source of truth for Figma Dev Mode node IDs used during implementation.

- **File:** Style Mint Mobile App
- **FileKey:** `iLXoCdfCr47LSIUX74j1nc`
- **Base URL:** `https://www.figma.com/design/iLXoCdfCr47LSIUX74j1nc/Style-Mint-Mobile-App?node-id=<NODE>&m=dev`

How to use: pass `fileKey` + `nodeId` (colon form, e.g. `9365:7968`) to the Figma MCP
tools `get_design_context` / `get_metadata` / `get_screenshot` / `get_variable_defs`.

---

## ✅ Auth section (implemented)

| Screen | Node ID | Status |
|--------|---------|--------|
| Auth section (root, holds all auth variables) | `9684:13311` | tokens pulled |
| Sign-In Method Selection ("Login") | `9684:9357` | ✅ built |
| Login - Email | `9684:21684` | ✅ built |
| Login - Phone Number | `9688:21840` | ✅ built |
| Login - Passkey Face | `9704:9705` | ✅ built |
| Login - Passkey Fingerprint | `9704:14248` | ✅ built |
| Login - OTP Verification | `9684:20916` | ✅ built |
| Login - OTP Verification (filled) | `9684:20900` | ref |
| Login - Apple ID Third Party | `9704:14364` | deferred (OAuth) |
| Login - Facebook Third Party | `9704:14307` | deferred (OAuth) |
| Login - Google Third Party | `9704:14367` | deferred (OAuth) |

---

## 📋 Provided node links (to identify + build)

Pulled via `get_design_context` as each is implemented; label filled in then.

Each link is a **section** containing one or more screen frames.

| # | Section node | Section name | Key frames | Status |
|---|--------------|--------------|-----------|--------|
| 1 | `9365:7968` | Splash Screen | Splashscreen `9365:7950` | ✅ built |
| 2 | `9365:7970` | User Selection | Select User Type `9365:7986` | ✅ built |
| 3 | `9365:10823` | Onboarding (intro carousel) | Onboarding-1..4 `9615:35799`/`36317`/`36782`/`37145` | ✅ built (4-slide PageView) |
| 4 | `9365:12058` | Select Interests | Pick Your Interests `9615:45821`, Picked `9615:44929` | ✅ built (search/grid; Picked state via toggle) |
| 5 | `9375:21538` | Follow Creators | Follow Creators `9383:4993`, Followed `9375:21539` | ✅ built |
| 6 | `9386:5224` | TBD | — | pending |
| 7 | `9407:6543` | TBD | — | pending |
| 8 | `9440:14124` | TBD | — | pending |
| 9 | `9555:9991` | TBD | — | pending |
| 10 | `9611:3670` | TBD | — | pending |
| 11 | `9594:3600` | TBD | — | pending |
| 12 | `9981:16513` | TBD | — | pending |
| 13 | `9457:14057` | TBD | — | pending |
| 14 | `9483:12594` | TBD | — | pending |
| 15 | `9613:12407` | TBD | — | pending |

> Note: `9386:5224` was provided twice (deduped above).
> Remaining TBD sections identified lazily via `get_metadata` as reached.

---

## Raw URLs (as provided)

```
https://www.figma.com/design/iLXoCdfCr47LSIUX74j1nc/Style-Mint-Mobile-App?node-id=9365-7968
https://www.figma.com/design/iLXoCdfCr47LSIUX74j1nc/Style-Mint-Mobile-App?node-id=9365-7970
https://www.figma.com/design/iLXoCdfCr47LSIUX74j1nc/Style-Mint-Mobile-App?node-id=9365-10823
https://www.figma.com/design/iLXoCdfCr47LSIUX74j1nc/Style-Mint-Mobile-App?node-id=9365-12058
https://www.figma.com/design/iLXoCdfCr47LSIUX74j1nc/Style-Mint-Mobile-App?node-id=9375-21538
https://www.figma.com/design/iLXoCdfCr47LSIUX74j1nc/Style-Mint-Mobile-App?node-id=9386-5224
https://www.figma.com/design/iLXoCdfCr47LSIUX74j1nc/Style-Mint-Mobile-App?node-id=9407-6543
https://www.figma.com/design/iLXoCdfCr47LSIUX74j1nc/Style-Mint-Mobile-App?node-id=9440-14124
https://www.figma.com/design/iLXoCdfCr47LSIUX74j1nc/Style-Mint-Mobile-App?node-id=9555-9991
https://www.figma.com/design/iLXoCdfCr47LSIUX74j1nc/Style-Mint-Mobile-App?node-id=9611-3670
https://www.figma.com/design/iLXoCdfCr47LSIUX74j1nc/Style-Mint-Mobile-App?node-id=9594-3600
https://www.figma.com/design/iLXoCdfCr47LSIUX74j1nc/Style-Mint-Mobile-App?node-id=9981-16513
https://www.figma.com/design/iLXoCdfCr47LSIUX74j1nc/Style-Mint-Mobile-App?node-id=9457-14057
https://www.figma.com/design/iLXoCdfCr47LSIUX74j1nc/Style-Mint-Mobile-App?node-id=9483-12594
https://www.figma.com/design/iLXoCdfCr47LSIUX74j1nc/Style-Mint-Mobile-App?node-id=9613-12407
```
