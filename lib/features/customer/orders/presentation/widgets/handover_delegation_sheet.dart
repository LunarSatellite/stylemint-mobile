import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/domain/entities/handover_delegation.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/presentation/widgets/handover_delegation_copy.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/shared/providers.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/mall/mall_metrics.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';
import 'package:uuid/uuid.dart';

/// Opens the 'authorise someone to receive this parcel' flow for
/// [trackingNumber].
///
/// A **modal sheet, not a route**. That is a security decision, not a styling
/// one: the created delegation's verification code is shown inside this sheet,
/// and a route would mean a navigator entry, a possible deep link and a path
/// or query string that could carry it. The sheet owns the code in local
/// `State` and it dies with the frame.
///
/// Resolves to `true` when a delegation was created, so the caller can refresh.
Future<bool> showHandoverDelegationSheet(
  BuildContext context, {
  required String trackingNumber,
  DateTime Function()? clock,
}) async {
  final created = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: DesignTokens.bgAppBody,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => HandoverDelegationSheet(
      trackingNumber: trackingNumber,
      clock: clock,
    ),
  );
  return created ?? false;
}

/// The two-step flow: fill in who and when, then read the code once.
@visibleForTesting
class HandoverDelegationSheet extends ConsumerStatefulWidget {
  const HandoverDelegationSheet({
    required this.trackingNumber,
    super.key,
    this.clock,
  });

  final String trackingNumber;
  final DateTime Function()? clock;

  @override
  ConsumerState<HandoverDelegationSheet> createState() =>
      _HandoverDelegationSheetState();
}

