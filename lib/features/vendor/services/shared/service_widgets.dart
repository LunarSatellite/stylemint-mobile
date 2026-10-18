import 'package:flutter/material.dart';
import 'package:stylemint_mobile_frontend/core/utils/format_money.dart';
import 'package:stylemint_mobile_frontend/features/vendor/services/shared/service_failure.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_error_view.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// "Rs 12,500" — whole rupees without decimals, paisa when there are any.
String serviceMoney(Money money) => formatMoney(
  money,
  decimalDigits: money.amount == money.amount.roundToDouble() ? 0 : 2,
);

/// Shown while a service endpoint 404s because the backend is not deployed
/// yet. Never an error, never a crash.
class ServiceSettingUpView extends StatelessWidget {
  const ServiceSettingUpView({
    required this.title,
    this.message =
        'This part of your seller app is being set up. Check back shortly.',
    super.key,
  });

  static const Key viewKey = Key('service-setting-up');

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) => Padding(
    key: viewKey,
    padding: const EdgeInsets.all(DesignTokens.s24),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(
          Icons.construction_rounded,
          size: 40,
          color: DesignTokens.textMuted,
        ),
        const SizedBox(height: DesignTokens.s12),
        Text(
          title,
          style: DesignTokens.mediumSemibold,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: DesignTokens.s4),
        Text(
          message,
          style: DesignTokens.smallRegular.copyWith(
            color: DesignTokens.textMuted,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    ),
  );
}

/// What a failed load shows: "being set up" for a 404 of a route that is
/// not deployed, otherwise a retryable error.
class ServiceLoadFailureView extends StatelessWidget {
  const ServiceLoadFailureView({
    required this.error,
    required this.settingUpTitle,
    required this.onRetry,
    this.fallback = 'We could not load this.',
    this.specific,
    super.key,
  });

  final Object error;
  final String settingUpTitle;
  final VoidCallback onRetry;
  final String fallback;
  final String? Function(String code)? specific;

  @override
  Widget build(BuildContext context) {
    if (serviceUnavailable(error)) {
      return ServiceSettingUpView(title: settingUpTitle);
    }
    final failure = serviceFailureOf(error);
    return SmErrorView(
      message: failure == null
          ? fallback
          : serviceFailureMessage(
              failure,
              specific: specific,
              fallback: fallback,
            ),
      onRetry: onRetry,
    );
  }
}

/// A rounded card on the raised surface.
class ServiceCard extends StatelessWidget {
  const ServiceCard({
    required this.child,
    this.borderColor,
    this.padding = const EdgeInsets.all(DesignTokens.s16),
    super.key,
  });

  final Widget child;
  final Color? borderColor;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: padding,
    decoration: BoxDecoration(
      color: DesignTokens.bgAppBody,
      borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
      border: Border.all(color: borderColor ?? DesignTokens.borderDefault),
    ),
    child: child,
  );
}

/// A label on the left, a value on the right.
class ServiceRow extends StatelessWidget {
  const ServiceRow({
    required this.label,
    required this.value,
    this.emphasised = false,
    this.valueColor,
    super.key,
  });

  final String label;
  final String value;
  final bool emphasised;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            label,
            style: DesignTokens.smallRegular.copyWith(
              color: DesignTokens.textMuted,
            ),
          ),
        ),
        const SizedBox(width: DesignTokens.s12),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style:
                (emphasised
                        ? DesignTokens.mediumSemibold
                        : DesignTokens.smallRegular)
                    .copyWith(color: valueColor),
          ),
        ),
      ],
    ),
  );
}

/// A section heading inside a screen.
class ServiceSectionTitle extends StatelessWidget {
  const ServiceSectionTitle(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(
      top: DesignTokens.s20,
      bottom: DesignTokens.s8,
    ),
    child: Text(text, style: DesignTokens.mediumSemibold),
  );
}

/// Pill tones.
enum ServicePillTone { neutral, info, success, warning, error }

/// A small coloured status pill.
class ServicePill extends StatelessWidget {
  const ServicePill(this.label, {this.tone = ServicePillTone.neutral, super.key});

  final String label;
  final ServicePillTone tone;

