// Development harness — launches CreatorDashboardScreen with mock data.
//
// Run with:
//   flutter run -t lib/main_dev.dart
//
// No login, no backend, no Firebase required.

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/core/auth/jwt_roles.dart';
import 'package:stylemint_mobile_frontend/core/network/api_client.dart';
import 'package:stylemint_mobile_frontend/core/network/dio_client.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/core/utils/format_date.dart';
import 'package:stylemint_mobile_frontend/features/creator/dashboard/domain/entities/creator_dashboard.dart';
import 'package:stylemint_mobile_frontend/features/creator/dashboard/domain/repositories/creator_dashboard_repository.dart';
import 'package:stylemint_mobile_frontend/features/creator/dashboard/presentation/screens/creator_dashboard_screen.dart';
import 'package:stylemint_mobile_frontend/features/creator/dashboard/presentation/screens/top_reels_screen.dart';
import 'package:stylemint_mobile_frontend/features/notifications/presentation/screens/recent_activity_screen.dart';
import 'package:stylemint_mobile_frontend/features/creator/dashboard/shared/providers.dart';
import 'package:stylemint_mobile_frontend/features/creator/apply/presentation/screens/creator_apply_screen.dart';
import 'package:stylemint_mobile_frontend/features/creator/earnings/domain/entities/earnings.dart';
import 'package:stylemint_mobile_frontend/features/creator/earnings/domain/repositories/earnings_repository.dart';
import 'package:stylemint_mobile_frontend/features/creator/earnings/presentation/screens/earnings_screen.dart';
import 'package:stylemint_mobile_frontend/features/creator/earnings/presentation/screens/payout_screen.dart';
import 'package:stylemint_mobile_frontend/features/creator/earnings/presentation/screens/add_payment_method_screen.dart';
import 'package:stylemint_mobile_frontend/features/creator/earnings/presentation/screens/bank_verification_screen.dart';
import 'package:stylemint_mobile_frontend/features/creator/earnings/presentation/screens/all_payout_history_screen.dart';
import 'package:stylemint_mobile_frontend/features/creator/earnings/presentation/screens/payout_invoice_screen.dart';
import 'package:stylemint_mobile_frontend/features/creator/earnings/shared/providers.dart';
import 'package:stylemint_mobile_frontend/features/creator/partnerships/presentation/screens/active_partnerships_screen.dart';
import 'package:stylemint_mobile_frontend/features/creator/partnerships/presentation/screens/brand_detail_screen.dart';
import 'package:stylemint_mobile_frontend/features/creator/partnerships/presentation/screens/brand_info_screen.dart';
import 'package:stylemint_mobile_frontend/features/creator/partnerships/presentation/screens/partnership_apply_screen.dart';
import 'package:stylemint_mobile_frontend/features/creator/partnerships/presentation/screens/partnership_requests_screen.dart';
import 'package:stylemint_mobile_frontend/features/creator/partnerships/presentation/screens/brands_screen.dart';
import 'package:stylemint_mobile_frontend/features/creator/reel_import/domain/entities/imported_reel.dart';
import 'package:stylemint_mobile_frontend/features/creator/reel_import/domain/repositories/reel_import_repository.dart';
import 'package:stylemint_mobile_frontend/features/creator/reel_import/presentation/screens/import_reel_screen.dart';
import 'package:stylemint_mobile_frontend/features/creator/reel_import/presentation/screens/preview_reel_screen.dart';
import 'package:stylemint_mobile_frontend/features/creator/reel_import/presentation/screens/tag_products_screen.dart';
import 'package:stylemint_mobile_frontend/features/creator/reel_import/presentation/screens/reel_published_screen.dart';
import 'package:stylemint_mobile_frontend/features/creator/reel_import/presentation/screens/review_reel_screen.dart';
import 'package:stylemint_mobile_frontend/features/creator/reel_import/shared/providers.dart';
import 'package:stylemint_mobile_frontend/features/creator/social_connect/domain/entities/social_account.dart';
import 'package:stylemint_mobile_frontend/features/creator/analytics/presentation/screens/analytics_screen.dart';
import 'package:stylemint_mobile_frontend/features/creator/analytics/presentation/screens/reel_detail_analytics_screen.dart';
import 'package:stylemint_mobile_frontend/features/creator/analytics/presentation/screens/full_analytics_report_screen.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/presentation/screens/search_screen.dart';
import 'package:stylemint_mobile_frontend/features/social/creator_profile/presentation/creator_edit_profile_screen.dart';
import 'package:stylemint_mobile_frontend/features/social/creator_profile/presentation/creator_profile_screen.dart';
import 'package:stylemint_mobile_frontend/features/auth/presentation/screens/change_password_screen.dart';
import 'package:stylemint_mobile_frontend/features/social/creator_profile/presentation/edit_category_niche_screen.dart';
import 'package:stylemint_mobile_frontend/features/social/creator_profile/presentation/upgrade_subscription_screen.dart';
import 'package:stylemint_mobile_frontend/features/social/creator_profile/presentation/edit_profile_badges_screen.dart';
import 'package:stylemint_mobile_frontend/features/social/creator_profile/presentation/profile_settings_screen.dart';
import 'package:stylemint_mobile_frontend/features/notifications/domain/entities/activity_item.dart';
import 'package:stylemint_mobile_frontend/features/notifications/domain/repositories/notifications_repository.dart';
import 'package:stylemint_mobile_frontend/features/notifications/shared/providers.dart';
import 'package:stylemint_mobile_frontend/features/profile/presentation/screens/edit_profile_screen.dart';
import 'package:stylemint_mobile_frontend/features/profile/presentation/screens/profile_screen.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';
import 'package:stylemint_mobile_frontend/theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  initTimezone();

  runApp(
    ProviderScope(
      overrides: [
        // Return true without reading a JWT so no token storage is touched.
        isCreatorProvider.overrideWith((ref) async => true),
        // Serve mock partnership data so BrandDetailScreen loads and the
        // Apply button becomes active without a real backend.
        apiClientProvider.overrideWithValue(_MockApiClient()),
        // Serve mock dashboard data — no Dio / network needed.
        creatorDashboardRepositoryProvider.overrideWithValue(
          _MockCreatorDashboardRepository(),
        ),
        // Serve mock activity feed — no Dio / network needed.
        notificationsRepositoryProvider.overrideWithValue(
          _MockNotificationsRepository(),
        ),
        // Serve mock earnings data for the payout screen.
        earningsRepositoryProvider.overrideWithValue(
          _MockEarningsRepository(),
        ),
        // Serve mock reel import data — no social API needed.
        reelImportRepositoryProvider.overrideWithValue(
          _MockReelImportRepository(),
        ),
      ],
      child: const _DevApp(),
    ),
  );
}

