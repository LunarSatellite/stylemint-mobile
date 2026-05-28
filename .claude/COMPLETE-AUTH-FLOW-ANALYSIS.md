# Complete Auth Flow Analysis & Implementation Plan

**Based on Design Specifications Extracted**

---

## Overview: Multi-Method Authentication System

Your design includes **6 sign-in methods**:
1. ✅ Phone (OTP) - **PARTIALLY IMPLEMENTED**
2. 📧 Email (OTP or Magic Link)
3. 🔑 Passkey (Face ID or Fingerprint)
4. 🍎 Apple (OAuth)
5. 🔵 Google (OAuth)
6. 📘 Facebook (OAuth)

Plus **User Type Selection** after successful login.

---

## Current Status

### ✅ IMPLEMENTED (Phase 1)
- LoginScreen (phone input)
- OtpScreen (5-digit verification)
- UserTypeSelectionScreen (customer/creator/vendor)
- Phone OTP flow: complete

### ❌ NOT IMPLEMENTED (Phases 2-5)
- Sign-In Method Selection Screen (entry point!)
- Email login flow
- Passkey setup flows (Face + Fingerprint)
- Social login flows (Apple, Google, Facebook)
- Magic link verification for email

---

## Complete Auth Flow Sequence

```
┌─────────────────────────────────────┐
│  Sign-In Method Selection Screen    │ ← USER STARTS HERE
│  (Phone, Email, Passkey, Social)    │
└──────────┬──────────────────────────┘
           │
    ┌──────┴──────┬──────────┬──────────┬────────────┐
    │             │          │          │            │
    ▼             ▼          ▼          ▼            ▼
  PHONE        EMAIL      PASSKEY     APPLE      GOOGLE
   ↓             ↓           ↓          ↓            ↓
┌──────┐   ┌──────────┐  ┌──────┐  ┌──────┐    ┌──────┐
│Phone │   │Email     │  │Setup │  │OAuth │    │OAuth │
│Input │   │Input     │  │Face  │  │Flow  │    │Flow  │
└──┬───┘   └────┬─────┘  └──┬───┘  └──┬───┘    └──┬───┘
   │            │            │        │           │
   ▼            ▼            ▼        ▼           ▼
┌──────────┐ ┌──────────┐ ┌──────────┐ (Redirect to callback)
│OTP or    │ │Verify    │ │Biometric │
│Magic Link│ │OTP/Link  │ │Auth      │
└────┬─────┘ └────┬─────┘ └────┬─────┘
     │            │            │
     └────────────┴────────────┘
            │
            ▼
  ┌──────────────────────┐
  │ User Type Selection  │
  │ (Customer/Creator/   │
  │  Vendor)             │
  └──────────┬───────────┘
             │
             ▼
  ┌──────────────────────┐
  │ Home Screen          │
  │ (Role-Specific)      │
  └──────────────────────┘
```

---

## Detailed Specifications by Method

### 1. PHONE LOGIN (Currently Implemented ✅)

**Screen 1: Phone Input**
```
Title: "Enter your Phone No."
Subtitle: "Sign in with your phone number. Passwordless and easy"
Icon: Phone (100x100, blue #00A6F4)

Input Field:
- Label: "Phone Number"
- Placeholder: "XXXXXXXXXX" (10 digits)
- Country code dropdown: +977 (default, flags: 🇳🇵 🇺🇸 🇮🇳)
- Border-radius: 8px
- Padding: 14px 12px
- Height: 48px
- Border: 1px solid #52525C (default) → #2ECC71 (focused)
- Background: #27272A

Button: "Submit"
- Padding: 16px 32px
- Border-radius: 999px (fully rounded)
- Background: #2ECC71
- Text color: #06190E (dark)
- Font: Poppins 16px 600

Validation:
- "Please enter a valid phone number" (< 10 digits)
```