  @override
  Widget build(BuildContext context) {
    final color = switch (tone) {
      ServicePillTone.neutral => DesignTokens.textMuted,
      ServicePillTone.info => DesignTokens.colorInfo,
      ServicePillTone.success => DesignTokens.colorSuccess,
      ServicePillTone.warning => DesignTokens.colorWarning,
      ServicePillTone.error => DesignTokens.colorError,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        label,
        style: DesignTokens.tiny.copyWith(color: color),
      ),
    );
  }
}

/// A full-width primary action (Material, so it needs no size config).
class ServiceActionButton extends StatelessWidget {
  const ServiceActionButton({
    required this.label,
    required this.onPressed,
    this.icon,
    this.destructive = false,
    this.outlined = false,
    this.busy = false,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool destructive;
  final bool outlined;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final color = destructive
        ? DesignTokens.colorError
        : DesignTokens.primaryGreen;
    final child = busy
        ? const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18),
                const SizedBox(width: DesignTokens.s8),
              ],
              Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
            ],
          );
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(DesignTokens.buttonRadius),
    );
    final onTap = busy ? null : onPressed;
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: outlined
          ? OutlinedButton(
              onPressed: onTap,
              style: OutlinedButton.styleFrom(
                foregroundColor: color,
                side: BorderSide(color: color),
                shape: shape,
              ),
              child: child,
            )
          : FilledButton(
              onPressed: onTap,
              style: FilledButton.styleFrom(
                backgroundColor: color,
                foregroundColor: DesignTokens.baseBlack,
                shape: shape,
              ),
              child: child,
            ),
    );
  }
}

/// Asks for a reason (cancel, close, no-show notes). Returns the trimmed
/// text, or null when the vendor backs out. [required] keeps the confirm
/// button off until something is typed.
Future<String?> askServiceReason(
  BuildContext context, {
  required String title,
  required String confirmLabel,
  String? message,
  String hint = 'Reason',
  bool required = true,
  int maxLength = 300,
}) => showDialog<String>(
  context: context,
  builder: (_) => _ReasonDialog(
    title: title,
    confirmLabel: confirmLabel,
    message: message,
    hint: hint,
    required: required,
    maxLength: maxLength,
  ),
);

class _ReasonDialog extends StatefulWidget {
  const _ReasonDialog({
    required this.title,
    required this.confirmLabel,
    required this.hint,
    required this.required,
    required this.maxLength,
    this.message,
  });

  final String title;
  final String confirmLabel;
  final String? message;
  final String hint;
  final bool required;
  final int maxLength;

  @override
  State<_ReasonDialog> createState() => _ReasonDialogState();
}

class _ReasonDialogState extends State<_ReasonDialog> {
  final _controller = TextEditingController();


  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final text = _controller.text.trim();
    return AlertDialog(
      title: Text(widget.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.message != null) ...[
            Text(widget.message!),
            const SizedBox(height: DesignTokens.s12),
          ],
          TextField(
            key: ServiceReasonDialogKeys.field,
            controller: _controller,
            maxLength: widget.maxLength,
            maxLines: 3,
            minLines: 1,
            decoration: InputDecoration(hintText: widget.hint),
            onChanged: (_) => setState(() {}),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Back'),
        ),
        TextButton(
          key: ServiceReasonDialogKeys.confirm,
          onPressed: widget.required && text.isEmpty
              ? null
              : () => Navigator.of(context).pop(text),
          child: Text(widget.confirmLabel),
        ),
      ],
    );
  }
}

/// Keys of the reason dialog, for tests.
abstract final class ServiceReasonDialogKeys {
  static const Key field = Key('service-reason-field');
  static const Key confirm = Key('service-reason-confirm');
}

/// A yes/no confirmation. True only on the confirm button.
Future<bool> confirmServiceAction(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
}) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: const Text('Back'),
        ),
        TextButton(
          key: ServiceConfirmDialogKeys.confirm,
          onPressed: () => Navigator.of(ctx).pop(true),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return ok ?? false;
}

abstract final class ServiceConfirmDialogKeys {
  static const Key confirm = Key('service-confirm-action');
}
