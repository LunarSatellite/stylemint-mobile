import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stylemint_mobile_frontend/features/customer/services/domain/entities/bookings.dart';
import 'package:stylemint_mobile_frontend/features/customer/services/domain/entities/service_line.dart';
import 'package:stylemint_mobile_frontend/features/customer/services/domain/service_messages.dart';
import 'package:stylemint_mobile_frontend/features/customer/services/presentation/widgets/service_line_widgets.dart';
import 'package:stylemint_mobile_frontend/features/customer/services/presentation/widgets/service_widgets.dart';
import 'package:stylemint_mobile_frontend/features/customer/services/shared/service_cart_providers.dart';
import 'package:stylemint_mobile_frontend/features/customer/services/shared/services_providers.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';
import 'package:uuid/uuid.dart';

/// 2–100 characters, as the server checks (service cart contract v1 §3.3).
String? validGuestName(String? raw) {
  final v = raw?.trim() ?? '';
  if (v.length < 2) return 'Enter the full name';
  if (v.length > 100) return 'Use at most 100 characters';
  return null;
}

/// Checkout's stays and trips: each line's room or trip, dates and money,
/// and the names the hotel or agency needs — the guest the stay is under,
/// every traveller on a trip (adults then children), and any request. The
/// vendor sees these names only, never the buyer's phone or email.
///
/// [CheckoutServiceGuestsState.save] sends them before the order is placed
/// (the server refuses to place without them); the page calls it from
/// Place order.
class CheckoutServiceGuests extends ConsumerStatefulWidget {
  const CheckoutServiceGuests({
    required this.sessionId,
    required this.lines,
    this.lineErrors = const {},
    this.onSaved,
    super.key,
  });

  final String? sessionId;
  final List<ServiceLine> lines;

  /// Per cart line id: why the server could not hold or place it.
  final Map<String, String> lineErrors;

  /// The session's service lines as the server saved them.
  final ValueChanged<List<ServiceLine>>? onSaved;

  static Key guestKey(String lineId) => Key('checkout-guest-$lineId');
  static Key travellerKey(String lineId, int i) =>
      Key('checkout-traveller-$lineId-$i');
  static Key requestsKey(String lineId) => Key('checkout-requests-$lineId');
  static Key lineErrorKey(String lineId) => Key('checkout-line-error-$lineId');
  static const Key errorKey = Key('checkout-guests-error');

  @override
  ConsumerState<CheckoutServiceGuests> createState() =>
      CheckoutServiceGuestsState();
}

class CheckoutServiceGuestsState extends ConsumerState<CheckoutServiceGuests> {
  final _formKey = GlobalKey<FormState>();
  final _guest = <String, TextEditingController>{};
  final _travellers = <String, List<TextEditingController>>{};
  final _requests = <String, TextEditingController>{};
  String? _error;
  bool _dirty = false;