class _HandoverDelegationSheetState
    extends ConsumerState<HandoverDelegationSheet> {
  final _name = TextEditingController();
  final _contact = TextEditingController();
  final _nameFocus = FocusNode();

  DelegateRelationship? _relationship;
  final Set<DelegatedException> _exceptions = <DelegatedException>{};

  late DateTime _startLocal;
  Duration _length = const Duration(hours: 4);

  bool _submitting = false;
  String? _failureCode;
  bool _showFieldErrors = false;

  /// The one-time verification code, held **only here**.
  ///
  /// A field on a `State`, not a provider, not a repository, not a cache:
  /// when this sheet is popped the object is garbage and the code is gone
  /// from the process. It is never written to `shared_preferences`, secure
  /// storage, the clipboard, a log, an analytics event or a route argument —
  /// `handover_delegation_secrecy_test.dart` fails the build if that changes.
  String? _issuedCode;
  HandoverDelegation? _issuedDelegation;

  DateTime _now() => widget.clock?.call() ?? DateTime.now().toUtc();

  @override
  void initState() {
    super.initState();
    // Default: starting now. The customer is usually setting this up because
    // a courier is on the way today.
    _startLocal = _roundToQuarter(_now().toLocal());
  }

  @override
  void dispose() {
    _name.dispose();
    _contact.dispose();
    _nameFocus.dispose();
    // Belt and braces: drop the reference before the frame is torn down.
    _issuedCode = null;
    super.dispose();
  }

  static DateTime _roundToQuarter(DateTime t) =>
      DateTime(t.year, t.month, t.day, t.hour, (t.minute ~/ 15) * 15);

  DateTime get _startUtc => _startLocal.toUtc();
  DateTime get _endUtc => _startUtc.add(_length);

  HandoverWindowProblem? get _windowProblem => validateHandoverWindow(
    startUtc: _startUtc,
    endUtc: _endUtc,
    nowUtc: _now(),
  );

  bool get _nameOk => _name.text.trim().isNotEmpty;
  bool get _contactOk => _contact.text.trim().isNotEmpty;

  bool get _canSubmit =>
      !_submitting &&
      _nameOk &&
      _contactOk &&
      _relationship != null &&
      _windowProblem == null;

  @override
  Widget build(BuildContext context) {
    final code = _issuedCode;
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: SafeArea(
        top: false,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.92,
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              DesignTokens.s16,
              DesignTokens.s12,
              DesignTokens.s16,
              DesignTokens.s24,
            ),
            child: code == null ? _form(context) : _issued(context, code),
          ),
        ),
      ),
    );
  }

  // ── Step 1: who, and when ───────────────────────────────────────────────

  Widget _form(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const _Grabber(),
      const SizedBox(height: DesignTokens.s16),
      Semantics(
        header: true,
        child: const Text(
          'Let someone else receive this parcel',
          style: DesignTokens.h3,
        ),
      ),
      const SizedBox(height: DesignTokens.s8),
      const Text(
        'You are authorising one person, for this parcel only, inside a time '
        'window you choose. You can withdraw it at any moment before the '
        'courier hands it over.',
        style: DesignTokens.mediumRegular,
      ),
      const SizedBox(height: DesignTokens.s24),

      const _SectionLabel('Who is collecting it'),
      const SizedBox(height: DesignTokens.s8),
      // Minimum viable third-party data: a name to match at the door and one
      // way to send the code. There is deliberately no contact-book import —
      // nothing leaves this form except what the customer typed.
      TextField(
        controller: _name,
        focusNode: _nameFocus,
        maxLength: 120,
        textCapitalization: TextCapitalization.words,
        onChanged: (_) => setState(() {}),
        decoration: InputDecoration(
          labelText: 'Their name',
          helperText: 'The courier reads this name out at the door.',
          helperMaxLines: 2,
          counterText: '',
          errorText: _showFieldErrors && !_nameOk
              ? 'The courier needs a name to match.'
              : null,
        ),
      ),
      const SizedBox(height: DesignTokens.s12),
      TextField(
        controller: _contact,
        keyboardType: TextInputType.emailAddress,
        maxLength: 200,
        onChanged: (_) => setState(() {}),
        decoration: InputDecoration(
          labelText: 'Their phone or email',
          helperText:
              'Used once, to send them the code. StyleMint stores only a '
              'scrambled version and never shows it again.',
          helperMaxLines: 3,
          counterText: '',
          errorText: _showFieldErrors && !_contactOk
              ? 'We need somewhere to send their code.'
              : null,
        ),
      ),
      const SizedBox(height: DesignTokens.s16),

      const _SectionLabel('How do you know them'),
      const SizedBox(height: DesignTokens.s8),
      const Text(
        'Shown to the courier so they know whom to expect. This is the only '
        'thing about them that is kept.',
        style: DesignTokens.smallDescription,
      ),
      const SizedBox(height: DesignTokens.s8),
      Wrap(
        spacing: DesignTokens.s8,
        runSpacing: DesignTokens.s8,
        children: [
          for (final r in HandoverCopy.selectableRelationships)
            ChoiceChip(
              key: ValueKey('handover-relationship-${r.name}'),
              label: Text(HandoverCopy.relationship(r)),
              selected: _relationship == r,
              onSelected: (_) => setState(() => _relationship = r),
              tooltip: HandoverCopy.relationship(r),
            ),
        ],
      ),
      if (_showFieldErrors && _relationship == null) ...[
        const SizedBox(height: DesignTokens.s8),
        const _Problem('Pick how you know them.'),
      ],
      const SizedBox(height: DesignTokens.s24),

      _WindowPicker(
        startLocal: _startLocal,
        length: _length,
        nowUtc: _now(),
        problem: _windowProblem,
        onStartChanged: (v) => setState(() => _startLocal = v),
        onLengthChanged: (v) => setState(() => _length = v),
      ),
      const SizedBox(height: DesignTokens.s24),

      _ExceptionPicker(
        delegateName: _name.text.trim(),
        chosen: _exceptions,
        onToggle: (e, {required allowed}) => setState(() {
          if (allowed) {
            _exceptions.add(e);
          } else {
            _exceptions.remove(e);
          }
        }),
      ),
      const SizedBox(height: DesignTokens.s24),

      if (_failureCode != null) ...[
        HandoverRefusalNotice(
          errorCode: _failureCode!,
          onDismiss: () => setState(() => _failureCode = null),
        ),
        const SizedBox(height: DesignTokens.s16),
      ],

      Semantics(
        button: true,
        enabled: _canSubmit,
        label: 'Authorise this person and show their one-time code',
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            key: const ValueKey('handover-authorise-button'),
            onPressed: _canSubmit ? _submit : _revealFieldErrors,
            child: _submitting
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Authorise and get the code'),
          ),
        ),
      ),
      const SizedBox(height: DesignTokens.s8),
      Semantics(
        button: true,
        label: 'Cancel without authorising anyone',
        child: SizedBox(
          width: double.infinity,
          child: TextButton(
            onPressed: _submitting
                ? null
                : () => Navigator.of(context).pop(false),
            child: const Text('Not now'),
          ),
        ),
      ),
    ],
  );

  void _revealFieldErrors() => setState(() => _showFieldErrors = true);

  Future<void> _submit() async {
    setState(() {
      _submitting = true;
      _failureCode = null;
    });
    try {
      // Called straight from this State — the issued object, and therefore
      // the code, never passes through a provider, a repository cache or a
      // notifier. It lives in `_issuedCode` and dies with this sheet.
      final issued = await ref
          .read(handoverDelegationDataSourceProvider)
          .authorise(
            trackingNumber: widget.trackingNumber,
            delegateDisplayName: _name.text,
            delegateContact: _contact.text,
            relationship: _relationship!,
            allowedExceptions: _exceptions,
            windowStartUtc: _startUtc,
            windowEndUtc: _endUtc,
            idempotencyKey: const Uuid().v4(),
          );
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _issuedCode = issued.verificationCode;
        _issuedDelegation = issued.delegation;
      });
      // The list behind the sheet is now stale. Ask it to re-read — and note
      // it is told nothing but 'go and look', never handed `issued`.
      unawaited(
        ref
            .read(
              handoverDelegationNotifierProvider(
                widget.trackingNumber,
              ).notifier,
            )
            .refresh(),
      );
    } on Object catch (error) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _failureCode =
            handoverErrorCodeOf(error) ?? 'handover.transport_failure';
      });
    }
  }

  // ── Step 2: the code, once ──────────────────────────────────────────────

  Widget _issued(BuildContext context, String code) {
    final d = _issuedDelegation;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _Grabber(),
        const SizedBox(height: DesignTokens.s16),
        Row(
          children: [
            const Icon(
              Icons.check_circle_outline_rounded,
              color: DesignTokens.primaryGreen,
              size: 22,
            ),
            const SizedBox(width: DesignTokens.s8),
            Expanded(
              child: Semantics(
                header: true,
                child: Text(
                  '${_name.text.trim()} is authorised',
                  style: DesignTokens.h3,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: DesignTokens.s16),

        _OneTimeCodePanel(code: code, delegateName: _name.text.trim()),

        const SizedBox(height: DesignTokens.s16),
        if (d != null) ...[
          _KeyFact(
            icon: Icons.schedule_rounded,
            label: 'Valid',
            value: HandoverCopy.windowSentence(
              d.windowStartUtc,
              d.windowEndUtc,
            ),
          ),
          const SizedBox(height: DesignTokens.s8),
          _KeyFact(
            icon: Icons.rule_rounded,
            label: 'They may accept',
            value: HandoverCopy.exceptionSummary(d.allowedExceptions),
          ),
          const SizedBox(height: DesignTokens.s16),
        ],
        Container(
          padding: const EdgeInsets.all(DesignTokens.s12),
          decoration: BoxDecoration(
            color: DesignTokens.bgAppBodyLight,
            borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
          ),
          child: const Text(
            'Changed your mind? Revoke this authorisation from the parcel at '
            'any time — right up to the moment of handover. If the code goes '
            'astray, revoke it and authorise someone again; a new code is '
            'issued each time.',
            style: DesignTokens.mediumRegular,
          ),
        ),
        const SizedBox(height: DesignTokens.s24),
        Semantics(
          button: true,
          label: 'I have passed the code on. Close and hide it for good.',
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              key: const ValueKey('handover-code-done-button'),
              onPressed: () {
                // Clear before popping, so not even the closing animation
                // frame still holds it.
                setState(() => _issuedCode = null);
                Navigator.of(context).pop(true);
              },
              child: const Text("I've passed it on — hide the code"),
            ),
          ),
        ),
      ],
    );
  }
}

