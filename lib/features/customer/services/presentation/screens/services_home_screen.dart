import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:stylemint_mobile_frontend/features/customer/services/domain/entities/banks.dart';
import 'package:stylemint_mobile_frontend/features/customer/services/domain/entities/service_search.dart';
import 'package:stylemint_mobile_frontend/features/customer/services/presentation/widgets/bank_widgets.dart';
import 'package:stylemint_mobile_frontend/features/customer/services/presentation/widgets/service_widgets.dart';
import 'package:stylemint_mobile_frontend/features/customer/services/shared/banks_providers.dart';
import 'package:stylemint_mobile_frontend/features/customer/services/shared/services_providers.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_brand_loader.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_empty_state.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// The Services tab: Stays · Travel · Banks, apart from the shopping Mall.
///
/// Stays and Travel open on a search (dates and guests); Banks lists the
/// banks and, filtered by type, their products. "My bookings" sits in the
/// app bar.
class ServicesHomeScreen extends ConsumerWidget {
  const ServicesHomeScreen({super.key});

  static const Key myBookingsKey = Key('services-my-bookings');

  @override
  Widget build(BuildContext context, WidgetRef ref) => DefaultTabController(
    length: 3,
    child: Scaffold(
      backgroundColor: DesignTokens.bgAppFoundation,
      appBar: AppBar(
        backgroundColor: DesignTokens.bgAppFoundation,
        title: const Text('Services'),
        actions: [
          TextButton.icon(
            key: myBookingsKey,
            onPressed: () async {
              if (await servicesEnsureAuth(context, ref) && context.mounted) {
                unawaited(context.push(RouteNames.myBookings));
              }
            },
            icon: const Icon(Icons.event_note_outlined, size: 18),
            label: const Text('My bookings'),
            style: TextButton.styleFrom(
              foregroundColor: DesignTokens.primaryGreen,
            ),
          ),
        ],
        bottom: const TabBar(
          labelColor: DesignTokens.primaryGreen,
          unselectedLabelColor: DesignTokens.textMuted,
          indicatorColor: DesignTokens.primaryGreen,
          tabs: [
            Tab(key: Key('services-tab-stays'), text: 'Stays'),
            Tab(key: Key('services-tab-travel'), text: 'Travel'),
            Tab(key: Key('services-tab-banks'), text: 'Banks'),
          ],
        ),
      ),
      body: const SafeArea(
        child: TabBarView(
          children: [StaySearchForm(), TravelSearchForm(), BanksSection()],
        ),
      ),
    ),
  );
}

// ── Stays ────────────────────────────────────────────────────────────────────

/// City or area, check-in and check-out, guests and rooms → results.
class StaySearchForm extends ConsumerStatefulWidget {
  const StaySearchForm({super.key});

  static const Key locationKey = Key('stay-search-location');
  static const Key datesKey = Key('stay-search-dates');
  static const Key submitKey = Key('stay-search-submit');
  static const Key errorKey = Key('stay-search-error');

  @override
  ConsumerState<StaySearchForm> createState() => _StaySearchFormState();
}

class _StaySearchFormState extends ConsumerState<StaySearchForm> {
  final _location = TextEditingController();
  late StaySearch _search = StaySearch.initial(
    kathmanduDay(ref.read(servicesClockProvider)()),
  );
  String? _error;

  @override
  void dispose() {
    _location.dispose();
    super.dispose();
  }

  Future<void> _pickDates() async {
    final today = kathmanduDay(ref.read(servicesClockProvider)());
    final range = await showDateRangePicker(
      context: context,
      firstDate: today,
      lastDate: today.add(const Duration(days: 365)),
      initialDateRange: DateTimeRange(
        start: _search.checkIn,
        end: _search.checkOut,
      ),
      helpText: 'Check-in and check-out',
    );
    if (range == null || !mounted) return;
    var end = range.end;
    if (!end.isAfter(range.start)) end = range.start.add(const Duration(days: 1));
    setState(() => _search = _search.copyWith(checkIn: range.start, checkOut: end));
  }

