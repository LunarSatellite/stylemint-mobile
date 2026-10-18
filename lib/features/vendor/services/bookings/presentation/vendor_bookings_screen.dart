import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/features/vendor/services/bookings/data/vendor_bookings_repository.dart';
import 'package:stylemint_mobile_frontend/features/vendor/services/bookings/domain/service_booking.dart';
import 'package:stylemint_mobile_frontend/features/vendor/services/bookings/presentation/booking_widgets.dart';
import 'package:stylemint_mobile_frontend/features/vendor/services/bookings/shared/booking_providers.dart';
import 'package:stylemint_mobile_frontend/features/vendor/services/shared/providers.dart';
import 'package:stylemint_mobile_frontend/features/vendor/services/shared/service_category.dart';
import 'package:stylemint_mobile_frontend/features/vendor/services/shared/service_failure.dart';
import 'package:stylemint_mobile_frontend/features/vendor/services/shared/service_routes.dart';
import 'package:stylemint_mobile_frontend/features/vendor/services/shared/service_time.dart';
import 'package:stylemint_mobile_frontend/features/vendor/services/shared/service_widgets.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_brand_loader.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_empty_state.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

const _settingUpTitle = 'Bookings are being set up';

/// The words for the day's three lists: a hotel's front desk, or a travel
/// agency's departures.
class BookingDayWords {
  const BookingDayWords._(this.arriving, this.leaving, this.inHouse);

  static const hotel = BookingDayWords._(
    'Arriving today',
    'Checking out today',
    'In house',
  );
  static const travel = BookingDayWords._(
    'Starting today',
    'Finishing today',
    'On trip now',
  );

  static BookingDayWords of(ServiceCategory c) =>
      c == ServiceCategory.travelAgency ? travel : hotel;

  final String arriving;
  final String leaving;
  final String inHouse;
}

/// Hotel / travel bookings on the go: today's arrivals and departures,
/// what is coming up, and every booking with search.
class VendorBookingsScreen extends ConsumerWidget {
  const VendorBookingsScreen({this.initialTab = 0, super.key});

  final int initialTab;

  static const Key todayTabKey = Key('vendor-bookings-tab-today');
  static const Key upcomingTabKey = Key('vendor-bookings-tab-upcoming');
  static const Key allTabKey = Key('vendor-bookings-tab-all');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 3,
      initialIndex: initialTab.clamp(0, 2),
      child: Scaffold(
        backgroundColor: DesignTokens.bgAppFoundation,
        appBar: AppBar(
          backgroundColor: DesignTokens.bgAppFoundation,
          title: const Text('Bookings'),
          actions: [
            IconButton(
              tooltip: 'Availability',
              icon: const Icon(Icons.event_note_rounded),
              onPressed: () => context.push(ServiceRoutes.availability),
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(key: todayTabKey, text: 'Today'),
              Tab(key: upcomingTabKey, text: 'Upcoming'),
              Tab(key: allTabKey, text: 'All'),
            ],
          ),
        ),
        body: const SafeArea(
          child: TabBarView(
            children: [_TodayTab(), _UpcomingTab(), _AllTab()],
          ),
        ),
      ),
    );
  }
}

