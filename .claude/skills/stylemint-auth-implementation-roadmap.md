# Style Mint Auth Flow Implementation Roadmap

## Current Status ✅

**Phase 1 Complete: Auth UI + State Management**
- ✅ Design tokens extracted and organized
- ✅ LoginScreen (phone input with SmPhoneNumberField)
- ✅ OtpScreen (5-digit OTP verification)
- ✅ UserTypeSelectionScreen (customer/creator/vendor selection)
- ✅ StateNotifier-based state management (no initial loading state)
- ✅ API integration wired (requests → OtpScreen → UserTypeSelectionScreen)
- ✅ Routes configured (login → otp → user-type-selection → home)
- ✅ **Zero compilation errors** — ready for testing

---

## Phase 2: Token Persistence & Auth Guard (Next)

### Task 2.1: Implement Secure Token Storage

**What to do:**
```dart
// 1. Add flutter_secure_storage to pubspec.yaml
flutter_pub_add flutter_secure_storage

// 2. Create token storage service
// File: lib/core/storage/secure_token_storage.dart

class SecureTokenStorage {
  static const _accessTokenKey = 'auth_access_token';
  static const _refreshTokenKey = 'auth_refresh_token';
  static const _accountIdKey = 'auth_account_id';
  
  final _storage = const FlutterSecureStorage();
  
  // Save tokens after successful login
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
    required String accountId,
  }) async {
    await Future.wait([
      _storage.write(key: _accessTokenKey, value: accessToken),
      _storage.write(key: _refreshTokenKey, value: refreshToken),
      _storage.write(key: _accountIdKey, value: accountId),
    ]);
  }
  
  // Retrieve tokens on app start
  Future<TokenData?> getTokens() async {
    final accessToken = await _storage.read(key: _accessTokenKey);
    final refreshToken = await _storage.read(key: _refreshTokenKey);
    final accountId = await _storage.read(key: _accountIdKey);
    
    if (accessToken == null || refreshToken == null || accountId == null) {
      return null;
    }
    
    return TokenData(
      accessToken: accessToken,
      refreshToken: refreshToken,
      accountId: accountId,
    );
  }
  
  // Clear tokens on logout
  Future<void> clearTokens() async {
    await Future.wait([
      _storage.delete(key: _accessTokenKey),
      _storage.delete(key: _refreshTokenKey),
      _storage.delete(key: _accountIdKey),
    ]);
  }
}

class TokenData {
  final String accessToken;
  final String refreshToken;
  final String accountId;
  
  TokenData({
    required this.accessToken,
    required this.refreshToken,
    required this.accountId,
  });
}
```

**Verification:**
- [ ] flutter_secure_storage added to pubspec.yaml
- [ ] SecureTokenStorage class created in lib/core/storage/
- [ ] Methods: saveTokens(), getTokens(), clearTokens()
- [ ] Data encrypted at rest on device

---

### Task 2.2: Wire Token Saving to UserTypeSelectionScreen

**What to do:**
```dart
// In lib/features/auth/presentation/screens/user_type_selection_screen.dart

class _UserTypeSelectionScreenState
    extends ConsumerState<UserTypeSelectionScreen> {
  
  void _handleContinue() async {
    if (selectedUserType == null) {
      SmSnackbar.warning(context, 'Please select a user type to continue');
      return;
    }

    // ✅ NEW: Save tokens to secure storage
    final tokenStorage = SecureTokenStorage();
    await tokenStorage.saveTokens(
      accessToken: widget.authData.accessToken ?? '',
      refreshToken: widget.authData.refreshToken ?? '',
      accountId: widget.authData.accountId,
    );

    // Save user role for later use
    // TODO: Implement user role persistence (SharedPreferences or Riverpod)

    // Navigate to appropriate home screen
    String homeRoute = RouteNames.home;
    if (selectedUserType == 'creator') {
      homeRoute = RouteNames.creatorHome;
    } else if (selectedUserType == 'vendor') {
      homeRoute = RouteNames.vendorHome;
    }

    context.go(homeRoute);
  }
}
```

**Verification:**
- [ ] Tokens saved after user type selection
- [ ] SecureTokenStorage imported
- [ ] saveTokens() called with accountId + tokens from authData
- [ ] Navigation still works