**Screen 2: OTP Verification**
```
Title: "OTP Verification"
Subtitle: "Please enter the OTP code we sent you in the phone number"
Icon: Green checkmark (100x100)

OTP Input: 5 digits (each digit in separate box)
- Box border-radius: 8px
- Spacing between boxes: 8px
- Auto-submit on complete

Resend Code:
- Text: "Did not receive code?" + "Resend Code" (green, 14px 600)
- Disabled for 60 seconds after request
- Shows countdown: "Resend Code (60s)"

Button: "Verify →"
- Same styling as Submit button
- Shows "Verifying..." during request

Validation:
- "Invalid OTP code. Please try again"
- "OTP code has expired. Request a new one"
```

---

### 2. EMAIL LOGIN (New - Need to Implement)

**Screen: Email Input with Verification Type Selection**
```
Title: "Enter your Email"
Subtitle: "Sign in with your email. Password-less and easy"
Icon: Email (115x100)

Email Input:
- Label: "Email Address"
- Placeholder: "user@example.com"
- Same styling as phone input (height 48px, border-radius 8px)

Email Verification Type (Radio Buttons):
- Title: "Email Verification Type"
- Option 1: "OTP Verification"
  Description: "We will send you an OTP for verification"
  Radio button (default selected)
  
- Option 2: "Magic Link Verification"
  Description: "We will send you a link to sign in"
  Radio button

Radio Button Styling:
- Container: min-height 48px, padding 8px 12px
- Background: #18181B
- Border-radius: 8px
- Title color: #FFF (14px 400)
- Description color: #9F9FA9 (12px 400)
- Icon: 20x20, #71717B (default) → #2ECC71 (selected)

Button: "Submit"
- Same as phone input

Flow:
- If OTP selected: Go to OTP verification (same as phone)
- If Magic Link selected: Go to Magic Link verification
```

---

### 3. PASSKEY LOGIN (New - Need to Implement)

**Screen: Passkey Setup (Face ID)**
```
Title: "Setup a Passkey"
Subtitle: "Sign in with just your face. Password-less, secure and works across all devices"
Icon: Face ID icon (100x100, cyan #00A6F4 outlines)

How It Works Section:
- Container: padding 12px, border-radius 16px, background #052F4A (dark blue)
- Icon: 24x24, fill #B8E6FE (light blue)
- Title: "How it works:" (14px 600, color #B8E6FE)
- Bullet points (12px 400, color #B8E6FE):
  • "We'll ask you to verify with Face ID/Touch ID"
  • "Your device create a secure passkey"
  • "Next time, just use biometrics to sign in"
  • "Your privacy is protected. Passkeys never leave your device"

Button: "Setup Passkey →"
- Same button styling
- Icon: 16x16 (arrow or checkmark)
```

**Screen: Passkey Setup (Fingerprint)**
```
Same as Face ID, but:
- Subtitle: "Sign in with just your finger print..."
- Icon: Fingerprint icon (100x100, magenta/purple)
```

**Flow:**
1. User taps "Setup Passkey" on Sign-In Methods screen
2. Choose Face ID or Fingerprint
3. Tap "Setup Passkey" button
4. Biometric prompt appears (native iOS/Android)
5. On success: Go to User Type Selection
6. On failure: Show error and return to Sign-In Methods

---

### 4. SOCIAL LOGINS (New - Need to Implement)

**Sign-In Methods Selection shows:**
```
Social Login Buttons (shown below other methods):
- Apple Sign In (Black or white button)
- Google Sign In (Multicolor button)
- Facebook Sign In (Blue button)
- Other providers (TBD)

Button styling:
- Height: 48px
- Border-radius: 999px
- Show provider logo + "Continue with [Provider]"
- Padding: 16px 32px

Flow:
1. User taps social provider
2. Native OAuth flow opens (Safari/Chrome)
3. User authenticates with provider
4. Redirect to app with auth token
5. Exchange token for app session
6. Go to User Type Selection
```

---

## Sign-In Method Selection Screen (NEW - CRITICAL!)

**This is the entry point to auth flow!**