class _TodayTab extends ConsumerWidget {
  const _TodayTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final board = ref.watch(vendorBookingsTodayProvider);
    final words = BookingDayWords.of(ref.watch(vendorServiceCategoryNowProvider));
    final summary = ref.watch(vendorBookingsSummaryProvider).value;
    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(vendorBookingsTodayProvider);
        ref.invalidate(vendorBookingsSummaryProvider);
        await ref.read(vendorBookingsTodayProvider.future);
      },
      child: switch ((board.value, board.error)) {
        (final BookingsTodayBoard b, _) => ListView(
          padding: const EdgeInsets.all(DesignTokens.s16),
          children: [
            if (summary != null && summary.balanceToCollect.amount > 0)
              Padding(
                padding: const EdgeInsets.only(bottom: DesignTokens.s8),
                child: Text(
                  '${serviceMoney(summary.balanceToCollect)} still to collect at the venue',
                  style: DesignTokens.smallRegular.copyWith(
                    color: DesignTokens.colorWarning,
                  ),
                ),
              ),
            if (b.isEmpty)
              const SmEmptyState(
                icon: Icons.event_available_rounded,
                message: 'Nobody arrives or leaves today.',
              ),
            ..._section(words.arriving, b.arrivals),
            ..._section(words.leaving, b.leaving),
            ..._section(words.inHouse, b.inHouse),
          ],
        ),
        (_, final Object error) => ListView(
          children: [
            ServiceLoadFailureView(
              error: error,
              settingUpTitle: _settingUpTitle,
              fallback: 'We could not load today\'s bookings.',
              specific: bookingErrorMessage,
              onRetry: () => ref.invalidate(vendorBookingsTodayProvider),
            ),
          ],
        ),
        _ => const SmPageLoader(),
      },
    );
  }

  static List<Widget> _section(String title, List<ServiceBooking> items) => [
    if (items.isNotEmpty) ...[
      ServiceSectionTitle('$title (${items.length})'),
      for (final b in items) ...[
        ServiceBookingTile(booking: b),
        const SizedBox(height: DesignTokens.s12),
      ],
    ],
  ];
}

class _UpcomingTab extends ConsumerWidget {
  const _UpcomingTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final upcoming = ref.watch(vendorBookingsUpcomingProvider);
    final today = ref.watch(serviceTodayProvider);
    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(vendorBookingsUpcomingProvider);
        await ref.read(vendorBookingsUpcomingProvider.future);
      },
      child: switch ((upcoming.value, upcoming.error)) {
        (final List<ServiceBooking> items, _) when items.isEmpty => ListView(
          children: const [
            SmEmptyState(
              icon: Icons.event_outlined,
              message: 'No bookings in the next 30 days yet.',
            ),
          ],
        ),
        (final List<ServiceBooking> items, _) => ListView(
          padding: const EdgeInsets.all(DesignTokens.s16),
          children: [
            for (var i = 0; i < items.length; i++) ...[
              if (i == 0 ||
                  items[i].startDate == null ||
                  items[i - 1].startDate == null ||
                  daysBetween(items[i - 1].startDate!, items[i].startDate!) !=
                      0)
                ServiceSectionTitle(
                  items[i].startDate == null
                      ? 'Date to be confirmed'
                      : serviceRelativeDay(items[i].startDate!, today),
                ),
              ServiceBookingTile(booking: items[i]),
              const SizedBox(height: DesignTokens.s12),
            ],
          ],
        ),
        (_, final Object error) => ListView(
          children: [
            ServiceLoadFailureView(
              error: error,
              settingUpTitle: _settingUpTitle,
              fallback: 'We could not load upcoming bookings.',
              specific: bookingErrorMessage,
              onRetry: () => ref.invalidate(vendorBookingsUpcomingProvider),
            ),
          ],
        ),
        _ => const SmPageLoader(),
      },
    );
  }
}

class _AllTab extends ConsumerStatefulWidget {
  const _AllTab();

  static const Key searchKey = Key('vendor-bookings-search');

  @override
  ConsumerState<_AllTab> createState() => _AllTabState();
}