---

### Task 2.3: Add Bearer Token to All API Requests

**What to do:**
```dart
// In lib/core/network/dio_client.dart or wherever Dio is configured

class DioClientProvider {
  static Dio createDio() {
    final dio = Dio(
      BaseOptions(
        baseUrl: 'http://localhost:5020',
        connectTimeout: const Duration(seconds: 5),
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // ✅ NEW: Add auth interceptor
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Get stored access token
          final tokenStorage = SecureTokenStorage();
          final tokenData = await tokenStorage.getTokens();
          
          if (tokenData != null) {
            options.headers['Authorization'] = 'Bearer ${tokenData.accessToken}';
          }
          
          return handler.next(options);
        },
        onError: (error, handler) {
          // TODO: Handle 401 Unauthorized → refresh token
          return handler.next(error);
        },
      ),
    );

    // Existing interceptors...
    
    return dio;
  }
}
```

**Verification:**
- [ ] Interceptor added to Dio client
- [ ] Access token retrieved from SecureTokenStorage
- [ ] Authorization header set to `Bearer <accessToken>`
- [ ] All API requests include the header
- [ ] Test with Network DevTools

---

### Task 2.4: Implement Token Refresh Logic

**What to do:**
```dart
// In lib/features/auth/data/datasources/auth_remote_datasource.dart

class AuthRemoteDataSource {
  // ... existing code ...
  
  /// Refresh access token when expired
  Future<AuthResponseDto> refreshToken({
    required String refreshToken,
  }) async {
    final response = await apiClient.post(
      '/v1/auth/refresh-token',
      data: {
        'refreshToken': refreshToken,
      },
    );
    
    return AuthResponseDto.fromJson(response);
  }
}

// In lib/features/auth/domain/usecases/refresh_token_usecase.dart

class RefreshTokenParams {
  final String refreshToken;
  
  RefreshTokenParams({required this.refreshToken});
}

class RefreshTokenUseCase implements UseCase<AuthResponseDto, RefreshTokenParams> {
  final AuthRepository repository;
  
  RefreshTokenUseCase({required this.repository});
  
  @override
  Future<Either<Failure, AuthResponseDto>> call(RefreshTokenParams params) {
    return repository.refreshToken(refreshToken: params.refreshToken);
  }
}

// In lib/core/network/dio_client.dart interceptor

onError: (error, handler) async {
  // If 401 Unauthorized, try to refresh token
  if (error.response?.statusCode == 401) {
    try {
      final tokenStorage = SecureTokenStorage();
      final tokenData = await tokenStorage.getTokens();
      
      if (tokenData != null) {
        // Refresh the token
        final newTokenResponse = await authDataSource.refreshToken(
          refreshToken: tokenData.refreshToken,
        );
        
        // Save new tokens
        await tokenStorage.saveTokens(
          accessToken: newTokenResponse.accessToken ?? '',
          refreshToken: newTokenResponse.refreshToken ?? '',
          accountId: newTokenResponse.accountId,
        );
        
        // Retry original request with new token
        final options = error.requestOptions;
        options.headers['Authorization'] = 'Bearer ${newTokenResponse.accessToken}';
        
        return handler.resolve(await dio.request(
          options.path,
          options: options,
        ));
      }
    } catch (e) {
      // Refresh failed → logout user
      await tokenStorage.clearTokens();
      // TODO: Navigate to login screen
    }
  }
  
  return handler.next(error);
},
```

**Verification:**
- [ ] RefreshTokenUseCase created
- [ ] /v1/auth/refresh-token endpoint implemented
- [ ] 401 handling in Dio interceptor
- [ ] Tokens updated after refresh
- [ ] Original request retried with new token
- [ ] Logout triggered if refresh fails

---

### Task 2.5: Implement Auth Guard in Routes