```
Layout:
┌─────────────────────────────┐
│  Title: "Sign In"           │
│  (Maybe: "How would you     │
│   like to sign in?")        │
├─────────────────────────────┤
│                             │
│  [📱 Phone Number]          │ ← Tab 1
│  "Sign in with your phone"  │
│                             │
│  [📧 Email]                 │ ← Tab 2
│  "Sign in with your email"  │
│                             │
│  [🔑 Passkey]               │ ← Tab 3
│  "Sign with Face ID/Touch"  │
│                             │
│  ─────────────────────────  │
│                             │
│  Or continue with:          │
│                             │
│  [🍎] [🔵] [📘]            │ ← Social buttons
│  Apple Google Facebook      │
│                             │
└─────────────────────────────┘
```

**Design Details:**
```
Screen Title:
- Color: #FFF
- Font: Poppins 24px 600
- Alignment: center or left
- Margin: 24px top

Method Cards (tappable):
- Container: 
  Background: #18181B
  Padding: 16px
  Border: 1px solid #52525C (default) → #2ECC71 (selected)
  Border-radius: 16px
  Margin-bottom: 12px

- Icon (40x40): method icon (phone, email, passkey)
- Title (16px 600, #FFF): "Phone Number" / "Email" / "Passkey"
- Description (14px 400, #9F9FA9): "Sign in with..."
- Chevron: right arrow (#9F9FA9)

Social Buttons:
- "Or continue with:" label (14px 400, #9F9FA9)
- Three buttons in a row:
  [Button][Button][Button]
- Each button: 48px height, provider logo/icon
- Spacing: 12px between buttons

Bottom:
- "Already have an account?" + "Sign In" link (if different from current flow)
- Or: "Privacy Policy" / "Terms" links
```

---

## Complete Authentication Architecture

### API Endpoints Needed

```
POST /v1/auth/login-otp/request
  Body: { identifierType: "phone"|"email", identifier: string }
  Response: { otpId, expiresUtc, devPlaintextCode? }

POST /v1/auth/login-otp/verify
  Body: { identifierType: "phone"|"email", identifier, code, deviceId? }
  Response: { accountId, sessionId, accessToken, refreshToken, expiresUtc }

POST /v1/auth/login-magic-link/request
  Body: { email: string }
  Response: { linkSent: true, email: string }

GET /v1/auth/login-magic-link/verify?token=xxx
  Response: { accountId, sessionId, accessToken, refreshToken, expiresUtc }

POST /v1/auth/login-passkey/register
  Body: { attestationObject, clientDataJSON, ... }
  Response: { registrationId, credentialId, ... }

POST /v1/auth/login-passkey/authenticate
  Body: { credentialId, assertionObject, clientDataJSON, ... }
  Response: { accountId, sessionId, accessToken, refreshToken, expiresUtc }

POST /v1/auth/login-oauth/callback
  Body: { provider: "apple"|"google"|"facebook", code: string, state: string }
  Response: { accountId, sessionId, accessToken, refreshToken, expiresUtc }
```

### State Management Needed

```dart
// Auth method selection
final selectedAuthMethod = StateProvider<AuthMethod>((ref) => AuthMethod.phone);

// OTP request/verify
final otpRequestProvider = StateNotifierProvider<OtpRequestNotifier, OtpRequestState>(...);
final otpVerificationProvider = StateNotifierProvider<OtpVerificationNotifier, OtpVerificationState>(...);

// Email verification (OTP or Magic Link)
final emailVerificationProvider = StateNotifierProvider<EmailVerificationNotifier, EmailVerificationState>(...);

// Passkey setup/authentication
final passkeyProvider = StateNotifierProvider<PasskeyNotifier, PasskeyState>(...);

// Social login
final socialLoginProvider = StateNotifierProvider<SocialLoginNotifier, SocialLoginState>(...);

// User type selection (after login)
final userTypeProvider = StateProvider<String?>((ref) => null);
```

### Riverpod UseCases Needed