// ── Mock repositories ─────────────────────────────────────────────────────────

class _MockCreatorDashboardRepository implements CreatorDashboardRepository {
  @override
  Future<Either<NetworkExceptions, CreatorDashboard>> getDashboard() async =>
      right(
        CreatorDashboard(
          earnings: const Money(amount: 24500.00, currency: 'NPR'),
          earningsDeltaPercent: 12.5,
          pendingBalance: const Money(amount: 5200.00, currency: 'NPR'),
          totalSales: 34,
          totalViews: 128400,
          topReels: [
            CreatorReel(
              id: '1',
              title: 'Summer Fashion Haul 2025',
              thumbnailUrl: '',
              publishedAt: DateTime.now().subtract(const Duration(days: 3)),
              views: 45200,
              likes: 3100,
              comments: 210,
              shares: 88,
            ),
            CreatorReel(
              id: '2',
              title: 'Top 5 Tech Gadgets Under Rs 5000',
              thumbnailUrl: '',
              publishedAt: DateTime.now().subtract(const Duration(days: 7)),
              views: 83200,
              likes: 6700,
              comments: 450,
              shares: 312,
            ),
          ],
        ),
      );
}

class _MockEarningsRepository implements EarningsRepository {
  @override
  Future<Either<NetworkExceptions, EarningsSummary>> getSummary() async =>
      right(
        EarningsSummary(
          totalEarnings: const Money(amount: 24500.00, currency: 'NPR'),
          availableBalance: const Money(amount: 12589.98, currency: 'NPR'),
          pendingBalance: const Money(amount: 12589.98, currency: 'NPR'),
          totalCommission: 2.0,
          thisMonthEarnings: const Money(amount: 8200.00, currency: 'NPR'),
          totalPayouts: const Money(amount: 5000.00, currency: 'NPR'),
        ),
      );

