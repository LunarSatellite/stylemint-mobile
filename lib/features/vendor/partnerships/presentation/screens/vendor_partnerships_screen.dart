import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/features/vendor/partnerships/domain/entities/vendor_partnership.dart';
import 'package:stylemint_mobile_frontend/features/vendor/partnerships/presentation/notifiers/vendor_partnerships_notifier.dart';
import 'package:stylemint_mobile_frontend/features/vendor/partnerships/presentation/widgets/campaign_card.dart';
import 'package:stylemint_mobile_frontend/features/vendor/partnerships/shared/providers.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_empty_state.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_error_view.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

class VendorPartnershipsScreen extends ConsumerWidget {
  const VendorPartnershipsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(vendorPartnershipsNotifierProvider);

    return Scaffold(
      backgroundColor: DesignTokens.bgAppFoundation,
      appBar: AppBar(
        backgroundColor: DesignTokens.bgAppFoundation,
        title: const Text('Partnerships', style: DesignTokens.titleMedium),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: DesignTokens.primaryGreen,
        foregroundColor: DesignTokens.textDark,
        onPressed: () => _showCreateCampaignSheet(context),
        child: const Icon(Icons.add),
      ),
      body: state.when(
        initial: _loader,
        loadInProgress: _loader,
        loadSuccess: (campaigns) {
          if (campaigns.isEmpty) {
            return const SmEmptyState(
              message: 'No campaigns yet.\nCreate your first campaign!',
              icon: Icons.campaign_outlined,
            );
          }
          return RefreshIndicator(
            color: DesignTokens.primaryGreen,
            onRefresh: () =>
                ref.read(vendorPartnershipsNotifierProvider.notifier).loadCampaigns(),
            child: ListView.builder(
              padding: const EdgeInsets.all(DesignTokens.s16),
              itemCount: campaigns.length,
              itemBuilder: (_, i) => CampaignCard(
                campaign: campaigns[i],
                onTap: () => context.push(
                  '/vendor/partnerships/${campaigns[i].id}/invite',
                ),
              ),
            ),
          );
        },
        loadFailure: (failure) => SmErrorView(
          message: 'Failed to load campaigns.',
          onRetry: () =>
              ref.read(vendorPartnershipsNotifierProvider.notifier).loadCampaigns(),
        ),
      ),
    );
  }

  Widget _loader() => const Center(
        child: CircularProgressIndicator(color: DesignTokens.primaryGreen),
      );

  void _showCreateCampaignSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: DesignTokens.bgAppBody,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(DesignTokens.s24)),
      ),
      builder: (_) => const _CreateCampaignSheet(),
    );
  }
}

class _CreateCampaignSheet extends ConsumerStatefulWidget {
  const _CreateCampaignSheet();

  @override
  ConsumerState<_CreateCampaignSheet> createState() =>
      _CreateCampaignSheetState();
}

class _CreateCampaignSheetState extends ConsumerState<_CreateCampaignSheet> {
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _budgetCtrl = TextEditingController();
  final _targetCtrl = TextEditingController();
  double _commission = 10;
  DateTime _startDate = DateTime.now();
  DateTime? _endDate;
  final _selectedCategories = <String>[];

  static const _categories = [
    'Fashion',
    'Beauty',
    'Lifestyle',
    'Fitness',
    'Food',
    'Tech',
    'Travel',
    'Home',
  ];

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _budgetCtrl.dispose();
    _targetCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: DesignTokens.s16,
        right: DesignTokens.s16,
        top: DesignTokens.s16,
        bottom: MediaQuery.of(context).viewInsets.bottom + DesignTokens.s16,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: DesignTokens.textMuted,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: DesignTokens.s16),
            Text('Create Campaign', style: DesignTokens.h2),
            const SizedBox(height: DesignTokens.s16),
            TextField(
              controller: _titleCtrl,
              style: DesignTokens.oneLinerRegular,
              decoration: DesignTokens.inputDecoration(
                labelText: 'Campaign Title',
              ),
            ),
            const SizedBox(height: DesignTokens.s12),
            TextField(
              controller: _descCtrl,
              style: DesignTokens.oneLinerRegular,
              maxLines: 3,
              decoration: DesignTokens.inputDecoration(
                labelText: 'Description',
              ),
            ),
            const SizedBox(height: DesignTokens.s12),
            Text(
              'Commission Rate: ${_commission.toStringAsFixed(0)}%',
              style: DesignTokens.mediumSemibold,
            ),
            Slider(
              value: _commission,
              min: 1,
              max: 50,
              divisions: 49,
              activeColor: DesignTokens.primaryGreen,
              onChanged: (v) => setState(() => _commission = v),
            ),
            TextField(
              controller: _budgetCtrl,
              style: DesignTokens.oneLinerRegular,
              keyboardType: TextInputType.number,
              decoration: DesignTokens.inputDecoration(
                labelText: 'Budget (NPR)',
              ),
            ),
            const SizedBox(height: DesignTokens.s12),
            TextField(
              controller: _targetCtrl,
              style: DesignTokens.oneLinerRegular,
              keyboardType: TextInputType.number,
              decoration: DesignTokens.inputDecoration(
                labelText: 'Target Creators',
              ),
            ),
            const SizedBox(height: DesignTokens.s12),
            Text('Required Categories', style: DesignTokens.mediumSemibold),
            const SizedBox(height: DesignTokens.s8),
            Wrap(
              spacing: DesignTokens.s8,
              runSpacing: DesignTokens.s8,
              children: _categories.map((cat) {
                final selected = _selectedCategories.contains(cat);
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      selected
                          ? _selectedCategories.remove(cat)
                          : _selectedCategories.add(cat);
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: DesignTokens.s12,
                      vertical: DesignTokens.s6,
                    ),
                    decoration: selected
                        ? DesignTokens.chipDecorationSelected()
                        : DesignTokens.chipDecorationDefault(),
                    child: Text(
                      cat,
                      style: DesignTokens.smallRegular.copyWith(
                        color: selected
                            ? DesignTokens.primaryGreen
                            : DesignTokens.textMuted,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: DesignTokens.s20),
            SizedBox(
              width: double.infinity,
              height: DesignTokens.buttonHeight,
              child: ElevatedButton(
                onPressed: _titleCtrl.text.isNotEmpty
                    ? () {
                        final notifier = ref.read(
                          vendorPartnershipsNotifierProvider.notifier,
                        );
                        final brief = CampaignBrief(
                          id: '',
                          title: _titleCtrl.text,
                          description: _descCtrl.text,
                          commissionRate: _commission,
                          budget: Money(amount: 0, currency: 'NPR'),
                          startDate: _startDate,
                          targetCreators:
                              int.tryParse(_targetCtrl.text) ?? 0,
                          requiredCategories:
                              List<String>.from(_selectedCategories),
                          createdAt: DateTime.now(),
                        ).copyWith(
                          budget: Money(
                            amount:
                                double.tryParse(_budgetCtrl.text) ?? 0,
                            currency: 'NPR',
                          ),
                        );
                        notifier.createCampaign(brief);
                        Navigator.of(context).pop();
                      }
                    : null,
                style: DesignTokens.primaryButtonStyle(),
                child: const Text('Create Campaign'),
              ),
            ),
            const SizedBox(height: DesignTokens.s12),
          ],
        ),
      ),
    );
  }
}
