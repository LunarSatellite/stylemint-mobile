import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:stylemint_mobile_frontend/core/utils/format_money.dart';
import 'package:stylemint_mobile_frontend/features/customer/services/domain/entities/service_failure.dart';
import 'package:stylemint_mobile_frontend/features/customer/services/domain/service_messages.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_empty_state.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_error_view.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// Whole rupees without decimals, anything else with two.
String serviceMoney(Money money) => formatMoney(
  money,
  decimalDigits: money.amount == money.amount.roundToDouble() ? 0 : 2,
);

/// A stay or departure date is a calendar date, not an instant: shown as it
/// is, never shifted by the device's time zone.
String serviceDate(DateTime date) =>
    DateFormat.yMMMd().format(DateTime(date.year, date.month, date.day));

/// "Sat, 24 Oct" — for check-in and check-out chips.
String serviceShortDate(DateTime date) =>
    DateFormat('EEE, d MMM').format(DateTime(date.year, date.month, date.day));

/// An instant, in the device's own time.
String serviceInstant(DateTime instant) =>
    DateFormat.yMMMd().add_jm().format(instant.toLocal());

/// `yyyy-MM-dd`, the wire form of a calendar date.
String serviceWireDate(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-'
    '${date.month.toString().padLeft(2, '0')}-'
    '${date.day.toString().padLeft(2, '0')}';

/// The bordered card every Services surface uses. A [Material], so list
/// tiles and radios inside it show their ripple.
class ServiceCard extends StatelessWidget {
  const ServiceCard({
    required this.child,
    this.borderColor,
    this.padding = const EdgeInsets.all(DesignTokens.s16),
    super.key,
  });

  final Widget child;
  final Color? borderColor;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    child: Material(
      color: DesignTokens.bgAppBody,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
        side: BorderSide(color: borderColor ?? DesignTokens.borderDefault),
      ),
      child: Padding(padding: padding, child: child),
    ),
  );
}

/// A label and a figure on one line. The figure shrinks rather than
/// truncates: an ellipsised amount reads as a different number.
class ServiceRow extends StatelessWidget {
  const ServiceRow({
    required this.label,
    required this.value,
    this.emphasised = false,
    this.valueKey,
    super.key,
  });

  final String label;
  final String value;
  final bool emphasised;
  final Key? valueKey;

  @override
  Widget build(BuildContext context) {
    final style = emphasised
        ? DesignTokens.mediumSemibold
        : DesignTokens.smallRegular;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: DesignTokens.s4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: style.copyWith(
                color: emphasised ? DesignTokens.textWhite : DesignTokens.textMuted,
              ),
            ),
          ),
          const SizedBox(width: DesignTokens.s8),
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerRight,
              child: Text(value, key: valueKey, style: style),
            ),
          ),
        ],
      ),
    );
  }
}

/// A section heading inside a Services page.
class ServiceSectionTitle extends StatelessWidget {
  const ServiceSectionTitle(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(
      top: DesignTokens.s20,
      bottom: DesignTokens.s8,
    ),
    child: Text(text, style: DesignTokens.h3),
  );
}

/// A small coloured label: a booking's status, a product type.
class ServiceChip extends StatelessWidget {
  const ServiceChip({
    required this.label,
    this.color = DesignTokens.primaryGreen,
    super.key,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(
      horizontal: DesignTokens.s8,
      vertical: DesignTokens.s4,
    ),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.14),
      borderRadius: BorderRadius.circular(DesignTokens.radiusSmall),
    ),
    child: Text(
      label,
      style: DesignTokens.tiny.copyWith(
        color: color,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}

/// A bulleted line, for amenities, inclusions, documents and policies.
class ServiceBullet extends StatelessWidget {
  const ServiceBullet(
    this.text, {
    this.icon = Icons.check_rounded,
    this.color = DesignTokens.primaryGreen,
    super.key,
  });

  final String text;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: DesignTokens.s8),
        Expanded(child: Text(text, style: DesignTokens.smallRegular)),
      ],
    ),
  );
}

/// A network photo with a quiet placeholder, or the placeholder alone when
/// there is no photo.
class ServicePhoto extends StatelessWidget {
  const ServicePhoto({
    required this.url,
    this.height = 160,
    this.width = double.infinity,
    this.icon = Icons.photo_outlined,
    this.radius = DesignTokens.cardRadius,
    super.key,
  });

  final String? url;
  final double height;
  final double width;
  final IconData icon;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final placeholder = Container(
      height: height,
      width: width,
      color: DesignTokens.surfaceRaised,
      alignment: Alignment.center,
      child: Icon(icon, color: DesignTokens.textMuted),
    );
    final src = url;
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: src == null || src.isEmpty
          ? placeholder
          : CachedNetworkImage(
              imageUrl: src,
              height: height,
              width: width,
              fit: BoxFit.cover,
              placeholder: (_, _) => placeholder,
              errorWidget: (_, _, _) => placeholder,
            ),
    );
  }
}