  @override
  Future<Either<NetworkExceptions, List<EarningsLedgerEntry>>> getLedger({
    int limit = 20,
    String? cursor,
  }) async =>
      right([
        EarningsLedgerEntry(
          id: 'p1',
          type: LedgerEntryType.payout,
          description: 'Payout to Bank A/C',
          amount: const Money(amount: 12500, currency: 'NPR'),
          createdAt: DateTime.now().subtract(const Duration(days: 1)),
          reference: '********1268',
        ),
        EarningsLedgerEntry(
          id: 'p2',
          type: LedgerEntryType.payout,
          description: 'Payout to Esewa Wallet',
          amount: const Money(amount: 17000, currency: 'NPR'),
          createdAt: DateTime.now().subtract(const Duration(days: 3)),
          reference: '********22',
        ),
        EarningsLedgerEntry(
          id: 'p3',
          type: LedgerEntryType.payout,
          description: 'Payout to Bank A/C',
          amount: const Money(amount: 10985.89, currency: 'NPR'),
          createdAt: DateTime.now().subtract(const Duration(days: 7)),
          reference: '********4566',
        ),
      ]);

  @override
  Future<Either<NetworkExceptions, List<PayoutMethod>>> getPayoutMethods() async =>
      right([
        const PayoutMethod(
          id: 'bank-1',
          type: PayoutMethodType.bankTransfer,
          label: 'NIMB Bank a/c — ****8909',
          isPrimary: false,
        ),
        const PayoutMethod(
          id: 'bank-2',
          type: PayoutMethodType.bankTransfer,
          label: 'Laxmi Bank a/c — ****7787',
          isPrimary: false,
        ),
        const PayoutMethod(
          id: 'paypal-1',
          type: PayoutMethodType.paypal,
          label: 'Paypal — @shreeteen123',
          isPrimary: true,
        ),
        const PayoutMethod(
          id: 'esewa-1',
          type: PayoutMethodType.esewa,
          label: 'eSewa — 9840098522',
          isPrimary: false,
        ),
      ]);

  @override
  Future<Either<NetworkExceptions, Unit>> requestPayout({
    required Money amount,
    required String payoutMethodId,
  }) async =>
      right(unit);

  @override
  Future<Either<NetworkExceptions, Unit>> addBankPayoutMethod({
    required int kind,
    required String label,
    String? maskedAccountNumber,
    String? beneficiaryName,
    String? processorReference,
  }) async =>
      right(unit);

  @override
  Future<Either<NetworkExceptions, Unit>> addExternalWalletPayoutMethod({
    required int kind,
    required String label,
    String? externalIdentifier,
    String? processorReference,
  }) async =>
      right(unit);

  @override
  Future<Either<NetworkExceptions, Unit>> removePayoutMethod(
    String methodId,
  ) async =>
      right(unit);

  @override
  Future<Either<NetworkExceptions, List<PayoutRecord>>> getPayouts({
    int pageSize = 25,
    String? cursor,
  }) async =>
      right([
        PayoutRecord(
          id: 'pay-001',
          requestedAmount: const Money(amount: 17000, currency: 'NPR'),
          feeAmount: const Money(amount: 340, currency: 'NPR'),
          netAmount: const Money(amount: 16660, currency: 'NPR'),
          state: PayoutState.paid,
          mode: PayoutMode.onDemand,
          destinationLabel: 'eSewa',
          destinationRef: '9840098522',
          requestedAt: DateTime.now().subtract(const Duration(days: 1)),
          paidAt: DateTime.now().subtract(const Duration(hours: 10)),
        ),
        PayoutRecord(
          id: 'pay-002',
          requestedAmount: const Money(amount: 12500, currency: 'NPR'),
          feeAmount: const Money(amount: 0, currency: 'NPR'),
          netAmount: const Money(amount: 12500, currency: 'NPR'),
          state: PayoutState.requested,
          mode: PayoutMode.automaticWeekly,
          destinationLabel: 'NIMB Bank',
          destinationRef: '****8909',
          requestedAt: DateTime.now().subtract(const Duration(days: 3)),
        ),
      ]);

  @override
  Future<Either<NetworkExceptions, PayoutInvoice>> getPayoutInvoice(
    String payoutId,
  ) async =>
      right(
        PayoutInvoice(
          payoutId: payoutId,
          invoiceNumber: 'INV-0001',
          destinationLabel: 'eSewa',
          destinationRef: '9840098522',
          grossAmount: const Money(amount: 17000, currency: 'NPR'),
          feeAmount: const Money(amount: 340, currency: 'NPR'),
          netAmount: const Money(amount: 16660, currency: 'NPR'),
          requestedAt: DateTime.now().subtract(const Duration(days: 1)),
          paidAt: DateTime.now().subtract(const Duration(hours: 10)),
          state: PayoutState.paid,
          lines: [
            PayoutInvoiceLine(
              description: 'Commission — order #NK2024-8912',
              amount: const Money(amount: 17000, currency: 'NPR'),
              occurredAt:
                  DateTime.now().subtract(const Duration(days: 2)),
            ),
          ],
        ),
      );

