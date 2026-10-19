import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stylemint_mobile_frontend/features/auth/presentation/providers/auth_state_provider.dart';
import 'package:stylemint_mobile_frontend/features/vendor/profile/shared/providers.dart';
import 'package:stylemint_mobile_frontend/features/vendor/services/shared/service_category.dart';
import 'package:stylemint_mobile_frontend/features/vendor/services/shared/service_contact.dart';
import 'package:stylemint_mobile_frontend/features/vendor/services/shared/service_time.dart';

/// The signed-in vendor's service category, from their vendor profile
/// (`serviceCategory`, service-banks contract v1). A product seller — and
/// anyone whose profile cannot be read, or a server that does not send the
/// field yet — is [ServiceCategory.none], so product sellers see no change.
final FutureProvider<ServiceCategory> vendorServiceCategoryProvider =
    FutureProvider.autoDispose<ServiceCategory>((ref) async {
      final accountId = ref
          .watch(sessionControllerProvider)
          .maybeWhen(authenticated: (id) => id, orElse: () => '');
      if (accountId.isEmpty) return ServiceCategory.none;
      final profile = await ref.watch(myVendorProfileProvider(accountId).future);
      return ServiceCategory.fromWire(profile?.serviceCategory);
    }, retry: (_, _) => null);

/// The category once known; [ServiceCategory.none] while loading or failed.
final Provider<ServiceCategory> vendorServiceCategoryNowProvider =
    Provider.autoDispose<ServiceCategory>(
      (ref) =>
          ref.watch(vendorServiceCategoryProvider).value ??
          ServiceCategory.none,
    );

/// Today on the Kathmandu calendar. A provider so tests can fix the date.
final Provider<DateTime> serviceTodayProvider = Provider<DateTime>(
  (ref) => serviceToday(),
);

/// The current instant (UTC). A provider so tests can fix the clock.
final Provider<DateTime> serviceNowProvider = Provider<DateTime>(
  (ref) => DateTime.now().toUtc(),
);

/// Opens the dialler or WhatsApp. A provider so tests can see what was
/// opened instead of leaving the app.
final Provider<ServiceContactLauncher> serviceContactLauncherProvider =
    Provider<ServiceContactLauncher>((ref) => const UrlServiceContactLauncher());