**What to do:**
```dart
// In lib/routes/app_router.dart

@riverpod
GoRouter appRouter(Ref ref) {
  return GoRouter(
    initialLocation: RouteNames.login,
    debugLogDiagnostics: true,
    routes: [
      // ... existing routes ...
    ],
    redirect: (context, state) async {
      // Check if user is logged in
      final tokenStorage = SecureTokenStorage();
      final tokenData = await tokenStorage.getTokens();
      
      final isLoggedIn = tokenData != null;
      final isOnAuthPath = state.uri.path == RouteNames.login ||
          state.uri.path == RouteNames.otp ||
          state.uri.path == RouteNames.userTypeSelection;
      
      if (!isLoggedIn && !isOnAuthPath) {
        // Not logged in and trying to access protected route → redirect to login
        return RouteNames.login;
      }
      
      if (isLoggedIn && isOnAuthPath) {
        // Already logged in and trying to access auth routes → redirect to home
        return RouteNames.home;
      }
      
      return null;  // Allow navigation
    },
  );
}
```

**Verification:**
- [ ] redirect() implemented in GoRouter
- [ ] Checks for stored tokens
- [ ] Redirects to login if not authenticated
- [ ] Redirects to home if already authenticated
- [ ] Test: try navigating to /checkout without logging in → should redirect to /login
- [ ] Test: after login, manually go to /login → should redirect to /home

---

## Phase 3: Sign-In Method Selection Screen (Optional Enhancement)

### Task 3.1: Create Sign-In Method Screen

**What to do:**
```
Before showing LoginScreen (phone input), show a screen with options:

1. "Continue with Phone" → LoginScreen
2. "Continue with Email" → EmailLoginScreen (future)
3. "Continue with Passkey" → PasskeyLoginScreen (future)
4. "Continue with Apple" → AppleLoginScreen (future)
5. "Continue with Google" → GoogleLoginScreen (future)
6. "Continue with Facebook" → FacebookLoginScreen (future)

For now:
- Create SignInMethodScreen with mockups of all methods
- Only "Phone" is functional
- Others show "Coming soon"
```

**Implementation:**
```dart
// lib/features/auth/presentation/screens/signin_method_screen.dart

class SignInMethodScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const SmAppBar(title: 'Sign In'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(DesignTokens.appHorizontalPadding),
        child: Column(
          children: [
            Text('Choose how to sign in', style: DesignTokens.h2),
            const SizedBox(height: DesignTokens.s32),
            
            // Phone option (active)
            _buildMethodOption(
              icon: Icons.phone,
              title: 'Phone Number',
              subtitle: 'Quick and secure',
              onTap: () => context.push(RouteNames.login),
            ),
            
            // Email option (coming soon)
            _buildMethodOption(
              icon: Icons.email,
              title: 'Email',
              subtitle: 'Coming soon',
              enabled: false,
            ),
            
            // Passkey option (coming soon)
            _buildMethodOption(
              icon: Icons.fingerprint,
              title: 'Passkey',
              subtitle: 'Coming soon',
              enabled: false,
            ),
            
            // Social logins
            Text('Or continue with', style: DesignTokens.body),
            const SizedBox(height: DesignTokens.s16),
            
            Row(
              children: [
                Expanded(child: _buildSocialButton('Apple')),
                const SizedBox(width: DesignTokens.s16),
                Expanded(child: _buildSocialButton('Google')),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildMethodOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback? onTap,
    bool enabled = true,
  }) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        padding: const EdgeInsets.all(DesignTokens.s16),
        margin: const EdgeInsets.only(bottom: DesignTokens.s12),
        decoration: BoxDecoration(
          border: Border.all(
            color: enabled ? DesignTokens.borderDefault : DesignTokens.textMuted,
          ),
          borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
        ),
        child: Row(
          children: [
            Icon(icon, color: enabled ? DesignTokens.primaryGreen : DesignTokens.textMuted),
            const SizedBox(width: DesignTokens.s16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: DesignTokens.body),
                  Text(subtitle, style: DesignTokens.small),
                ],
              ),
            ),
            Icon(Icons.arrow_forward, color: DesignTokens.textMuted),
          ],
        ),
      ),
    );
  }
}
```

**Verification:**
- [ ] Screen shows all sign-in methods
- [ ] Phone option is functional (navigates to LoginScreen)
- [ ] Other options show "Coming soon" state
- [ ] Route is `/signin-method` or similar
- [ ] Router redirects to this screen before login if needed

---

## Phase 4: Resend OTP Functionality

### Task 4.1: Implement Resend OTP