  @override
  Future<Either<NetworkExceptions, Unit>> cancelPayout(
    String payoutId,
  ) async =>
      right(unit);
}

class _MockNotificationsRepository implements NotificationsRepository {
  @override
  Future<Either<NetworkExceptions, List<ActivityItem>>> getRecentActivity({
    int pageSize = 10,
  }) async =>
      right([
        ActivityItem(
          id: '1',
          title: 'Earnings +Rs 5,525.00 — Commission from order #NK2024-8912',
          occurredAt: DateTime.now().subtract(const Duration(hours: 2)),
          isRead: false,
        ),
        ActivityItem(
          id: '2',
          title: 'Reel Published — "Winter Fashion Trends 2026" · 1.2k views',
          occurredAt: DateTime.now().subtract(const Duration(hours: 5)),
          isRead: true,
        ),
        ActivityItem(
          id: '3',
          title: 'Partnership Request — Nike wants to collaborate with you',
          occurredAt: DateTime.now().subtract(const Duration(hours: 8)),
          isRead: false,
        ),
        ActivityItem(
          id: '4',
          title: 'Milestone Achieved — You reached 10k followers!',
          occurredAt: DateTime.now().subtract(const Duration(days: 1, hours: 1)),
          isRead: true,
        ),
        ActivityItem(
          id: '5',
          title: 'Earnings +Rs 17,899.90 — 15 orders from your reels',
          occurredAt: DateTime.now().subtract(const Duration(days: 1, hours: 14)),
          isRead: true,
        ),
        ActivityItem(
          id: '6',
          title: 'Payout Completed — Rs 1,33,890.91 sent to NIMB Bank a/c ******3458',
          occurredAt: DateTime.now().subtract(const Duration(days: 2)),
          isRead: true,
        ),
        ActivityItem(
          id: '7',
          title: 'Reel Imported — "Top Picks: Monsoon Collection" is live',
          occurredAt: DateTime.now().subtract(const Duration(days: 2, hours: 3)),
          isRead: true,
        ),
        ActivityItem(
          id: '8',
          title: 'Brand Partnership — StyleCo campaign approved',
          occurredAt: DateTime.now().subtract(const Duration(days: 3)),
          isRead: true,
        ),
      ]);
}

class _MockReelImportRepository implements ReelImportRepository {
  @override
  Future<Either<NetworkExceptions, List<ImportableReel>>> getImportableReels(
    SocialPlatform platform,
  ) async =>
      right([
        ImportableReel(
          id: '1',
          platform: platform,
          platformPostId: 'post-1',
          sourceUrl: '',
          thumbnailUrl: '',
          caption: 'Summer Fashion Haul 2025 ☀️ #fashion #stylemint',
          createdAt: DateTime.now().subtract(const Duration(days: 2)),
          videoDuration: 45,
        ),
        ImportableReel(
          id: '2',
          platform: platform,
          platformPostId: 'post-2',
          sourceUrl: '',
          thumbnailUrl: '',
          caption: 'Top 5 Tech Gadgets Under Rs 5000 🔥 #tech #gadgets',
          createdAt: DateTime.now().subtract(const Duration(days: 5)),
          videoDuration: 62,
        ),
        ImportableReel(
          id: '3',
          platform: platform,
          platformPostId: 'post-3',
          sourceUrl: '',
          thumbnailUrl: '',
          caption: 'Monsoon Collection Picks 🌧️ #monsoon #fashion',
          createdAt: DateTime.now().subtract(const Duration(days: 8)),
          videoDuration: 38,
        ),
        ImportableReel(
          id: '4',
          platform: platform,
          platformPostId: 'post-4',
          sourceUrl: '',
          thumbnailUrl: '',
          caption: 'Winter Wardrobe Essentials ❄️ #winter #style',
          createdAt: DateTime.now().subtract(const Duration(days: 12)),
          videoDuration: 55,
        ),
      ]);