  @override
  void dispose() {
    for (final c in [
      ..._guest.values,
      ..._requests.values,
      for (final list in _travellers.values) ...list,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  String _id(ServiceLine l) => l.lineId ?? l.bookingId ?? l.listingId;

  TextEditingController _guestFor(ServiceLine l) => _guest.putIfAbsent(
    _id(l),
    () => _watched(
      TextEditingController(
        text: l.guestName ?? ref.read(servicesBuyerNameProvider) ?? '',
      ),
    ),
  );

  TextEditingController _requestsFor(ServiceLine l) => _requests.putIfAbsent(
    _id(l),
    () => _watched(TextEditingController(text: l.specialRequests ?? '')),
  );

  /// A trip names every traveller: adults first, then children (§3.3).
  List<TextEditingController> _travellersFor(ServiceLine l) =>
      _travellers.putIfAbsent(_id(l), () {
        final saved = l.travellers;
        return [
          for (var i = 0; i < l.guests; i++)
            _watched(
              TextEditingController(
                text: i < saved.length
                    ? saved[i].fullName
                    : (i == 0
                          ? l.guestName ??
                                ref.read(servicesBuyerNameProvider) ??
                                ''
                          : ''),
              ),
            ),
        ];
      });

  TextEditingController _watched(TextEditingController c) =>
      c..addListener(() => _dirty = true);

  TravellerType _typeAt(ServiceLine l, int i) =>
      i < l.adults ? TravellerType.adult : TravellerType.child;

  /// Validates every name and sends them. True when the server has them all
  /// (nothing is sent when they were already saved and nothing changed).
  Future<bool> save() async {
    final lines = widget.lines;
    if (lines.isEmpty) return true;
    final valid = _formKey.currentState?.validate() ?? false;
    if (!valid) {
      setState(() => _error = 'Add the missing names above.');
      return false;
    }
    if (!_dirty && lines.every((l) => l.guestsComplete)) return true;
    final sessionId = widget.sessionId;
    if (sessionId == null || sessionId.isEmpty) {
      setState(() => _error = 'Checkout has expired. Go back and start again.');
      return false;
    }
    setState(() => _error = null);
    final result = await ref
        .read(serviceCartRepositoryProvider)
        .setGuests(
          sessionId: sessionId,
          idempotencyKey: const Uuid().v4(),
          lines: [
            for (final l in lines)
              ServiceGuests(
                lineId: _id(l),
                guestName: _guestFor(l).text,
                travellers: l.isStay
                    ? const []
                    : [
                        for (final (i, c) in _travellersFor(l).indexed)
                          Traveller(fullName: c.text, type: _typeAt(l, i)),
                      ],
                specialRequests: _requestsFor(l).text,
              ),
          ],
        );
    if (!mounted) return false;
    return result.fold(
      (failure) {
        setState(
          () => _error = serviceFailureMessage(failure, what: 'the names'),
        );
        return false;
      },
      (saved) {
        _dirty = false;
        widget.onSaved?.call(saved);
        return true;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final lines = widget.lines;
    if (lines.isEmpty) return const SizedBox.shrink();
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Stays and trips', style: DesignTokens.sectionInnerTitle),
          const SizedBox(height: DesignTokens.s4),
          Text(
            'The hotel or agency sees these names, never your phone or email.',
            style: DesignTokens.tiny.copyWith(color: DesignTokens.textMuted),
          ),
          const SizedBox(height: DesignTokens.s12),
          for (final l in lines) ...[
            _line(l),
            const SizedBox(height: DesignTokens.s12),
          ],
          if (_error != null)
            Text(
              _error!,
              key: CheckoutServiceGuests.errorKey,
              style: DesignTokens.smallRegular.copyWith(
                color: DesignTokens.colorError,
              ),
            ),
        ],
      ),
    );
  }

  Widget _line(ServiceLine l) {
    final id = _id(l);
    final lineError = widget.lineErrors[id];
    final hold = l.holdExpiresAt;
    return ServiceCard(
      borderColor: lineError == null ? null : DesignTokens.colorError,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l.listingTitle, style: DesignTokens.mediumSemibold),
          ServiceLineSummary(line: l),
          if (hold != null)
            Text(
              'Held until ${serviceInstant(hold)}.',
              style: DesignTokens.tiny.copyWith(color: DesignTokens.textLight),
            ),
          if (lineError != null)
            Padding(
              padding: const EdgeInsets.only(top: DesignTokens.s4),
              child: Text(
                lineError,
                key: CheckoutServiceGuests.lineErrorKey(id),
                style: DesignTokens.smallRegular.copyWith(
                  color: DesignTokens.colorError,
                ),
              ),
            ),
          const SizedBox(height: DesignTokens.s12),
          TextFormField(
            key: CheckoutServiceGuests.guestKey(id),
            controller: _guestFor(l),
            textCapitalization: TextCapitalization.words,
            decoration: serviceInputDecoration(
              l.isStay ? 'Booking under the name' : 'Lead traveller',
            ),
            validator: validGuestName,
          ),
          if (!l.isStay)
            for (final (i, c) in _travellersFor(l).indexed)
              Padding(
                padding: const EdgeInsets.only(top: DesignTokens.s8),
                child: TextFormField(
                  key: CheckoutServiceGuests.travellerKey(id, i),
                  controller: c,
                  textCapitalization: TextCapitalization.words,
                  decoration: serviceInputDecoration(
                    'Traveller ${i + 1} (${_typeAt(l, i).label.toLowerCase()})',
                  ),
                  validator: validGuestName,
                ),
              ),
          const SizedBox(height: DesignTokens.s8),
          TextFormField(
            key: CheckoutServiceGuests.requestsKey(id),
            controller: _requestsFor(l),
            maxLength: 1000,
            maxLines: 2,
            decoration: serviceInputDecoration(
              'Requests for the ${l.isStay ? 'hotel' : 'agency'} (optional)',
            ),
          ),
        ],
      ),
    );
  }
}

/// Why checkout could not start or place: the stays and trips the server
/// could not hold (service cart contract v1 §3.1 — `errors[]`, one per cart
/// line, `code` = the reason).
Map<String, String> serviceLineErrors(
  Iterable<({String field, String code, String message})> errors,
) => {
  for (final e in errors)
    if (e.field.isNotEmpty)
      e.field: e.code.isEmpty
          ? (e.message.isEmpty ? 'Not available any more.' : e.message)
          : quoteUnavailableMessage(e.code == 'not_bookable' ? null : e.code),
};