/// What a Services screen shows when its data could not be read.
///
/// A 404 without an `errorCode` means the backend is not deployed yet, and
/// reads as "Services are coming soon" — never an error, never a crash.
class ServiceFailureView extends StatelessWidget {
  const ServiceFailureView({
    required this.error,
    this.onRetry,
    this.what = 'this',
    this.compact = false,
    super.key,
  });

  /// A provider's error: a [ServiceLoadException], or anything else.
  final Object error;
  final VoidCallback? onRetry;

  /// What failed to load, for the generic sentence.
  final String what;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final failure = serviceFailureOf(error);
    if (failure.isComingSoon) return ServicesComingSoon(compact: compact);
    if (failure.isNotFound) {
      return SmEmptyState(
        key: const Key('service-not-found'),
        title: 'Not available',
        message: serviceFailureMessage(failure, what: what),
        kind: SmEmptyKind.notApplicable,
        compact: compact,
      );
    }
    return SmErrorView(
      key: const Key('service-error'),
      message: serviceFailureMessage(failure, what: what),
      onRetry: onRetry,
      compact: compact,
    );
  }
}

/// The calm "being set up" state for a Services area whose endpoints are
/// not live yet.
class ServicesComingSoon extends StatelessWidget {
  const ServicesComingSoon({this.compact = false, super.key});

  static const Key viewKey = Key('services-coming-soon');

  final bool compact;

  @override
  Widget build(BuildContext context) => SmEmptyState(
    key: viewKey,
    title: 'Services are coming soon',
    message:
        'Hotels, travel packages and bank services are being set up. '
        'Check back shortly.',
    icon: Icons.luggage_outlined,
    kind: SmEmptyKind.notApplicable,
    compact: compact,
  );
}

/// A − n + stepper for guests, rooms, travellers.
class ServiceCounter extends StatelessWidget {
  const ServiceCounter({
    required this.label,
    required this.value,
    required this.onChanged,
    this.min = 0,
    this.max = 20,
    this.caption,
    this.keyPrefix,
    super.key,
  });

  final String label;
  final int value;
  final ValueChanged<int> onChanged;
  final int min;
  final int max;
  final String? caption;

  /// Gives the buttons and value keys `<prefix>-minus`, `<prefix>-plus`,
  /// `<prefix>-value`.
  final String? keyPrefix;

  @override
  Widget build(BuildContext context) {
    final prefix = keyPrefix ?? label.toLowerCase();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: DesignTokens.s4),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: DesignTokens.smallRegular),
                if (caption != null)
                  Text(
                    caption!,
                    style: DesignTokens.tiny.copyWith(
                      color: DesignTokens.textMuted,
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            key: Key('$prefix-minus'),
            onPressed: value > min ? () => onChanged(value - 1) : null,
            icon: const Icon(Icons.remove_circle_outline),
            color: DesignTokens.textLight,
            tooltip: 'Fewer',
          ),
          SizedBox(
            width: 28,
            child: Text(
              '$value',
              key: Key('$prefix-value'),
              textAlign: TextAlign.center,
              style: DesignTokens.mediumSemibold,
            ),
          ),
          IconButton(
            key: Key('$prefix-plus'),
            onPressed: value < max ? () => onChanged(value + 1) : null,
            icon: const Icon(Icons.add_circle_outline),
            color: DesignTokens.textLight,
            tooltip: 'More',
          ),
        ],
      ),
    );
  }
}

/// The full-width primary button at the foot of a Services flow.
class ServicePrimaryButton extends StatelessWidget {
  const ServicePrimaryButton({
    required this.label,
    required this.onPressed,
    this.busy = false,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool busy;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    height: DesignTokens.buttonHeight,
    child: FilledButton(
      onPressed: busy ? null : onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: DesignTokens.buttonPrimaryFill,
        foregroundColor: DesignTokens.buttonPrimaryText,
        disabledBackgroundColor: DesignTokens.buttonGrayFill,
        disabledForegroundColor: DesignTokens.buttonGrayText,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.buttonRadius),
        ),
      ),
      child: busy
          ? const SizedBox.square(
              dimension: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Text(label),
    ),
  );
}

/// A form field in the Services style.
InputDecoration serviceInputDecoration(String label, {String? hint}) =>
    InputDecoration(
      labelText: label,
      hintText: hint,
      filled: true,
      fillColor: DesignTokens.inputFieldFill,
      labelStyle: DesignTokens.smallRegular.copyWith(
        color: DesignTokens.inputFieldLabel,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(DesignTokens.inputRadius),
        borderSide: const BorderSide(color: DesignTokens.inputFieldBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(DesignTokens.inputRadius),
        borderSide: const BorderSide(color: DesignTokens.inputFieldBorder),
      ),
    );