  @override
  Future<Either<NetworkExceptions, ImportedReel>> importReel(
    ImportableReel reel,
  ) async =>
      right(
        ImportedReel(
          id: 'imported-${reel.platformPostId}',
          status: ImportStatus.processing,
          reelReelId: 'reel-${reel.platformPostId}',
          tags: const [],
          importedAt: DateTime.now(),
          caption: reel.caption,
          thumbnailUrl: '',
          sourceUrl: reel.sourceUrl,
          platform: SocialPlatform.instagram,
          platformPostId: reel.platformPostId,
        ),
      );

  @override
  Future<Either<NetworkExceptions, BulkImportResult>> importBulk(
    List<ImportableReel> reels,
  ) async =>
      right(BulkImportResult(
        successCount: reels.length,
        failureCount: 0,
        allSucceeded: true,
      ));

  static final _allProducts = [
    const TaggedProductForImport(
      productId: 'p1',
      productName: 'Raspberry Velvet Cake',
      imageUrl: '',
      price: Money(amount: 5000, currency: 'NPR'),
      vendorName: "Sam's Bakery",
    ),
    const TaggedProductForImport(
      productId: 'p2',
      productName: 'Strawberry Cheese Cake',
      imageUrl: '',
      price: Money(amount: 2500, currency: 'NPR'),
      vendorName: 'Traditional Bakery',
    ),
    const TaggedProductForImport(
      productId: 'p3',
      productName: 'Belgian Chocolate Truffles Cake with Swiss Chocolate Drizzle',
      imageUrl: '',
      price: Money(amount: 8000, currency: 'NPR'),
      vendorName: 'The German Bakery',
    ),
    const TaggedProductForImport(
      productId: 'p4',
      productName: 'Classic Red Velvet Cake',
      imageUrl: '',
      price: Money(amount: 4500, currency: 'NPR'),
      vendorName: "Sam's Bakery",
    ),
    const TaggedProductForImport(
      productId: 'p5',
      productName: 'Mango Mousse Cake',
      imageUrl: '',
      price: Money(amount: 3800, currency: 'NPR'),
      vendorName: 'Sweet Treats',
    ),
  ];

  @override
  Future<Either<NetworkExceptions, List<TaggedProductForImport>>>
      searchProducts(String query) async {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return right(_allProducts);
    return right(
      _allProducts
          .where(
            (p) =>
                p.productName.toLowerCase().contains(q) ||
                p.vendorName.toLowerCase().contains(q),
          )
          .toList(),
    );
  }

  @override
  Future<Either<NetworkExceptions, Unit>> publishReel({
    required String reelId,
  }) async =>
      right(unit);

  @override
  Future<Either<NetworkExceptions, Unit>> tagProduct({
    required String reelId,
    required String productId,
  }) async =>
      right(unit);

  @override
  Future<Either<NetworkExceptions, List<ImportedReel>>> getImportHistory({
    int pageSize = 20,
    String? cursor,
  }) async =>
      right([]);

  @override
  Future<Either<NetworkExceptions, ReelIntent>> launchReelIntent(
    SocialPlatform platform,
  ) async =>
      right(ReelIntent(
        id: 'intent-mock-1',
        targetPlatform: platform,
        launchedAtUtc: DateTime.now(),
        expiresAtUtc: DateTime.now().add(const Duration(minutes: 30)),
        state: ReelIntentState.launched,
      ));

  @override
  Future<Either<NetworkExceptions, ReelIntent>> completeReelIntent({
    required String intentId,
    required String resultingReelId,
  }) async =>
      right(ReelIntent(
        id: intentId,
        targetPlatform: SocialPlatform.instagram,
        launchedAtUtc: DateTime.now().subtract(const Duration(minutes: 5)),
        expiresAtUtc: DateTime.now().add(const Duration(minutes: 25)),
        state: ReelIntentState.completed,
        resultingReelId: resultingReelId,
      ));
}

// ── Mock API client ───────────────────────────────────────────────────────────

class _MockApiClient extends ApiClient {
  _MockApiClient() : super(dio: Dio());

  @override
  Future<dynamic> get(
    String uri, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    if (uri.contains('/terms/active')) return _mockTerms;
    if (uri.contains('/campaigns')) return _mockCampaigns;
    if (uri.startsWith('/v1/partnerships/')) return _mockPartnership;
    return <String, dynamic>{};
  }

  @override
  Future<dynamic> post(
    String uri, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 600));
    return <String, dynamic>{'success': true};
  }
}