**What to do:**
```dart
// In OtpScreen

class _OtpScreenState extends ConsumerState<OtpScreen> {
  int _resendCountdown = 0;
  late Timer _resendTimer;
  
  @override
  void initState() {
    super.initState();
    _startResendCountdown();
  }
  
  void _startResendCountdown() {
    _resendCountdown = 60;  // 60 seconds
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _resendCountdown--;
      });
      if (_resendCountdown == 0) {
        timer.cancel();
      }
    });
  }
  
  Future<void> _handleResendOtp() async {
    if (_resendCountdown > 0) return;  // Prevent spam
    
    // Call resend API
    await ref.read(otpRequestProvider.notifier).requestOtp(
      identifierType: 'phone',
      identifier: widget.phone,
    );
    
    // Check result
    await Future.delayed(const Duration(milliseconds: 100));
    if (mounted) {
      final otpState = ref.read(otpRequestProvider);
      if (otpState.isSuccess) {
        SmSnackbar.success(context, 'OTP resent to your phone');
        _startResendCountdown();
      } else if (otpState.hasError) {
        SmSnackbar.error(context, 'Failed to resend OTP');
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ... existing code ...
      body: Column(
        children: [
          // ... existing OTP input ...
          
          // Resend code section
          Center(
            child: Column(
              children: [
                Text('Did not receive code?', style: DesignTokens.body),
                const SizedBox(height: DesignTokens.s8),
                GestureDetector(
                  onTap: _resendCountdown == 0 ? _handleResendOtp : null,
                  child: Text(
                    _resendCountdown > 0
                        ? 'Resend Code (${_resendCountdown}s)'
                        : 'Resend Code',
                    style: DesignTokens.body.copyWith(
                      color: _resendCountdown == 0
                          ? DesignTokens.primaryGreen
                          : DesignTokens.textMuted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  @override
  void dispose() {
    _resendTimer.cancel();
    super.dispose();
  }
}
```

