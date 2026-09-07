import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/features/vendor/partnerships/domain/entities/vendor_partnership.dart';
import 'package:stylemint_mobile_frontend/features/vendor/partnerships/shared/providers.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// Mirrors the backend `CampaignGoal` enum (Vendor §3, `BrandStudio` module)
/// — values 1-7, no display labels published by the API.
const Map<int, String> _campaignGoals = {
  1: 'Drive first purchase',
  2: 'Reintroduce dormant customers',
  3: 'Launch new variant',
  4: 'Clear slow inventory',
  5: 'Build seasonal awareness',
  6: 'Educate on use',
  7: 'Test new audience',
};

/// Vendor → Brand Studio → new campaign brief (Vendor §3.1). Chains the two
/// calls the backend requires: `POST /v1/vendor/briefs` (title/goal/currency
/// only) then `PATCH /v1/vendor/briefs/{id}` (commission range + boost
/// budget) — the draft endpoint doesn't accept those fields directly.
class CreateCampaignScreen extends ConsumerStatefulWidget {
  const CreateCampaignScreen({super.key});

  @override
  ConsumerState<CreateCampaignScreen> createState() =>
      _CreateCampaignScreenState();
}

class _CreateCampaignScreenState extends ConsumerState<CreateCampaignScreen> {
  final _titleCtrl = TextEditingController();
  final _budgetCtrl = TextEditingController();
  int _goal = 1;
  RangeValues _commissionRange = const RangeValues(10, 20);
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _budgetCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final title = _titleCtrl.text.trim();
    if (title.isEmpty) {
      setState(() => _error = 'Give this campaign a title.');
      return;
    }
    final budget = double.tryParse(_budgetCtrl.text.trim());
    if (budget == null || budget <= 0) {
      setState(() => _error = 'Enter a valid boost budget amount.');
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });

    final notifier = ref.read(vendorPartnershipsNotifierProvider.notifier);
    final draft = CampaignBrief(
      id: '',
      vendorProfileId: '',
      title: title,
      primaryGoal: _goal,
      state: BrandBriefState.draft,
      version: 1,
      rootBriefId: '',
      commissionMinPercent: _commissionRange.start / 100,
      commissionMaxPercent: _commissionRange.end / 100,
      boostBudget: const Money(amount: 0, currency: 'NPR'),
      createdAt: DateTime.fromMillisecondsSinceEpoch(0),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(0),
    );

    final created = await notifier.createCampaign(draft);
    if (created == null) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = 'Failed to create campaign. Please try again.';
      });
      return;
    }

    final updated = await notifier.updateCampaign(
      created.id,
      created.copyWith(
        commissionMinPercent: _commissionRange.start / 100,
        commissionMaxPercent: _commissionRange.end / 100,
        boostBudget: Money(amount: budget, currency: 'NPR'),
      ),
    );

    if (!mounted) return;
    setState(() => _submitting = false);

    if (!updated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Campaign created, but commission/budget failed to save. '
            'Edit it from the brief detail screen.',
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: DesignTokens.colorError,
        ),
      );
    }

    context.pushReplacement(
      RouteNames.vendorCampaignBriefDetail.replaceFirst(
        ':briefId',
        created.id,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignTokens.bgAppFoundation,
      appBar: AppBar(
        backgroundColor: DesignTokens.bgAppFoundation,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: DesignTokens.textWhite,
            size: 20,
          ),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'New Campaign Brief',
          style: TextStyle(
            fontFamily: DesignTokens.fontFamily,
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: DesignTokens.textWhite,
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(DesignTokens.s16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_error != null) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(DesignTokens.s12),
                      decoration: BoxDecoration(
                        color: DesignTokens.colorError.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _error!,
                        style: const TextStyle(
                          fontFamily: DesignTokens.fontFamily,
                          fontSize: 13,
                          color: DesignTokens.colorError,
                        ),
                      ),
                    ),
                    const SizedBox(height: DesignTokens.s16),
                  ],
                  _sectionLabel('Title'),
                  const SizedBox(height: DesignTokens.s8),
                  _textField(
                    controller: _titleCtrl,
                    hint: 'e.g. Monsoon Collection Push',
                  ),
                  const SizedBox(height: DesignTokens.s16),
                  _sectionLabel('Primary Goal'),
                  const SizedBox(height: DesignTokens.s8),
                  _goalDropdown(),
                  const SizedBox(height: DesignTokens.s16),
                  _sectionLabel('Boost Budget (NPR)'),
                  const SizedBox(height: DesignTokens.s8),
                  _textField(
                    controller: _budgetCtrl,
                    hint: 'e.g. 5000',
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                  ),
                  const SizedBox(height: DesignTokens.s16),
                  _commissionCard(),
                ],
              ),
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                DesignTokens.s16,
                12,
                DesignTokens.s16,
                16,
              ),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _submitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: DesignTokens.primaryGreen,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(100),
                    ),
                    elevation: 0,
                  ),
                  child: _submitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Create Campaign Brief',
                          style: TextStyle(
                            fontFamily: DesignTokens.fontFamily,
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String label) => Text(
    label,
    style: const TextStyle(
      fontFamily: DesignTokens.fontFamily,
      fontSize: 14,
      fontWeight: FontWeight.w600,
      color: DesignTokens.textWhite,
    ),
  );

  Widget _textField({
    required TextEditingController controller,
    required String hint,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(
        fontFamily: DesignTokens.fontFamily,
        fontSize: 14,
        color: DesignTokens.textWhite,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: DesignTokens.textMuted),
        filled: true,
        fillColor: DesignTokens.bgAppBodyLight,
        contentPadding: const EdgeInsets.all(DesignTokens.s12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _goalDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: DesignTokens.s12),
      decoration: BoxDecoration(
        color: DesignTokens.bgAppBodyLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: _goal,
          isExpanded: true,
          dropdownColor: DesignTokens.bgAppBodyLight,
          icon: const Icon(Icons.expand_more, color: DesignTokens.textMuted),
          style: const TextStyle(
            fontFamily: DesignTokens.fontFamily,
            fontSize: 14,
            color: DesignTokens.textWhite,
          ),
          items: _campaignGoals.entries
              .map(
                (e) => DropdownMenuItem(value: e.key, child: Text(e.value)),
              )
              .toList(growable: false),
          onChanged: (value) {
            if (value != null) setState(() => _goal = value);
          },
        ),
      ),
    );
  }

  Widget _commissionCard() {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        DesignTokens.s16,
        DesignTokens.s16,
        DesignTokens.s16,
        12,
      ),
      decoration: BoxDecoration(
        color: DesignTokens.bgAppBodyLight,
        borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Creator Commission Range: '
            '${_commissionRange.start.round()}%–${_commissionRange.end.round()}%',
            style: const TextStyle(
              fontFamily: DesignTokens.fontFamily,
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: DesignTokens.textWhite,
            ),
          ),
          RangeSlider(
            values: _commissionRange,
            min: 0,
            max: 50,
            divisions: 50,
            activeColor: DesignTokens.primaryGreen,
            inactiveColor: DesignTokens.borderDefault,
            onChanged: (v) => setState(() => _commissionRange = v),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '0%',
                  style: TextStyle(
                    fontFamily: DesignTokens.fontFamily,
                    fontSize: 12,
                    color: DesignTokens.textMuted,
                  ),
                ),
                Text(
                  '50%',
                  style: TextStyle(
                    fontFamily: DesignTokens.fontFamily,
                    fontSize: 12,
                    color: DesignTokens.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