const _mockPartnership = <String, dynamic>{
  'id': 'brand-test-1',
  'state': 3,
  'commissionMinPercent': 12.0,
  'commissionMaxPercent': 20.0,
  'vendorRating': 4.8,
  'requestMessage': null,
  'vendorName': 'Nike Official Store',
  'vendorLogoUrl': null,
  'vendorCategory': 'Athletic & Sportswear',
  'description':
      'Nike is one of the world\'s most recognizable and iconic sportswear '
      'brands, founded in 1964 by Bill Bowerman and Phil Knight, originally.',
  'avgOrderValue': 12899.98,
  'successRatePercent': 97.0,
};

const _mockTerms = <String, dynamic>{
  'versionNumber': 1,
  'body': {
    'whoCanJoin': {
      'heading': 'Who Can Join?',
      'bullets': [
        'Open to all verified StyleMint creators.',
        'Must have synced social accounts before participating.',
      ],
    },
    'reelContentRules': {
      'heading': 'Reel Content Rules',
      'bullets': [
        'Use the hero video provided in the campaign details.',
        'Showcase Nike Running Shoes in action — jogging, sprinting, workouts, or styling shots.',
        'Minimum reel length: 8 seconds',
        'Reel must clearly feature Nike Zoom Series branding or product visuals.',
        'No third-party brand logos allowed in the reel.',
      ],
    },
  },
};

const _mockCampaigns = <Map<String, dynamic>>[
  {
    'id': 'c1',
    'title': 'Nike Zoom Series: Athlete Sprint Edition',
    'imageUrl': null,
    'reelCount': 5800,
    'creatorCollabCount': 269,
  },
  {
    'id': 'c2',
    'title': 'Nike Tech Fleece Jacket. Athlete Style for Every Age',
    'imageUrl': null,
    'reelCount': 2700,
    'creatorCollabCount': 345,
  },
];

// ── App shell ─────────────────────────────────────────────────────────────────

class _DevApp extends StatelessWidget {
  const _DevApp();