```
Domain Layer (Pure Dart):
- RequestOtpLoginUseCase ✅ (already exists)
- VerifyOtpLoginUseCase ✅ (already exists)
- RequestMagicLinkUseCase (new)
- VerifyMagicLinkUseCase (new)
- RegisterPasskeyUseCase (new)
- AuthenticateWithPasskeyUseCase (new)
- AuthenticateWithSocialUseCase (new)
```

---

## Implementation Priority

### **Phase 1** ✅ DONE
- Phone OTP login (complete)
- User type selection

### **Phase 2** 🔄 RECOMMENDED NEXT
- Sign-In Method Selection Screen (entry point)
- Email login with OTP
- Token persistence (flutter_secure_storage)
- Auth guard in GoRouter

### **Phase 3** 📌 OPTIONAL
- Email login with Magic Link
- Passkey Face ID setup
- Passkey Fingerprint setup

### **Phase 4** 📌 OPTIONAL
- Apple OAuth integration
- Google OAuth integration
- Facebook OAuth integration

### **Phase 5** 📌 OPTIONAL
- Advanced features:
  - Remember me / biometric on return
  - Multiple login methods per account
  - Account linking
  - Social login with existing email

---

## What Changes from Current Implementation

### ✅ Keep As-Is
- Phone OTP login (LoginScreen, OtpScreen)
- OTP verification logic
- User type selection
- Design tokens
- State management pattern (StateNotifier)

### 🔄 Modify
- **AppRouter**: Change initial route from `/login` to `/signin-method`
- **Navigation**: Add routes for all auth methods

### ➕ Add
- SignInMethodSelectionScreen (entry point)
- EmailLoginScreen
- PasskeySetupFaceScreen
- PasskeySetupFingerprintScreen
- MagicLinkVerificationScreen
- SocialLoginCallbackHandler
- New UseCases (email, passkey, social)
- New Notifiers (email, passkey, social)
- OAuth callbacks (Apple, Google, Facebook)

---

## Design Token Updates Needed

From Email spec:
```
Radio List Item:
- Fill: #18181B
- Border-radius: 8px
- Text-title: #FFF (14px 400)
- Text-description: #9F9FA9 (12px 400)
- Icon default: #71717B
- Icon checked: #2ECC71

Info Container (for "How it works"):
- Fill: #052F4A (dark blue)
- Border-radius: 16px
- Icon fill: #B8E6FE (light blue)
- Text: #B8E6FE (14px 600)
```

---

## Summary: What Was Missed

You were right! The initial implementation only covered **1 out of 6** sign-in methods:

| Method | Status | Notes |
|--------|--------|-------|
| Phone (OTP) | ✅ Done | Complete flow |
| Email (OTP/Magic Link) | ❌ Missing | 2 sub-flows |
| Passkey (Face/Fingerprint) | ❌ Missing | 2 setup flows |
| Apple OAuth | ❌ Missing | OAuth callback |
| Google OAuth | ❌ Missing | OAuth callback |
| Facebook OAuth | ❌ Missing | OAuth callback |
| **Sign-In Method Selection** | ❌ Critical Missing! | Entry point! |

The **Sign-In Method Selection Screen** is critical - it should be the first screen users see, not the phone login screen directly.

---

## Next Steps

1. **Create SignInMethodSelectionScreen** (entry point)
   - Shows all 6 methods
   - Navigates to appropriate login flow
   - Route: `/signin-method` (new initial route)

2. **Create EmailLoginScreen**
   - Email input
   - OTP or Magic Link selection (radio buttons)
   - Navigate to OtpScreen or MagicLinkVerificationScreen

3. **Create PasskeyScreens** (2 variants)
   - PasskeySetupFaceScreen
   - PasskeySetupFingerprintScreen
   - Call native biometric APIs

4. **Wire Social Logins** (OAuth callbacks)
   - Create OAuth handlers
   - Implement deeplinks for OAuth callbacks
   - Handle token exchange

5. **Update Router**
   - Change initial route to `/signin-method`
   - Add routes for all new screens
   - Handle OAuth redirects

---

This is a **complete multi-method authentication system**, not just phone OTP. Ready to implement the full flow? 🔐
