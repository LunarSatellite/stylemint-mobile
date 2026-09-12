import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/domain/entities/product_detail.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/shared/providers.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_error_view.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// Voyager "Mission-Based Shopping": the customer describes a goal in plain
/// language ("set up a home office under Rs 10,000") and gets back a small,
/// real, in-stock shopping list rather than a bare search-result page.
class MissionShoppingScreen extends ConsumerStatefulWidget {
  const MissionShoppingScreen({super.key});

  @override
  ConsumerState<MissionShoppingScreen> createState() =>
      _MissionShoppingScreenState();
}

class _MissionShoppingScreenState
    extends ConsumerState<MissionShoppingScreen> {
  final _missionController = TextEditingController();
  final _budgetController = TextEditingController();

  bool _loading = false;
  String? _error;
  MissionShoppingPlan? _plan;

  @override
  void dispose() {
    _missionController.dispose();
    _budgetController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final mission = _missionController.text.trim();
    if (mission.isEmpty) return;

    final budgetText = _budgetController.text.trim();
    final budget = budgetText.isEmpty ? null : double.tryParse(budgetText);

    setState(() {
      _loading = true;
      _error = null;
    });

    final result = await ref
        .read(discoveryRepositoryProvider)
        .getMissionShoppingPlan(missionText: mission, budgetAmount: budget);

    if (!mounted) return;
    result.fold(
      (failure) => setState(() {
        _loading = false;
        _error = 'Could not build a shopping plan. Try again.';
      }),
      (plan) => setState(() {
        _loading = false;
        _plan = plan;
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignTokens.bgAppFoundation,
      appBar: AppBar(
        backgroundColor: DesignTokens.bgAppFoundation,
        title: Text('Shop by Mission', style: DesignTokens.titleLarge),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(DesignTokens.s16),
          children: [
            Text(
              'Tell us what you\'re trying to do, and we\'ll put together a real, in-stock shopping list.',
              style: DesignTokens.mediumRegular.copyWith(
                color: DesignTokens.textLight,
              ),
            ),
            const SizedBox(height: DesignTokens.s16),
            TextField(
              controller: _missionController,
              maxLines: 2,
              style: DesignTokens.mediumRegular.copyWith(
                color: DesignTokens.textWhite,
              ),
              decoration: InputDecoration(
                hintText: 'e.g. "Set up a home office"',
                hintStyle: DesignTokens.mediumRegular.copyWith(
                  color: DesignTokens.inputFieldPlaceholder,
                ),
                filled: true,
                fillColor: DesignTokens.inputFieldFill,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: DesignTokens.s16,
                  vertical: DesignTokens.s12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(DesignTokens.inputRadius),
                  borderSide: const BorderSide(color: DesignTokens.inputFieldBorder),
                ),
              ),
            ),
            const SizedBox(height: DesignTokens.s12),
            TextField(
              controller: _budgetController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: DesignTokens.mediumRegular.copyWith(
                color: DesignTokens.textWhite,
              ),
              decoration: InputDecoration(
                hintText: 'Budget in NPR (optional)',
                hintStyle: DesignTokens.mediumRegular.copyWith(
                  color: DesignTokens.inputFieldPlaceholder,
                ),
                filled: true,
                fillColor: DesignTokens.inputFieldFill,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: DesignTokens.s16,
                  vertical: DesignTokens.s12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(DesignTokens.inputRadius),
                  borderSide: const BorderSide(color: DesignTokens.inputFieldBorder),
                ),
              ),
            ),
            const SizedBox(height: DesignTokens.s16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: DesignTokens.primaryGreen,
                  padding: const EdgeInsets.symmetric(vertical: DesignTokens.s12),
                ),
                child: _loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Build My Shopping List'),
              ),
            ),
            const SizedBox(height: DesignTokens.s24),
            if (_error != null)
              SmErrorView(message: _error!, onRetry: _submit),
            if (_plan != null) _MissionPlanResult(plan: _plan!),
          ],
        ),
      ),
    );
  }
}

class _MissionPlanResult extends StatelessWidget {
  const _MissionPlanResult({required this.plan});

  final MissionShoppingPlan plan;

  @override
  Widget build(BuildContext context) {
    if (plan.items.isEmpty) {
      return Text(
        plan.missionSummary,
        style: DesignTokens.mediumRegular.copyWith(color: DesignTokens.textLight),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          plan.missionSummary,
          style: DesignTokens.mediumSemibold.copyWith(
            color: DesignTokens.textWhite,
          ),
        ),
        const SizedBox(height: DesignTokens.s12),
        for (final item in plan.items) ...[
          _MissionItemCard(item: item),
          const SizedBox(height: DesignTokens.s8),
        ],
        const SizedBox(height: DesignTokens.s8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Total',
              style: DesignTokens.mediumSemibold.copyWith(
                color: DesignTokens.textWhite,
              ),
            ),
            Text(
              '${plan.totalEstimatedCost.toStringAsFixed(2)} ${plan.currency}',
              style: DesignTokens.mediumSemibold.copyWith(
                color: plan.withinBudget
                    ? DesignTokens.primaryGreen
                    : DesignTokens.colorWarning,
              ),
            ),
          ],
        ),
        if (plan.budgetAmount != null && !plan.withinBudget)
          Padding(
            padding: const EdgeInsets.only(top: DesignTokens.s4),
            child: Text(
              'This is above your ${plan.budgetAmount!.toStringAsFixed(0)} ${plan.currency} budget.',
              style: DesignTokens.smallRegular.copyWith(
                color: DesignTokens.colorWarning,
              ),
            ),
          ),
      ],
    );
  }
}

class _MissionItemCard extends StatelessWidget {
  const _MissionItemCard({required this.item});

  final MissionShoppingItem item;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push(
        RouteNames.productDetail.replaceFirst(':productId', item.productId),
      ),
      child: Container(
        padding: const EdgeInsets.all(DesignTokens.s12),
        decoration: BoxDecoration(
          color: DesignTokens.bgAppBodyLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: DesignTokens.borderDefault),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: item.thumbnailUrl != null && item.thumbnailUrl!.isNotEmpty
                  ? Image.network(
                      item.thumbnailUrl!,
                      width: 56,
                      height: 56,
                      fit: BoxFit.cover,
                    )
                  : Container(
                      width: 56,
                      height: 56,
                      color: DesignTokens.bgAppFoundation,
                      child: const Icon(Icons.image_not_supported_outlined),
                    ),
            ),
            const SizedBox(width: DesignTokens.s12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: DesignTokens.mediumSemibold.copyWith(
                      color: DesignTokens.textWhite,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: DesignTokens.s4),
                  Text(
                    item.reason,
                    style: DesignTokens.smallRegular.copyWith(
                      color: DesignTokens.textLight,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: DesignTokens.s8),
            Text(
              item.priceAmount.toStringAsFixed(0),
              style: DesignTokens.mediumSemibold.copyWith(
                color: DesignTokens.primaryGreen,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