  void _submit() {
    final location = _location.text.trim();
    final search = _search.copyWith(location: location);
    String? error;
    if (location.length < 2) {
      error = 'Enter a city or area, for example Pokhara.';
    } else if (!search.isValid) {
      error = search.nights < 1
          ? 'Check-out must be after check-in.'
          : 'Each room needs at least one guest.';
    }
    setState(() => _error = error);
    if (error != null) return;
    unawaited(
      context.push(
        Uri(
          path: RouteNames.serviceStayResults,
          queryParameters: search.toQuery(),
        ).toString(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final nights = _search.nights;
    return ListView(
      padding: const EdgeInsets.all(DesignTokens.s20),
      children: [
        const Text('Find a place to stay', style: DesignTokens.h3),
        const SizedBox(height: DesignTokens.s16),
        TextField(
          key: StaySearchForm.locationKey,
          controller: _location,
          textInputAction: TextInputAction.search,
          onSubmitted: (_) => _submit(),
          style: DesignTokens.smallRegular,
          decoration: serviceInputDecoration(
            'City or area',
            hint: 'Kathmandu, Thamel, Pokhara…',
          ).copyWith(prefixIcon: const Icon(Icons.place_outlined)),
        ),
        const SizedBox(height: DesignTokens.s12),
        ServiceCard(
          padding: EdgeInsets.zero,
          child: ListTile(
            key: StaySearchForm.datesKey,
            onTap: () => unawaited(_pickDates()),
            leading: const Icon(Icons.date_range_outlined),
            title: Text(
              '${serviceShortDate(_search.checkIn)} → '
              '${serviceShortDate(_search.checkOut)}',
              style: DesignTokens.smallRegular,
            ),
            subtitle: Text(
              nights == 1 ? '1 night' : '$nights nights',
              style: DesignTokens.tiny.copyWith(color: DesignTokens.textMuted),
            ),
            trailing: const Icon(Icons.edit_calendar_outlined, size: 18),
          ),
        ),
        const SizedBox(height: DesignTokens.s12),
        ServiceCard(
          child: Column(
            children: [
              ServiceCounter(
                label: 'Guests',
                keyPrefix: 'stay-guests',
                value: _search.guests,
                min: 1,
                max: 30,
                onChanged: (v) =>
                    setState(() => _search = _search.copyWith(guests: v)),
              ),
              ServiceCounter(
                label: 'Rooms',
                keyPrefix: 'stay-rooms',
                value: _search.rooms,
                min: 1,
                max: 10,
                onChanged: (v) =>
                    setState(() => _search = _search.copyWith(rooms: v)),
              ),
            ],
          ),
        ),
        if (_error != null) ...[
          const SizedBox(height: DesignTokens.s8),
          Text(
            _error!,
            key: StaySearchForm.errorKey,
            style: DesignTokens.tiny.copyWith(color: DesignTokens.colorError),
          ),
        ],
        const SizedBox(height: DesignTokens.s20),
        ServicePrimaryButton(
          key: StaySearchForm.submitKey,
          label: 'Search stays',
          onPressed: _submit,
        ),
      ],
    );
  }
}

// ── Travel ───────────────────────────────────────────────────────────────────

/// Destination, month and travellers → packages.
class TravelSearchForm extends ConsumerStatefulWidget {
  const TravelSearchForm({super.key});

  static const Key destinationKey = Key('travel-search-destination');
  static const Key submitKey = Key('travel-search-submit');
  static Key monthKey(int index) => Key('travel-month-$index');

  @override
  ConsumerState<TravelSearchForm> createState() => _TravelSearchFormState();
}

class _TravelSearchFormState extends ConsumerState<TravelSearchForm> {
  final _destination = TextEditingController();
  TravelSearch _search = const TravelSearch();

  @override
  void dispose() {
    _destination.dispose();
    super.dispose();
  }

  void _submit() {
    final search = _search.copyWith(destination: _destination.text.trim());
    unawaited(
      context.push(
        Uri(
          path: RouteNames.serviceTravelResults,
          queryParameters: search.toQuery(),
        ).toString(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final today = kathmanduDay(ref.watch(servicesClockProvider)());
    final months = [
      for (var i = 0; i < 12; i++) DateTime(today.year, today.month + i),
    ];
    return ListView(
      padding: const EdgeInsets.all(DesignTokens.s20),
      children: [
        const Text('Find a trip', style: DesignTokens.h3),
        const SizedBox(height: DesignTokens.s16),
        TextField(
          key: TravelSearchForm.destinationKey,
          controller: _destination,
          textInputAction: TextInputAction.search,
          onSubmitted: (_) => _submit(),
          style: DesignTokens.smallRegular,
          decoration: serviceInputDecoration(
            'Destination',
            hint: 'Annapurna, Chitwan, Mustang…',
          ).copyWith(prefixIcon: const Icon(Icons.terrain_outlined)),
        ),
        const SizedBox(height: DesignTokens.s16),
        Text(
          'When',
          style: DesignTokens.tiny.copyWith(color: DesignTokens.textMuted),
        ),
        const SizedBox(height: DesignTokens.s8),
        SizedBox(
          height: 40,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              Padding(
                padding: const EdgeInsets.only(right: DesignTokens.s8),
                child: ChoiceChip(
                  key: const Key('travel-month-any'),
                  label: const Text('Any time'),
                  selected: _search.month == null,
                  onSelected: (_) => setState(
                    () => _search = _search.copyWith(clearMonth: true),
                  ),
                ),
              ),
              for (var i = 0; i < months.length; i++)
                Padding(
                  padding: const EdgeInsets.only(right: DesignTokens.s8),
                  child: ChoiceChip(
                    key: TravelSearchForm.monthKey(i),
                    label: Text(DateFormat('MMM yyyy').format(months[i])),
                    selected: _search.month == months[i],
                    onSelected: (_) => setState(
                      () => _search = _search.copyWith(month: months[i]),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: DesignTokens.s12),
        ServiceCard(
          child: ServiceCounter(
            label: 'Travellers',
            keyPrefix: 'travel-travellers',
            value: _search.travellers,
            min: 1,
            max: 50,
            onChanged: (v) =>
                setState(() => _search = _search.copyWith(travellers: v)),
          ),
        ),
        const SizedBox(height: DesignTokens.s20),
        ServicePrimaryButton(
          key: TravelSearchForm.submitKey,
          label: 'Search trips',
          onPressed: _submit,
        ),
      ],
    );
  }
}

// ── Banks ────────────────────────────────────────────────────────────────────

/// Which product type the Banks section is filtered to; null shows banks.
final bankTypeFilterProvider = StateProvider<BankProductType?>(
  (ref) => null,
);

/// Banks, or — filtered by a product type — those products across banks,
/// to compare rates.
class BanksSection extends ConsumerWidget {
  const BanksSection({super.key});

  static Key filterKey(BankProductType? type) =>
      Key('bank-filter-${type?.name ?? 'all'}');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final type = ref.watch(bankTypeFilterProvider);
    return Column(
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(
            horizontal: DesignTokens.s16,
            vertical: DesignTokens.s8,
          ),
          child: Row(
            children: [
              for (final t in <BankProductType?>[null, ...BankProductType.values])
                Padding(
                  padding: const EdgeInsets.only(right: DesignTokens.s8),
                  child: ChoiceChip(
                    key: filterKey(t),
                    label: Text(t == null ? 'All banks' : t.label),
                    selected: type == t,
                    onSelected: (_) =>
                        ref.read(bankTypeFilterProvider.notifier).state = t,
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: type == null ? const _BanksList() : _ProductsList(type: type),
        ),
      ],
    );
  }
}

class _BanksList extends ConsumerWidget {
  const _BanksList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final banks = ref.watch(banksListProvider);
    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(banksListProvider);
        try {
          await ref.read(banksListProvider.future);
        } on Object {
          // The list shows the failure itself.
        }
      },
      child: banks.when(
        loading: () => const SmPageLoader(),
        error: (error, _) => ListView(
          children: [
            ServiceFailureView(
              error: error,
              what: 'the banks',
              onRetry: () => ref.invalidate(banksListProvider),
            ),
          ],
        ),
        data: (list) => list.isEmpty
            ? ListView(
                children: const [
                  SmEmptyState(
                    title: 'No banks yet',
                    message: 'Banks will appear here once they join.',
                    icon: Icons.account_balance_outlined,
                  ),
                ],
              )
            : ListView.separated(
                padding: const EdgeInsets.all(DesignTokens.s16),
                itemCount: list.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(height: DesignTokens.s12),
                itemBuilder: (context, i) => BankTile(bank: list[i]),
              ),
      ),
    );
  }
}

class BankTile extends StatelessWidget {
  const BankTile({required this.bank, super.key});

  final BankSummary bank;

  @override
  Widget build(BuildContext context) => InkWell(
    key: Key('bank-tile-${bank.id}'),
    borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
    onTap: () => context.push(RouteNames.serviceBankDetailPath(bank.id)),
    child: ServiceCard(
      child: Row(
        children: [
          ServicePhoto(
            url: bank.logoUrl,
            height: 48,
            width: 48,
            radius: DesignTokens.radiusMedium,
            icon: Icons.account_balance_outlined,
          ),
          const SizedBox(width: DesignTokens.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        bank.name,
                        style: DesignTokens.mediumSemibold,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (bank.isVerified) ...[
                      const SizedBox(width: DesignTokens.s4),
                      const Icon(
                        Icons.verified_rounded,
                        size: 16,
                        color: DesignTokens.primaryGreen,
                      ),
                    ],
                  ],
                ),
                if (bank.tagline != null)
                  Text(
                    bank.tagline!,
                    style: DesignTokens.tiny.copyWith(
                      color: DesignTokens.textMuted,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                const SizedBox(height: DesignTokens.s4),
                Text(
                  [
                    if (bank.productCount > 0)
                      bank.productCount == 1
                          ? '1 product'
                          : '${bank.productCount} products',
                    if (bank.branchCount > 0)
                      bank.branchCount == 1
                          ? '1 branch'
                          : '${bank.branchCount} branches',
                    if (bank.appointmentsAvailable) 'Appointments',
                  ].join(' · '),
                  style: DesignTokens.tiny.copyWith(
                    color: DesignTokens.textLight,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: DesignTokens.textMuted),
        ],
      ),
    ),
  );
}

class _ProductsList extends ConsumerWidget {
  const _ProductsList({required this.type});

  final BankProductType type;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final products = ref.watch(bankProductsProvider(type));
    return products.when(
      loading: () => const SmPageLoader(),
      error: (error, _) => ListView(
        children: [
          ServiceFailureView(
            error: error,
            what: 'these products',
            onRetry: () => ref.invalidate(bankProductsProvider(type)),
          ),
        ],
      ),
      data: (list) => list.isEmpty
          ? ListView(
              children: [
                SmEmptyState(
                  title: 'Nothing here yet',
                  message: 'No bank offers a ${type.label.toLowerCase()} '
                      'on StyleMint yet.',
                  icon: Icons.account_balance_outlined,
                ),
              ],
            )
          : ListView.separated(
              padding: const EdgeInsets.all(DesignTokens.s16),
              itemCount: list.length,
              separatorBuilder: (_, _) =>
                  const SizedBox(height: DesignTokens.s12),
              itemBuilder: (context, i) => BankProductTile(product: list[i]),
            ),
    );
  }
}

class BankProductTile extends StatelessWidget {
  const BankProductTile({required this.product, this.showBank = true, super.key});

  final BankProduct product;
  final bool showBank;

  @override
  Widget build(BuildContext context) {
    final rate = product.rateLabel;
    return InkWell(
      key: Key('bank-product-tile-${product.id}'),
      borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
      onTap: () => context.push(RouteNames.serviceBankProductPath(product.id)),
      child: ServiceCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    product.name,
                    style: DesignTokens.mediumSemibold,
                  ),
                ),
                ServiceChip(label: product.type.label),
              ],
            ),
            if (showBank && product.bankName.isNotEmpty)
              Text(
                product.bankName,
                style: DesignTokens.tiny.copyWith(color: DesignTokens.textMuted),
              ),
            if (product.summary != null) ...[
              const SizedBox(height: DesignTokens.s4),
              Text(
                product.summary!,
                style: DesignTokens.smallRegular,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            if (rate != null) ...[
              const SizedBox(height: DesignTokens.s8),
              Text(
                rate,
                key: Key('bank-product-rate-${product.id}'),
                style: DesignTokens.mediumSemibold.copyWith(
                  color: DesignTokens.primaryGreen,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