**Verification:**
- [ ] Resend button appears after 60 second countdown
- [ ] Resend calls `/v1/auth/login-otp/request` again
- [ ] Success message shown on resend
- [ ] Error message shown if resend fails
- [ ] Countdown prevents spam (can't resend immediately)
- [ ] Timer disposed on screen close

---

## Phase 5: Home Screen Placeholders

### Task 5.1: Create Role-Specific Home Screens

**What to do:**
```dart
// lib/features/home/presentation/screens/customer_home_screen.dart
class CustomerHomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const SmAppBar(title: 'Discover'),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.shopping_bag, size: 48),
            const SizedBox(height: 16),
            const Text('Customer Home'),
            const SizedBox(height: 32),
            SmPrimaryButton(
              label: 'Logout',
              onPressed: () {
                // TODO: Implement logout
              },
            ),
          ],
        ),
      ),
    );
  }
}

// lib/features/home/presentation/screens/creator_home_screen.dart
class CreatorHomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const SmAppBar(title: 'Creator Dashboard'),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.video_camera_back, size: 48),
            const SizedBox(height: 16),
            const Text('Creator Home'),
            const SizedBox(height: 32),
            SmPrimaryButton(
              label: 'Logout',
              onPressed: () {
                // TODO: Implement logout
              },
            ),
          ],
        ),
      ),
    );
  }
}

// lib/features/home/presentation/screens/vendor_home_screen.dart
class VendorHomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const SmAppBar(title: 'Vendor Dashboard'),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.store, size: 48),
            const SizedBox(height: 16),
            const Text('Vendor Home'),
            const SizedBox(height: 32),
            SmPrimaryButton(
              label: 'Logout',
              onPressed: () {
                // TODO: Implement logout
              },
            ),
          ],
        ),
      ),
    );
  }
}
```

**Update routes:**
```dart
// In lib/routes/app_router.dart

GoRoute(
  path: RouteNames.home,
  builder: (ctx, state) => const CustomerHomeScreen(),
),
GoRoute(
  path: RouteNames.creatorHome,
  builder: (ctx, state) => const CreatorHomeScreen(),
),
GoRoute(
  path: RouteNames.vendorHome,
  builder: (ctx, state) => const VendorHomeScreen(),
),
```

**Verification:**
- [ ] All three home screens created
- [ ] Routes point to correct home based on role
- [ ] Logout button present (implement in Task 5.2)
- [ ] Navigation works: UserTypeSelectionScreen → appropriate home

---

### Task 5.2: Implement Logout

**What to do:**
```dart
// In lib/features/auth/domain/usecases/logout_usecase.dart

class LogoutUseCase implements UseCase<void, NoParams> {
  final SecureTokenStorage _tokenStorage;
  
  LogoutUseCase({required SecureTokenStorage tokenStorage})
      : _tokenStorage = tokenStorage;
  
  @override
  Future<Either<Failure, void>> call(NoParams params) async {
    try {
      await _tokenStorage.clearTokens();
      return right(null);
    } catch (e) {
      return left(CacheFailure('Failed to logout'));
    }
  }
}

// In app_router.dart redirect()

redirect: (context, state) async {
  final tokenStorage = SecureTokenStorage();
  final tokenData = await tokenStorage.getTokens();
  
  final isLoggedIn = tokenData != null;
  final isOnAuthPath = state.uri.path == RouteNames.login || ...;
  
  // If tokens were cleared (logout), redirect to login
  if (!isLoggedIn && !isOnAuthPath && state.uri.path != RouteNames.login) {
    return RouteNames.login;
  }
  
  return null;
},

// In home screens

SmPrimaryButton(
  label: 'Logout',
  onPressed: () async {
    await ref.read(logoutUsecaseProvider).call(NoParams());
    if (context.mounted) {
      context.go(RouteNames.login);
    }
  },
),
```

**Verification:**
- [ ] Logout clears tokens from SecureTokenStorage
- [ ] App redirects to login after logout
- [ ] Can login again after logout
- [ ] No cached data from previous session visible

---

## Testing Checklist

### Phase 1 Testing ✅ (Already done)
- [x] App compiles with zero errors
- [x] All auth screens render without errors
- [x] Navigation between screens works

### Phase 2 Testing (Token Persistence)
- [ ] Run app → login → close app → reopen → should be logged in (not show login)
- [ ] Tokens stored in secure storage (use DevTools to verify)
- [ ] API requests include `Authorization: Bearer <token>` header
- [ ] Manually delete tokens → app redirects to login

### Phase 3 Testing (Auth Guard)
- [ ] Try accessing /checkout without logging in → redirected to /login
- [ ] After login, manually navigate to /login → redirected to /home
- [ ] Auth guard logs user state in console

### Phase 4 Testing (Token Refresh)
- [ ] Manually expire access token
- [ ] Make API request → should refresh token automatically
- [ ] Request succeeds with new token
- [ ] If refresh fails, logged out and redirected to login

### Phase 5 Testing (Complete Flow)
- [ ] Phone login → OTP → User type selection → Home (role-specific)
- [ ] Each step shows correct loading/error states
- [ ] Logout from home → redirected to login
- [ ] Can login again after logout

---

## Timeline

| Phase | Tasks | Est. Time | Status |
|-------|-------|-----------|--------|
| 1 | UI + State + Routes | ✅ Done | Complete |
| 2 | Token Storage + Auth Guard | ~4 hours | Next |
| 3 | Sign-in Methods | ~2 hours | Optional |
| 4 | Resend OTP | ~1 hour | Optional |
| 5 | Home Screens + Logout | ~1 hour | Optional |

**Total remaining: ~8 hours (all optional tasks included)**

---

## Critical Verification

Before moving to next phase:
- [ ] **Phase 2.5**: Try accessing protected route without login → redirects to /login
- [ ] **Phase 2.5**: After login, try accessing /login → redirects to /home
- [ ] **Phase 2.2**: Auth tokens saved to secure storage
- [ ] **Phase 2.3**: Authorization header includes Bearer token in all requests
- [ ] **Phase 5**: Logout clears tokens and redirects to login

If all pass → ready for Phase 3+

---

## Reference

- **Full design extraction skill**: `/design-extraction-and-review.md`
- **Quick design reference**: `/design-extraction-quick-reference.md`
- **Frontend skill**: Use the `stylemint-mobile-frontend` skill for any Flutter-specific questions
- **Current auth implementation**: `lib/features/auth/` folder