  @override
  Widget build(BuildContext context) {
    final router = GoRouter(
      initialLocation: RouteNames.creatorHome,
      routes: [
        GoRoute(
          path: RouteNames.creatorHome,
          builder: (ctx, _) => const CreatorDashboardScreen(),
        ),
        GoRoute(
          path: RouteNames.creatorTopReels,
          builder: (ctx, _) => const TopReelsScreen(),
        ),
        GoRoute(
          path: RouteNames.creatorActivity,
          builder: (ctx, _) => const RecentActivityScreen(),
        ),
        GoRoute(
          path: RouteNames.earningsPayout,
          builder: (ctx, _) => const PayoutScreen(),
        ),
        GoRoute(
          path: RouteNames.creatorPayoutHistory,
          builder: (ctx, _) => const AllPayoutHistoryScreen(),
        ),
        GoRoute(
          path: RouteNames.creatorPayoutInvoice,
          builder: (ctx, state) => PayoutInvoiceScreen(
            args: state.extra! as PayoutInvoiceArgs,
          ),
        ),
        GoRoute(
          path: RouteNames.creatorAddPaymentMethod,
          builder: (ctx, _) => const AddPaymentMethodScreen(),
        ),
        GoRoute(
          path: RouteNames.creatorBankVerification,
          builder: (ctx, _) => const BankVerificationScreen(),
        ),
        GoRoute(
          path: RouteNames.earnings,
          builder: (ctx, _) => const EarningsScreen(),
        ),
        GoRoute(
          path: RouteNames.creatorApply,
          builder: (ctx, _) => const CreatorApplyScreen(),
        ),
        GoRoute(
          path: RouteNames.reelImport,
          builder: (ctx, _) => const ImportReelScreen(),
        ),
        GoRoute(
          path: RouteNames.reelImportPreview,
          builder: (ctx, state) {
            final extra = state.extra! as Map<String, dynamic>;
            return PreviewReelScreen(
              url: extra['url'] as String,
              platform: extra['platform'] as SocialPlatform,
            );
          },
        ),
        GoRoute(
          path: RouteNames.reelImportTagProducts,
          builder: (ctx, _) => const TagProductsScreen(),
        ),
        GoRoute(
          path: RouteNames.reelImportReview,
          builder: (ctx, state) => ReviewReelScreen(
            args: state.extra! as ReviewReelArgs,
          ),
        ),
        GoRoute(
          path: RouteNames.reelPublished,
          builder: (ctx, state) => ReelPublishedScreen(
            args: state.extra! as ReviewReelArgs,
          ),
        ),
        GoRoute(
          path: RouteNames.creatorAnalytics,
          builder: (ctx, _) => const AnalyticsScreen(),
        ),
        GoRoute(
          path: RouteNames.creatorReelAnalyticsDetail,
          builder: (ctx, state) => ReelDetailAnalyticsScreen(
            reelId: state.pathParameters['reelId']!,
          ),
        ),
        GoRoute(
          path: RouteNames.creatorFullAnalyticsReport,
          builder: (ctx, _) => const FullAnalyticsReportScreen(),
        ),
        GoRoute(
          path: RouteNames.partnerships,
          builder: (ctx, _) => const BrandsScreen(),
        ),
        GoRoute(
          path: RouteNames.activePartnerships,
          builder: (ctx, _) => const ActivePartnershipsScreen(),
        ),
        GoRoute(
          path: RouteNames.partnershipRequests,
          builder: (ctx, _) => const PartnershipRequestsScreen(),
        ),
        GoRoute(
          path: RouteNames.brandDetail,
          builder: (ctx, state) => BrandDetailScreen(
            partnershipId: state.pathParameters['partnershipId']!,
          ),
        ),
        GoRoute(
          path: RouteNames.partnershipApply,
          builder: (ctx, state) => PartnershipRequestScreen(
            args: state.extra! as PartnershipApplyArgs,
          ),
        ),
        GoRoute(
          path: RouteNames.brandInfo,
          builder: (ctx, state) =>
              BrandInfoScreen(data: state.extra! as BrandInfoData),
        ),
        GoRoute(
          path: RouteNames.creatorProfile,
          builder: (ctx, state) {
            final accountId = state.pathParameters['accountId']!;
            final extra = state.extra is CreatorProfileArgs
                ? state.extra! as CreatorProfileArgs
                : CreatorProfileArgs(
                    accountId: accountId, displayName: '', handle: '');
            return CreatorProfileScreen(args: extra);
          },
        ),
        GoRoute(
          path: RouteNames.creatorProfileSettings,
          builder: (ctx, state) {
            final extra = state.extra is CreatorProfileArgs
                ? state.extra! as CreatorProfileArgs
                : const CreatorProfileArgs(
                    accountId: '', displayName: '', handle: '');
            return ProfileSettingsScreen(
              displayName: extra.displayName,
              handle: extra.handle,
              avatarUrl: extra.avatarUrl,
            );
          },
        ),
        GoRoute(
          path: RouteNames.creatorEditProfile,
          builder: (ctx, state) {
            final extra = state.extra is CreatorProfileArgs
                ? state.extra! as CreatorProfileArgs
                : const CreatorProfileArgs(
                    accountId: '', displayName: '', handle: '');
            return CreatorEditProfileScreen(
              initialDisplayName: extra.displayName,
              initialHandle: extra.handle,
            );
          },
        ),
        GoRoute(
          path: RouteNames.creatorProfileBadges,
          builder: (ctx, _) => const EditProfileBadgesScreen(),
        ),
        GoRoute(
          path: RouteNames.creatorCategoryNiche,
          builder: (ctx, _) => const EditCategoryNicheScreen(),
        ),
        GoRoute(
          path: RouteNames.creatorUpgradeSubscription,
          builder: (ctx, _) => const UpgradeSubscriptionScreen(),
        ),
        GoRoute(
          path: RouteNames.settingsChangePassword,
          builder: (ctx, _) => const ChangePasswordScreen(),
        ),
        GoRoute(
          path: RouteNames.profileEdit,
          builder: (ctx, _) => const EditProfileScreen(),
        ),
        GoRoute(
          path: RouteNames.profile,
          builder: (ctx, _) => const ProfileScreen(),
        ),
        GoRoute(
          path: RouteNames.search,
          builder: (ctx, _) => const SearchScreen(),
        ),
      ],
      errorBuilder: (_, state) => Scaffold(
        appBar: AppBar(title: const Text('Dev harness')),
        body: Center(
          child: Text(
            'No dev route for: ${state.uri}',
            style: const TextStyle(color: Colors.white70),
          ),
        ),
      ),
    );

    return MaterialApp.router(
      title: 'Creator Dashboard (dev)',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      routerConfig: router,
    );
  }
}