/// Reads the backend `errorCode` out of a failed call, if there is one.
@visibleForTesting
String? handoverErrorCodeOf(Object error) {
  if (error is! DioException) return null;
  final data = error.response?.data;
  if (data is Map) {
    final code = data['errorCode'];
    if (code is String && code.trim().isNotEmpty) return code.trim();
  }
  return null;
}

/// The one-time code, drawn once.
///
/// Notes on what this widget deliberately does **not** offer:
/// * **No copy button and no `SelectableText`.** The system clipboard is
///   readable by this app (`Clipboard.getData`) and by every other app on the
///   device, and it survives long after the sheet closes. A credential that
///   opens someone's parcel does not belong there.
/// * **No QR, no link, no deep link.** The code never becomes a URL.
/// * **No screenshot prompt, no 'save to notes'.**
///
/// What it does offer is the system share sheet — the customer's own channel,
/// handed straight to the OS. Nothing written by that path is readable back by
/// this app.
class _OneTimeCodePanel extends StatelessWidget {
  const _OneTimeCodePanel({required this.code, required this.delegateName});

  final String code;
  final String delegateName;

  /// Grouped in fours so it can be read aloud over the phone without losing
  /// your place — the most common way this actually gets passed on.
  String get _grouped {
    final buffer = StringBuffer();
    for (var i = 0; i < code.length; i++) {
      if (i > 0 && i % 4 == 0) buffer.write(' ');
      buffer.write(code[i]);
    }
    return buffer.toString();
  }

