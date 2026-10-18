import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/features/vendor/services/bank/data/bank_leads_repository.dart';
import 'package:stylemint_mobile_frontend/features/vendor/services/bank/domain/bank_lead.dart';
import 'package:stylemint_mobile_frontend/features/vendor/services/bank/presentation/bank_lead_widgets.dart';
import 'package:stylemint_mobile_frontend/features/vendor/services/bank/shared/bank_providers.dart';
import 'package:stylemint_mobile_frontend/features/vendor/services/shared/providers.dart';
import 'package:stylemint_mobile_frontend/features/vendor/services/shared/service_failure.dart';
import 'package:stylemint_mobile_frontend/features/vendor/services/shared/service_routes.dart';
import 'package:stylemint_mobile_frontend/features/vendor/services/shared/service_time.dart';
import 'package:stylemint_mobile_frontend/features/vendor/services/shared/service_widgets.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_brand_loader.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_empty_state.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// The bank's leads inbox: enquiries and branch appointments, newest first,
/// filtered by status and kind, searchable by reference or name.
class BankLeadsScreen extends ConsumerStatefulWidget {
  const BankLeadsScreen({this.initialStatus, super.key});

  final BankLeadStatus? initialStatus;

  static const Key searchKey = Key('bank-leads-search');
  static const Key loadMoreKey = Key('bank-leads-load-more');
  static Key statusChipKey(BankLeadStatus? s) =>
      Key('bank-leads-status-${s?.name ?? 'all'}');
  static Key kindChipKey(BankLeadKind? k) =>
      Key('bank-leads-kind-${k?.name ?? 'all'}');
  static Key tileKey(String id) => Key('bank-lead-tile-$id');

  @override
  ConsumerState<BankLeadsScreen> createState() => _BankLeadsScreenState();
}

class _BankLeadsScreenState extends ConsumerState<BankLeadsScreen> {
  late BankLeadStatus? _status = widget.initialStatus;
  BankLeadKind? _kind;
  String _search = '';
  Timer? _debounce;

