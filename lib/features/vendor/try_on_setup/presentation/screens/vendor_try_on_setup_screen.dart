import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stylemint_mobile_frontend/features/customer/try_on/domain/entities/try_on_failure.dart';
import 'package:stylemint_mobile_frontend/features/vendor/try_on_setup/domain/entities/vendor_try_on.dart';
import 'package:stylemint_mobile_frontend/features/vendor/try_on_setup/presentation/notifiers/vendor_try_on_setup_notifier.dart';
import 'package:stylemint_mobile_frontend/features/vendor/try_on_setup/presentation/widgets/size_chart_editor.dart';
import 'package:stylemint_mobile_frontend/features/vendor/try_on_setup/presentation/widgets/try_on_image_uploader.dart';
import 'package:stylemint_mobile_frontend/features/vendor/try_on_setup/shared/providers.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_snackbar.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// "Try-on & sizes" for one product: readiness badge, size chart editor and
/// the try-on image. Reached from the Add/Edit Product wizard.
class VendorTryOnSetupScreen extends ConsumerStatefulWidget {
  const VendorTryOnSetupScreen({
    required this.productId,
    this.categoryName,
    super.key,
  });

  final String productId;

  /// Used to say whether a size chart is required (apparel) or optional.
  final String? categoryName;

  @override
  ConsumerState<VendorTryOnSetupScreen> createState() =>
      _VendorTryOnSetupScreenState();
}

class _VendorTryOnSetupScreenState
    extends ConsumerState<VendorTryOnSetupScreen> {
  SizeChart? _draft;
  bool _showErrors = false;
  bool _saving = false;
  String? _chartError;

  VendorTryOnSetupNotifier get _notifier =>
      ref.read(vendorTryOnSetupNotifierProvider(widget.productId).notifier);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_notifier.load());
    });
  }

  static String _message(TryOnFailure f) =>
      f.kind == TryOnFailureKind.rejected && f.message != null
      ? f.message!
      : f.displayMessage;

  Future<void> _saveChart() async {
    final chart = _draft;
    if (chart == null) return;
    setState(() {
      _showErrors = true;
      _chartError = null;
    });
    if (SizeChartRules.validate(chart).isNotEmpty) return;
    setState(() => _saving = true);
    final failure = await _notifier.saveChart(chart);
    if (!mounted) return;
    setState(() {
      _saving = false;
      _chartError = failure == null ? null : _message(failure);
    });
    if (failure == null) SmSnackbar.success(context, 'Size chart saved');
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(vendorTryOnSetupNotifierProvider(widget.productId));
    return Scaffold(
      backgroundColor: DesignTokens.bgAppFoundation,
      appBar: AppBar(
        backgroundColor: DesignTokens.bgAppFoundation,
        title: const Text(
          'Try-on & sizes',
          style: DesignTokens.sectionInnerTitle,
        ),
      ),
      body: state.when(
        initial: _loader,
        loadInProgress: _loader,
        loadFailure: (f) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                f.displayMessage,
                style: const TextStyle(color: DesignTokens.textLight),
              ),
              TextButton(
                onPressed: () => unawaited(_notifier.load()),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        loadSuccess: _body,
      ),
    );
  }

  Widget _loader() => const Center(
    child: CircularProgressIndicator(color: DesignTokens.primaryGreen),
  );

  Widget _body(VendorTryOnData data) {
    final apparel = isSizedApparel(categoryName: widget.categoryName);
    final chart =
        _draft ??
        data.chart ??
        SizeChartEditor.blank(data.readiness.garmentType ?? GarmentType.top);
    _draft ??= chart;
    return ListView(
      padding: const EdgeInsets.all(DesignTokens.s16),
      children: [
        TryOnReadinessBadge(readiness: data.readiness),
        const SizedBox(height: DesignTokens.s24),
        _Section(
          title: 'Size chart',
          subtitle: apparel
              ? 'Required for clothing and shoes before you publish.'
              : 'Optional — helps buyers pick the right size.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizeChartEditor(
                // Rebuild from the server's copy after a save.
                key: ValueKey(data.chart?.updatedUtc),
                initial: chart,
                showErrors: _showErrors,
                onChanged: (c) => setState(() => _draft = c),
              ),
              if (_chartError case final String e)
                Text(
                  e,
                  key: const Key('chart-server-error'),
                  style: DesignTokens.smallRegular.copyWith(
                    color: DesignTokens.colorError,
                  ),
                ),
              const SizedBox(height: DesignTokens.s8),
              Row(
                children: [
                  ElevatedButton(
                    key: const Key('chart-save'),
                    style: DesignTokens.primaryButtonStyle(),
                    onPressed: _saving ? null : () => unawaited(_saveChart()),
                    child: _saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Save size chart'),
                  ),
                  if (data.chart != null) ...[
                    const SizedBox(width: DesignTokens.s8),
                    TextButton(
                      onPressed: () async {
                        final f = await _notifier.deleteChart();
                        if (!mounted) return;
                        if (f == null) {
                          setState(() => _draft = null);
                        } else {
                          SmSnackbar.error(context, _message(f));
                        }
                      },
                      child: const Text('Delete chart'),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: DesignTokens.s24),
        _Section(
          title: 'Try-on image',
          subtitle:
              'Strongly recommended — without it buyers can only get size '
              'advice, not see the item on themselves.',
          child: TryOnImageUploader(
            currentImageUrl: data.readiness.imageUrl,
            onUpload: (path, progress) async {
              final f = await _notifier.uploadImage(path, onProgress: progress);
              return f == null ? null : _message(f);
            },
            onDelete: () async {
              final f = await _notifier.deleteImage();
              return f == null ? null : _message(f);
            },
          ),
        ),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title,
        style: DesignTokens.mediumSemibold.copyWith(
          color: DesignTokens.textWhite,
        ),
      ),
      Text(
        subtitle,
        style: DesignTokens.smallRegular.copyWith(
          color: DesignTokens.textMuted,
        ),
      ),
      const SizedBox(height: DesignTokens.s12),
      child,
    ],
  );
}

/// Ready / not ready, with the server's reasons.
class TryOnReadinessBadge extends StatelessWidget {
  const TryOnReadinessBadge({required this.readiness, super.key});

  final TryOnReadiness readiness;

  @override
  Widget build(BuildContext context) {
    final ready = readiness.ready;
    return Container(
      key: const Key('try-on-readiness'),
      padding: const EdgeInsets.all(DesignTokens.s12),
      decoration: BoxDecoration(
        color: ready
            ? DesignTokens.statusCompletedBg
            : DesignTokens.warningFillDark,
        borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                ready
                    ? Icons.check_circle_rounded
                    : Icons.error_outline_rounded,
                color: ready
                    ? DesignTokens.colorSuccess
                    : DesignTokens.colorWarning,
              ),
              const SizedBox(width: DesignTokens.s8),
              Text(
                ready ? 'Try-on ready' : 'Not try-on ready yet',
                style: DesignTokens.mediumSemibold.copyWith(
                  color: DesignTokens.textWhite,
                ),
              ),
            ],
          ),
          const SizedBox(height: DesignTokens.s4),
          Text(
            '${readiness.hasSizeChart ? '✓' : '✗'} Size chart   '
            '${readiness.hasTryOnImage ? '✓' : '✗'} Try-on image',
            style: DesignTokens.smallRegular.copyWith(
              color: DesignTokens.textLight,
            ),
          ),
          for (final p in readiness.problems)
            Text(
              '• $p',
              style: DesignTokens.smallRegular.copyWith(
                color: DesignTokens.warningTextLight,
              ),
            ),
        ],
      ),
    );
  }
}