  Future<void> _share() => SharePlus.instance.share(
    ShareParams(
      // Plain text only. No URL, no tracking number in a link, nothing that
      // could become a clickable route.
      text:
          'Handover code for your StyleMint parcel: $code\n'
          'Show this to the courier. It works once, and only in the '
          'window I set.',
      subject: 'StyleMint handover code',
    ),
  );

  @override
  Widget build(BuildContext context) {
    final scaler = MallMetrics.scalerOf(context);
    return Container(
      key: const ValueKey('handover-one-time-code'),
      width: double.infinity,
      padding: const EdgeInsets.all(DesignTokens.s16),
      decoration: BoxDecoration(
        color: DesignTokens.bgAppBodyLight,
        borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
        border: Border.all(color: DesignTokens.primaryGreen, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.visibility_off_outlined,
                size: 18,
                color: DesignTokens.warning300,
              ),
              const SizedBox(width: DesignTokens.s8),
              Expanded(
                child: Text(
                  'Shown once. You will not be able to see it again.',
                  style: DesignTokens.mediumRegular.copyWith(
                    color: DesignTokens.warning300,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: DesignTokens.s16),
          Semantics(
            label: 'Verification code: ${code.split('').join(' ')}',
            excludeSemantics: true,
            child: Text(
              _grouped,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: scaler.scale(28),
                height: 1.25,
                letterSpacing: 2,
                fontWeight: FontWeight.w700,
                fontFamily: 'monospace',
                color: DesignTokens.textLight,
              ),
            ),
          ),
          const SizedBox(height: DesignTokens.s16),
          Text(
            'Give this to $delegateName yourself — read it out, or send it the '
            'way you normally talk to them. StyleMint keeps no copy, so we '
            'cannot resend it.',
            style: DesignTokens.smallDescription,
          ),
          const SizedBox(height: DesignTokens.s12),
          Semantics(
            button: true,
            label: 'Send the code using another app',
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                key: const ValueKey('handover-share-code-button'),
                onPressed: _share,
                icon: const Icon(Icons.ios_share_rounded, size: 18),
                label: const Text('Send it with another app'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Start time plus length, with the resulting window written out in words.
///
/// The window is the whole safety control, so it is never left implicit: the
/// customer always sees the exact start, the exact end and how long that is,
/// and the four backend rules are checked here rather than at the server.
class _WindowPicker extends StatelessWidget {
  const _WindowPicker({
    required this.startLocal,
    required this.length,
    required this.nowUtc,
    required this.problem,
    required this.onStartChanged,
    required this.onLengthChanged,
  });

  final DateTime startLocal;
  final Duration length;
  final DateTime nowUtc;
  final HandoverWindowProblem? problem;
  final ValueChanged<DateTime> onStartChanged;
  final ValueChanged<Duration> onLengthChanged;

  static const _step = Duration(minutes: 15);
  static const _presets = <(String, Duration)>[
    ('1 hour', Duration(hours: 1)),
    ('4 hours', Duration(hours: 4)),
    ('Today', Duration(hours: 12)),
    ('3 days', Duration(hours: 72)),
  ];

  DateTime get _endLocal => startLocal.add(length);

  String get _sentence =>
      HandoverCopy.windowSentence(startLocal.toUtc(), _endLocal.toUtc());

  Future<void> _pickStart(BuildContext context) async {
    final nowLocal = nowUtc.toLocal();
    final date = await showDatePicker(
      context: context,
      initialDate: startLocal,
      // The picker itself stops at the 14-day rule, so the common case never
      // reaches a refusal at all; the validator still catches a stale sheet.
      firstDate: DateTime(nowLocal.year, nowLocal.month, nowLocal.day),
      lastDate: nowLocal.add(kHandoverMaxLeadTime),
      helpText: 'When should they be able to collect it?',
    );
    if (date == null || !context.mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(startLocal),
      helpText: 'From what time?',
    );
    if (time == null) return;
    onStartChanged(
      DateTime(date.year, date.month, date.day, time.hour, time.minute),
    );
  }

  @override
  Widget build(BuildContext context) {
    final invalid = problem != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionLabel('When they can collect it'),
        const SizedBox(height: DesignTokens.s8),
        const Text(
          'Outside this window the code does nothing. Between 15 minutes and '
          '72 hours long, starting within the next 14 days.',
          style: DesignTokens.smallDescription,
        ),
        const SizedBox(height: DesignTokens.s12),
        Semantics(
          button: true,
          label: 'Change the start time. Currently $_sentence',
          child: OutlinedButton.icon(
            key: const ValueKey('handover-pick-start-button'),
            onPressed: () => _pickStart(context),
            icon: const Icon(Icons.event_outlined, size: 18),
            label: const Text('Change start time'),
          ),
        ),
        const SizedBox(height: DesignTokens.s12),
        const Text(
          'How long should it last?',
          style: DesignTokens.mediumRegular,
        ),
        const SizedBox(height: DesignTokens.s8),
        Wrap(
          spacing: DesignTokens.s8,
          runSpacing: DesignTokens.s8,
          children: [
            for (final (label, value) in _presets)
              ChoiceChip(
                key: ValueKey('handover-length-$label'),
                label: Text(label),
                selected: length == value,
                onSelected: (_) => onLengthChanged(value),
              ),
          ],
        ),
        const SizedBox(height: DesignTokens.s8),
        Row(
          children: [
            Semantics(
              button: true,
              label: 'Shorten the window by fifteen minutes',
              child: IconButton(
                key: const ValueKey('handover-length-minus'),
                onPressed: () => onLengthChanged(length - _step),
                icon: const Icon(Icons.remove_circle_outline_rounded),
                tooltip: 'Shorter',
              ),
            ),
            Expanded(
              child: Text(
                HandoverCopy.durationWords(length),
                key: const ValueKey('handover-length-readout'),
                textAlign: TextAlign.center,
                style: DesignTokens.mediumRegular,
              ),
            ),
            Semantics(
              button: true,
              label: 'Lengthen the window by fifteen minutes',
              child: IconButton(
                key: const ValueKey('handover-length-plus'),
                onPressed: () => onLengthChanged(length + _step),
                icon: const Icon(Icons.add_circle_outline_rounded),
                tooltip: 'Longer',
              ),
            ),
          ],
        ),
        const SizedBox(height: DesignTokens.s8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(DesignTokens.s12),
          decoration: BoxDecoration(
            color: DesignTokens.bgAppBodyLight,
            borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
          ),
          child: Semantics(
            label: invalid
                ? 'This window is not allowed'
                : 'Window: $_sentence',
            excludeSemantics: true,
            child: Text(
              HandoverCopy.windowSentence(
                startLocal.toUtc(),
                _endLocal.toUtc(),
              ),
              key: const ValueKey('handover-window-sentence'),
              style: DesignTokens.mediumRegular.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        if (problem != null) ...[
          const SizedBox(height: DesignTokens.s8),
          _Problem(
            HandoverCopy.windowProblem(problem!),
            key: const ValueKey('handover-window-problem'),
          ),
        ],
      ],
    );
  }
}

/// The three `allowedExceptions`, as decisions with named consequences.
/// Nothing is pre-ticked: the safe answer is the default, and the customer
/// has to choose to widen it.
class _ExceptionPicker extends StatelessWidget {
  const _ExceptionPicker({
    required this.delegateName,
    required this.chosen,
    required this.onToggle,
  });

  final String delegateName;
  final Set<DelegatedException> chosen;

  /// Named, not positional: `onToggle(e, true)` at a call site would not
  /// say what the boolean means.
  final void Function(DelegatedException exception, {required bool allowed})
  onToggle;

  @override
  Widget build(BuildContext context) {
    final who = delegateName.isEmpty ? 'They' : delegateName;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionLabel('What may they accept for you?'),
        const SizedBox(height: DesignTokens.s8),
        const Text(
          HandoverCopy.noExceptionsExplainer,
          style: DesignTokens.smallDescription,
        ),
        const SizedBox(height: DesignTokens.s12),
        for (final e in DelegatedException.values) ...[
          Semantics(
            toggled: chosen.contains(e),
            label:
                '${HandoverCopy.exceptionTitle(e)}. '
                '${HandoverCopy.exceptionConsequence(e)}',
            child: CheckboxListTile(
              key: ValueKey('handover-exception-${e.name}'),
              value: chosen.contains(e),
              onChanged: (v) => onToggle(e, allowed: v ?? false),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
              dense: true,
              title: Text(
                HandoverCopy.exceptionTitle(e),
                style: DesignTokens.mediumRegular,
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  HandoverCopy.exceptionConsequence(e),
                  style: DesignTokens.smallDescription,
                ),
              ),
            ),
          ),
          const SizedBox(height: DesignTokens.s8),
        ],
        Text(
          chosen.isEmpty
              ? '$who can only take a complete, undamaged parcel.'
              : HandoverCopy.exceptionSummary(chosen),
          key: const ValueKey('handover-exception-summary'),
          style: DesignTokens.smallDescription,
        ),
      ],
    );
  }
}

/// A refusal from the backend, in words the customer can act on.
class HandoverRefusalNotice extends StatelessWidget {
  const HandoverRefusalNotice({
    required this.errorCode,
    this.onDismiss,
    super.key,
  });

  final String errorCode;
  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context) {
    final copy = HandoverCopy.refusal(errorCode);
    return Container(
      key: const ValueKey('handover-refusal-notice'),
      width: double.infinity,
      padding: const EdgeInsets.all(DesignTokens.s12),
      decoration: BoxDecoration(
        color: DesignTokens.colorError.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
      ),
      child: Semantics(
        liveRegion: true,
        label: '${copy.title}. ${copy.body}',
        excludeSemantics: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  size: 18,
                  color: DesignTokens.colorError,
                ),
                const SizedBox(width: DesignTokens.s8),
                Expanded(
                  child: Text(
                    copy.title,
                    style: DesignTokens.mediumRegular.copyWith(
                      fontWeight: FontWeight.w700,
                      color: DesignTokens.colorError,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(copy.body, style: DesignTokens.smallDescription),
            if (onDismiss != null)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: onDismiss,
                  child: const Text('Got it'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _KeyFact extends StatelessWidget {
  const _KeyFact({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Semantics(
    label: '$label: $value',
    excludeSemantics: true,
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: DesignTokens.textMuted),
        const SizedBox(width: DesignTokens.s8),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: DesignTokens.smallDescription,
              children: [
                TextSpan(
                  text: '$label  ',
                  style: DesignTokens.smallDescription.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                TextSpan(text: value),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Semantics(
    header: true,
    child: Text(
      text,
      style: DesignTokens.mediumRegular.copyWith(fontWeight: FontWeight.w700),
    ),
  );
}

class _Problem extends StatelessWidget {
  const _Problem(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Semantics(
    liveRegion: true,
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(
          Icons.warning_amber_rounded,
          size: 16,
          color: DesignTokens.colorError,
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: DesignTokens.smallDescription.copyWith(
              color: DesignTokens.colorError,
            ),
          ),
        ),
      ],
    ),
  );
}

class _Grabber extends StatelessWidget {
  const _Grabber();

  @override
  Widget build(BuildContext context) => Center(
    child: Container(
      width: 36,
      height: 4,
      decoration: BoxDecoration(
        color: DesignTokens.bgAppBodyLight,
        borderRadius: BorderRadius.circular(2),
      ),
    ),
  );
}