  final List<BankLead> _leads = [];
  String? _cursor;
  bool _loading = true;
  bool _loadingMore = false;
  Object? _error;
  int _generation = 0;

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
        .read(bankLeadsRepositoryProvider)
        .listLeads(status: _status, kind: _kind, search: _search);
    if (!mounted || generation != _generation) return;
    setState(() {
      _loading = false;
      result.fold((f) {
        _error = ServiceLoadException(f);
      }, (page) {
        _leads
          ..clear()
          ..addAll(page.items);
        _cursor = page.nextCursor;
      });
    });
  }

  Future<void> _loadMore() async {
    final cursor = _cursor;
    if (cursor == null || _loadingMore) return;
    final generation = _generation;
    setState(() => _loadingMore = true);
    final result = await ref
        .read(bankLeadsRepositoryProvider)
        .listLeads(
          status: _status,
          kind: _kind,
          search: _search,
          cursor: cursor,
        );
    if (!mounted || generation != _generation) return;
    setState(() {
      _loadingMore = false;
      result.fold((_) {}, (page) {
        _leads.addAll(page.items);
        _cursor = page.nextCursor;
      });
    });
    result.fold(
      (f) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(serviceFailureMessage(f, specific: bankErrorMessage)),
        ),
      ),
      (_) {},
    );
  }

  void _onSearch(String text) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      _search = text.trim();
      unawaited(_reload());
    });
  }

  @override
  Widget build(BuildContext context) {
    final unavailable = serviceUnavailable(_error);
    return Scaffold(
      backgroundColor: DesignTokens.bgAppFoundation,
      appBar: AppBar(
        backgroundColor: DesignTokens.bgAppFoundation,
        title: const Text('Leads'),
        actions: [
          IconButton(
            tooltip: 'Branch appointments',
            icon: const Icon(Icons.event_available_rounded),
            onPressed: () => context.push(ServiceRoutes.bankAppointments),
          ),
        ],
      ),
      body: SafeArea(
        child: unavailable
            ? ListView(
                children: const [
                  ServiceSettingUpView(title: 'Your leads inbox is being set up'),
                ],
              )
            : Column(
                children: [
                  _filters(),
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: _reload,
                      child: _body(),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _filters() => Padding(
    padding: const EdgeInsets.fromLTRB(
      DesignTokens.s16,
      DesignTokens.s8,
      DesignTokens.s16,
      DesignTokens.s4,
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          key: BankLeadsScreen.searchKey,
          onChanged: _onSearch,
          textInputAction: TextInputAction.search,
          decoration: const InputDecoration(
            isDense: true,
            prefixIcon: Icon(Icons.search_rounded),
            hintText: 'Search by reference or name',
          ),
        ),
        const SizedBox(height: DesignTokens.s8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final k in <BankLeadKind?>[null, ...BankLeadKind.values])
                Padding(
                  padding: const EdgeInsets.only(right: DesignTokens.s8),
                  child: ChoiceChip(
                    key: BankLeadsScreen.kindChipKey(k),
                    label: Text(
                      k == null
                          ? 'All'
                          : k == BankLeadKind.enquiry
                          ? 'Enquiries'
                          : 'Appointments',
                    ),
                    selected: _kind == k,
                    selectedColor: DesignTokens.chipsSelectedFill,
                    onSelected: (_) {
                      setState(() => _kind = k);
                      unawaited(_reload());
                    },
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: DesignTokens.s4),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final s in <BankLeadStatus?>[
                null,
                ...BankLeadStatus.values,
              ])
                Padding(
                  padding: const EdgeInsets.only(right: DesignTokens.s8),
                  child: ChoiceChip(
                    key: BankLeadsScreen.statusChipKey(s),
                    label: Text(s?.label ?? 'Any status'),
                    selected: _status == s,
                    selectedColor: DesignTokens.chipsSelectedFill,
                    onSelected: (_) {
                      setState(() => _status = s);
                      unawaited(_reload());
                    },
                  ),
                ),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _body() {
    if (_loading) return const SmPageLoader();
    final error = _error;
    if (error != null) {
      return ListView(
        children: [
          ServiceLoadFailureView(
            error: error,
            settingUpTitle: 'Your leads inbox is being set up',
            fallback: 'We could not load your leads.',
            specific: bankErrorMessage,
            onRetry: () => unawaited(_reload()),
          ),
        ],
      );
    }
    if (_leads.isEmpty) {
      return ListView(
        children: [
          SmEmptyState(
            icon: Icons.inbox_outlined,
            message: _status == null && _kind == null && _search.isEmpty
                ? 'No enquiries or appointment requests yet. They arrive '
                      'here when buyers contact you from your bank page.'
                : 'No leads match these filters.',
          ),
        ],
      );
    }
    final today = ref.read(serviceTodayProvider);
    return ListView.separated(
      padding: const EdgeInsets.all(DesignTokens.s16),
      itemCount: _leads.length + (_cursor != null ? 1 : 0),
      separatorBuilder: (_, _) => const SizedBox(height: DesignTokens.s12),
      itemBuilder: (_, i) {
        if (i == _leads.length) {
          return Center(
            child: _loadingMore
                ? const CircularProgressIndicator()
                : TextButton(
                    key: BankLeadsScreen.loadMoreKey,
                    onPressed: () => unawaited(_loadMore()),
                    child: const Text('Load more'),
                  ),
          );
        }
        return BankLeadTile(lead: _leads[i], today: today);
      },
    );
  }
}

/// One lead in the inbox.
class BankLeadTile extends StatelessWidget {
  const BankLeadTile({required this.lead, required this.today, super.key});

  final BankLead lead;
  final DateTime today;

  @override
  Widget build(BuildContext context) {
    final l = lead;
    final muted = DesignTokens.tiny.copyWith(color: DesignTokens.textMuted);
    final appointment = l.appointment;
    return InkWell(
      key: BankLeadsScreen.tileKey(l.id),
      borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
      onTap: () => context.push(ServiceRoutes.bankLeadPath(l.id)),
      child: ServiceCard(
        borderColor: l.status == BankLeadStatus.newLead
            ? DesignTokens.colorInfo.withValues(alpha: 0.6)
            : null,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    l.displayName,
                    style: DesignTokens.mediumSemibold,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: DesignTokens.s8),
                ServicePill(l.status.label, tone: bankLeadTone(l.status)),
              ],
            ),
            const SizedBox(height: DesignTokens.s4),
            Text(
              '${l.kind.label} · ${l.title}',
              style: DesignTokens.smallRegular,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (appointment?.date != null)
              Text(
                'Visit ${serviceRelativeDay(appointment!.date!, today)}'
                '${appointment.startTime == null ? '' : ' at ${appointment.startTime}'}'
                '${appointment.branchName == null ? '' : ' · ${appointment.branchName}'}',
                style: muted,
              )
            else if (l.branchName != null)
              Text('Preferred branch: ${l.branchName}', style: muted),
            Text(
              [
                if (l.reference.isNotEmpty) l.reference,
                if (l.createdUtc != null) serviceInstantText(l.createdUtc!),
              ].join(' · '),
              style: muted,
            ),
          ],
        ),
      ),
    );
  }
}