class _AllTabState extends ConsumerState<_AllTab>
    with AutomaticKeepAliveClientMixin {
  BookingState? _state;
  String _query = '';
  Timer? _debounce;
  final List<ServiceBooking> _items = [];
  String? _cursor;
  bool _loading = true;
  bool _loadingMore = false;
  Object? _error;
  int _generation = 0;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    unawaited(_reload());
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _reload() async {
    final generation = ++_generation;
    setState(() {
      _loading = true;
      _error = null;
    });
    final result = await ref
        .read(vendorBookingsRepositoryProvider)
        .listBookings(state: _state, query: _query);
    if (!mounted || generation != _generation) return;
    setState(() {
      _loading = false;
      result.fold(
        (f) {
          _error = ServiceLoadException(f);
        },
        (page) {
          _items
            ..clear()
            ..addAll(page.items);
          _cursor = page.nextCursor;
        },
      );
    });
  }

  Future<void> _loadMore() async {
    final cursor = _cursor;
    if (cursor == null || _loadingMore) return;
    final generation = _generation;
    setState(() => _loadingMore = true);
    final result = await ref
        .read(vendorBookingsRepositoryProvider)
        .listBookings(state: _state, query: _query, cursor: cursor);
    if (!mounted || generation != _generation) return;
    setState(() {
      _loadingMore = false;
      result.fold((_) {}, (page) {
        _items.addAll(page.items);
        _cursor = page.nextCursor;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (serviceUnavailable(_error)) {
      return ListView(
        children: const [ServiceSettingUpView(title: _settingUpTitle)],
      );
    }
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            DesignTokens.s16,
            DesignTokens.s8,
            DesignTokens.s16,
            0,
          ),
          child: TextField(
            key: _AllTab.searchKey,
            textInputAction: TextInputAction.search,
            decoration: const InputDecoration(
              isDense: true,
              prefixIcon: Icon(Icons.search_rounded),
              hintText: 'Booking number or guest name',
            ),
            onChanged: (text) {
              _debounce?.cancel();
              _debounce = Timer(const Duration(milliseconds: 400), () {
                _query = text.trim();
                unawaited(_reload());
              });
            },
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.fromLTRB(
            DesignTokens.s16,
            DesignTokens.s8,
            DesignTokens.s16,
            0,
          ),
          child: Row(
            children: [
              for (final s in <BookingState?>[
                null,
                BookingState.confirmed,
                BookingState.checkedIn,
                BookingState.pendingPayment,
                BookingState.completed,
                BookingState.cancelled,
                BookingState.noShow,
              ])
                Padding(
                  padding: const EdgeInsets.only(right: DesignTokens.s8),
                  child: ChoiceChip(
                    key: Key('vendor-bookings-state-${s?.name ?? 'all'}'),
                    label: Text(s?.label ?? 'All'),
                    selected: _state == s,
                    selectedColor: DesignTokens.chipsSelectedFill,
                    onSelected: (_) {
                      setState(() => _state = s);
                      unawaited(_reload());
                    },
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: RefreshIndicator(onRefresh: _reload, child: _body()),
        ),
      ],
    );
  }

  Widget _body() {
    if (_loading) return const SmPageLoader();
    final error = _error;
    if (error != null) {
      return ListView(
        children: [
          ServiceLoadFailureView(
            error: error,
            settingUpTitle: _settingUpTitle,
            fallback: 'We could not load your bookings.',
            specific: bookingErrorMessage,
            onRetry: () => unawaited(_reload()),
          ),
        ],
      );
    }
    if (_items.isEmpty) {
      return ListView(
        children: [
          SmEmptyState(
            icon: Icons.luggage_outlined,
            message: _state == null && _query.isEmpty
                ? 'No bookings yet.'
                : 'No bookings match.',
          ),
        ],
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(DesignTokens.s16),
      itemCount: _items.length + (_cursor != null ? 1 : 0),
      separatorBuilder: (_, _) => const SizedBox(height: DesignTokens.s12),
      itemBuilder: (_, i) => i == _items.length
          ? Center(
              child: _loadingMore
                  ? const CircularProgressIndicator()
                  : TextButton(
                      key: const Key('vendor-bookings-load-more'),
                      onPressed: () => unawaited(_loadMore()),
                      child: const Text('Load more'),
                    ),
            )
          : ServiceBookingTile(booking: _items[i]),
    );
  }
}
