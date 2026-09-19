import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:stylemint_mobile_frontend/features/customer/agent_commerce/domain/entities/agent_mandate.dart';
import 'package:stylemint_mobile_frontend/features/customer/agent_commerce/presentation/notifiers/agent_commerce_notifier.dart';
import 'package:stylemint_mobile_frontend/features/customer/agent_commerce/presentation/widgets/agent_commerce_copy.dart';
import 'package:stylemint_mobile_frontend/features/customer/agent_commerce/shared/providers.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/mall/mall_metrics.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';
import 'package:uuid/uuid.dart';

/// Opens the "connect an outside assistant" flow.
///
/// A **modal sheet, not a route** — the same security decision the delegated
/// parcel handover made, for the same reason: the issued mandate credential is
/// shown inside this sheet, and a route would mean a navigator entry, a
/// possible deep link and a path or query string that could carry it. The
/// sheet owns the credential in local `State` and it dies with the frame.
///
/// Resolves to `true` when a mandate was issued, so the caller can refresh.
Future<bool> showAgentMandateIssueSheet(
  BuildContext context, {
  DateTime Function()? clock,
}) async {
  final issued = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: DesignTokens.bgAppBody,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => AgentMandateIssueSheet(clock: clock),
  );
  return issued ?? false;
}

/// Two steps: set every limit, then read the credential once.
@visibleForTesting
class AgentMandateIssueSheet extends ConsumerStatefulWidget {
  const AgentMandateIssueSheet({super.key, this.clock});

  final DateTime Function()? clock;

  @override
  ConsumerState<AgentMandateIssueSheet> createState() =>
      _AgentMandateIssueSheetState();
}

class _AgentMandateIssueSheetState
    extends ConsumerState<AgentMandateIssueSheet> {
  static const List<String> _commonCurrencies = <String>[
    'NPR',
    'USD',
    'EUR',
    'INR',
    'GBP',
  ];
  static const List<int> _dayPresets = <int>[
    7,
    30,
    kAgentMandateMaxLifetimeDays,
  ];

  final _name = TextEditingController();
  final _cap = TextEditingController();
  final _days = TextEditingController();
  final _otherCurrency = TextEditingController();

  /// Nothing is pre-ticked. Every one of these widens what somebody else's
  /// software may do in this customer's name, so each is a decision they take
  /// rather than one they fail to undo.
  final Set<AgentMandateScope> _scopes = <AgentMandateScope>{};
  final Set<String> _allowedProductIds = <String>{};

  String? _currency;
  bool _otherCurrencyChosen = false;

  /// Null until the customer chooses. There is no "everything" default.
  bool? _limitToChosenProducts;

  bool _submitting = false;
  bool _showFieldErrors = false;
  String? _failureCode;

  /// The mandate credential, held **only here**.
  ///
  /// A field on a `State`, not a provider, not a repository, not a cache:
  /// when this sheet is popped the object is garbage and the credential is
  /// gone from the process. It is never written to `shared_preferences`,
  /// secure storage, the clipboard, a log line, a crash breadcrumb, an
  /// analytics event or a route argument — `agent_commerce_secrecy_test.dart`
  /// fails the build if that changes.
  String? _issuedCredential;
  AgentMandate? _issuedMandate;

  DateTime _now() => widget.clock?.call() ?? DateTime.now().toUtc();

  @override
  void dispose() {
    _name.dispose();
    _cap.dispose();
    _days.dispose();
    _otherCurrency.dispose();
    // Belt and braces: drop the reference before the frame is torn down.
    _issuedCredential = null;
    super.dispose();
  }

  // ── The limits, as the backend enforces them ─────────────────────────────

  int? get _dayCount => int.tryParse(_days.text.trim());

  DateTime? get _expiresUtc {
    final days = _dayCount;
    if (days == null) return null;
    return _now().add(Duration(days: days));
  }

  MandateExpiryProblem? get _expiryProblem {
    final expires = _expiresUtc;
    if (expires == null) return null;
    return validateMandateExpiry(expiresUtc: expires, nowUtc: _now());
  }

  MandateCapProblem? get _capProblem => validateMandateCap(_cap.text);

  String get _currencyText =>
      _otherCurrencyChosen ? _otherCurrency.text : (_currency ?? '');

  MandateCurrencyProblem? get _currencyProblem => _currencyText.trim().isEmpty
      ? null
      : validateMandateCurrency(_currencyText);

  bool get _nameOk =>
      _name.text.trim().isNotEmpty &&
      _name.text.trim().length <= kAgentMandateMaxNameLength;

  bool get _currencyOk =>
      _currencyText.trim().isNotEmpty &&
      validateMandateCurrency(_currencyText) == null;

  bool get _allowlistOk {
    if (_limitToChosenProducts == null) return false;
    if (!_limitToChosenProducts!) return true;
    return _allowedProductIds.isNotEmpty &&
        _allowedProductIds.length <= kAgentMandateMaxAllowedProducts;
  }

  bool get _canSubmit =>
      !_submitting &&
      _nameOk &&
      _scopes.isNotEmpty &&
      _capProblem == null &&
      _currencyOk &&
      _allowlistOk &&
      _dayCount != null &&
      _expiryProblem == null;

  @override
  Widget build(BuildContext context) {
    final credential = _issuedCredential;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
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
            child: credential == null
                ? _form(context)
                : _issued(context, credential),
          ),
        ),
      ),
    );
  }

  // ── Step 1: every limit, visible and settable ────────────────────────────

  Widget _form(BuildContext context) {
    final candidates = ref.watch(agentAllowlistCandidatesProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _Grabber(),
        const SizedBox(height: DesignTokens.s16),
        Semantics(
          header: true,
          child: const Text(
            'Connect an outside assistant',
            style: DesignTokens.h3,
          ),
        ),
        const SizedBox(height: DesignTokens.s8),
        const Text(
          'You are giving somebody else’s software permission to act for '
          'you on StyleMint, inside limits you set here. You can withdraw it '
          'in one step, at any time.',
          style: DesignTokens.mediumRegular,
        ),
        const SizedBox(height: DesignTokens.s24),

        const _NeverCanPanel(),
        const SizedBox(height: DesignTokens.s24),

        const _SectionLabel('Which assistant'),
        const SizedBox(height: DesignTokens.s8),
        TextField(
          key: const ValueKey('agent-mandate-name-field'),
          controller: _name,
          maxLength: kAgentMandateMaxNameLength,
          textCapitalization: TextCapitalization.words,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            labelText: 'Name of the assistant',
            helperText:
                'Shown on every line of its activity, so you can tell '
                'two assistants apart.',
            helperMaxLines: 3,
            counterText: '',
            errorText: _showFieldErrors && !_nameOk
                ? 'Give this assistant a name.'
                : null,
          ),
        ),
        const SizedBox(height: DesignTokens.s24),

        // ── Scopes ──
        const _SectionLabel('What may it do?'),
        const SizedBox(height: DesignTokens.s8),
        const Text(
          'Nothing is ticked to begin with. Each one is a separate permission, '
          'and you can grant as few as one.',
          style: DesignTokens.smallDescription,
        ),
        const SizedBox(height: DesignTokens.s12),
        for (final scope in AgentMandateScope.values) ...[
          Semantics(
            toggled: _scopes.contains(scope),
            label:
                '${AgentCommerceCopy.scopeTitle(scope)}. '
                '${AgentCommerceCopy.scopeConsequence(scope)}',
            child: CheckboxListTile(
              key: ValueKey('agent-scope-${scope.name}'),
              value: _scopes.contains(scope),
              onChanged: (v) => setState(() {
                if (v ?? false) {
                  _scopes.add(scope);
                } else {
                  _scopes.remove(scope);
                }
              }),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
              dense: true,
              title: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(
                      top: 2,
                      right: DesignTokens.s8,
                    ),
                    child: Icon(
                      AgentCommerceCopy.scopeIcon(scope),
                      size: 16,
                      color: DesignTokens.textMuted,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      AgentCommerceCopy.scopeTitle(scope),
                      style: DesignTokens.mediumRegular,
                    ),
                  ),
                ],
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  AgentCommerceCopy.scopeConsequence(scope),
                  style: DesignTokens.smallDescription,
                ),
              ),
            ),
          ),
          const SizedBox(height: DesignTokens.s8),
        ],
        if (_showFieldErrors && _scopes.isEmpty)
          const _Problem(
            'Tick at least one permission, or this mandate grants nothing.',
          ),
        const SizedBox(height: DesignTokens.s16),

        // ── Spend cap + currency ──
        const _SectionLabel('How much may one order be?'),
        const SizedBox(height: DesignTokens.s8),
        const Text(
          'A hard ceiling on any single order it prepares. An order above it '
          'is refused outright, and the refusal appears in your activity.',
          style: DesignTokens.smallDescription,
        ),
        const SizedBox(height: DesignTokens.s12),
        TextField(
          key: const ValueKey('agent-mandate-cap-field'),
          controller: _cap,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp('[0-9.,]')),
          ],
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            labelText: 'Spending limit per order',
            counterText: '',
            errorText: _showFieldErrors && _capProblem != null
                ? AgentCommerceCopy.capProblem(_capProblem!)
                : null,
            errorMaxLines: 3,
          ),
        ),
        const SizedBox(height: DesignTokens.s12),
        const Text('In which currency?', style: DesignTokens.mediumRegular),
        const SizedBox(height: DesignTokens.s4),
        const Text(
          'The mandate is pinned to one currency. A basket quoted in any other '
          'is refused.',
          style: DesignTokens.smallDescription,
        ),
        const SizedBox(height: DesignTokens.s8),
        Wrap(
          spacing: DesignTokens.s8,
          runSpacing: DesignTokens.s8,
          children: [
            for (final code in _commonCurrencies)
              ChoiceChip(
                key: ValueKey('agent-currency-$code'),
                label: Text(code),
                selected: !_otherCurrencyChosen && _currency == code,
                onSelected: (_) => setState(() {
                  _currency = code;
                  _otherCurrencyChosen = false;
                }),
                tooltip: 'Cap this mandate in $code',
              ),
            ChoiceChip(
              key: const ValueKey('agent-currency-other'),
              label: const Text('Another code'),
              selected: _otherCurrencyChosen,
              onSelected: (_) => setState(() {
                _otherCurrencyChosen = true;
                _currency = null;
              }),
              tooltip: 'Type a three-letter currency code',
            ),
          ],
        ),
        if (_otherCurrencyChosen) ...[
          const SizedBox(height: DesignTokens.s12),
          TextField(
            key: const ValueKey('agent-currency-other-field'),
            controller: _otherCurrency,
            maxLength: 3,
            textCapitalization: TextCapitalization.characters,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              labelText: 'Three-letter currency code',
              counterText: '',
              errorText: _currencyProblem == null
                  ? null
                  : AgentCommerceCopy.currencyProblem(_currencyProblem!),
              errorMaxLines: 2,
            ),
          ),
        ],
        if (_showFieldErrors && !_currencyOk) ...[
          const SizedBox(height: DesignTokens.s8),
          const _Problem('Pick the currency this limit is in.'),
        ],
        const SizedBox(height: DesignTokens.s24),

        // ── Allowlist ──
        _AllowlistPicker(
          candidates: candidates,
          limitToChosen: _limitToChosenProducts,
          chosen: _allowedProductIds,
          showErrors: _showFieldErrors,
          onModeChanged: (limit) => setState(() {
            _limitToChosenProducts = limit;
            if (!limit) _allowedProductIds.clear();
          }),
          onToggle: (id, {required allowed}) => setState(() {
            if (allowed) {
              _allowedProductIds.add(id);
            } else {
              _allowedProductIds.remove(id);
            }
          }),
        ),
        const SizedBox(height: DesignTokens.s24),

        // ── Expiry ──
        _ExpiryPicker(
          controller: _days,
          dayCount: _dayCount,
          expiresUtc: _expiresUtc,
          problem: _expiryProblem,
          nowUtc: _now(),
          presets: _dayPresets,
          showErrors: _showFieldErrors,
          onChanged: () => setState(() {}),
          onPreset: (days) => setState(() {
            _days.text = '$days';
          }),
        ),
        const SizedBox(height: DesignTokens.s24),

        if (_failureCode != null) ...[
          AgentActionFailureNotice(
            errorCode: _failureCode!,
            onDismiss: () => setState(() => _failureCode = null),
          ),
          const SizedBox(height: DesignTokens.s16),
        ],

        Semantics(
          container: true,
          button: true,
          enabled: _canSubmit,
          label: 'Issue this mandate and show its credential once',
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              key: const ValueKey('agent-mandate-issue-button'),
              onPressed: _submitting
                  ? null
                  : (_canSubmit ? _submit : _revealFieldErrors),
              child: _submitting
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Issue the mandate'),
            ),
          ),
        ),
        const SizedBox(height: DesignTokens.s8),
        Semantics(
          container: true,
          button: true,
          label: 'Cancel without connecting anything',
          child: SizedBox(
            width: double.infinity,
            child: TextButton(
              key: const ValueKey('agent-mandate-cancel-button'),
              onPressed: _submitting
                  ? null
                  : () => Navigator.of(context).pop(false),
              child: const Text('Not now'),
            ),
          ),
        ),
      ],
    );
  }

  void _revealFieldErrors() => setState(() => _showFieldErrors = true);

  Future<void> _submit() async {
    final expires = _expiresUtc;
    if (expires == null) return;
    setState(() {
      _submitting = true;
      _failureCode = null;
    });
    try {
      // Called straight from this State — the issued object, and therefore the
      // credential, never passes through a provider, a repository cache or a
      // notifier. It lives in `_issuedCredential` and dies with this sheet.
      final issued = await ref
          .read(agentCommerceDataSourceProvider)
          .issueMandate(
            agentName: _name.text,
            scopes: AgentScopeSet(_scopes),
            maxOrderAmount: double.parse(_cap.text.trim().replaceAll(',', '')),
            currency: _currencyText,
            allowedProductIds: _allowedProductIds.toList(growable: false),
            expiresUtc: expires,
            idempotencyKey: const Uuid().v4(),
          );
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _issuedCredential = issued.credential;
        _issuedMandate = issued.mandate;
      });
      // The list behind the sheet is now stale. Ask it to re-read — note it is
      // told nothing but "go and look", never handed `issued`.
      unawaited(ref.read(agentCommerceNotifierProvider.notifier).refresh());
    } on Object catch (error) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _failureCode = agentErrorCodeOf(error);
      });
    }
  }

  // ── Step 2: the credential, once ─────────────────────────────────────────

  Widget _issued(BuildContext context, String credential) {
    final mandate = _issuedMandate;
    final cap = mandate == null
        ? ''
        : AgentCommerceCopy.money(mandate.maxOrderAmount, mandate.currency);
    final expiry = mandate == null
        ? ''
        : '${AgentCommerceCopy.date(mandate.expiresUtc)} '
              '(${AgentCommerceCopy.daysFromNow(mandate.expiresUtc, _now())})';
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
                  '${_name.text.trim()} is connected',
                  style: DesignTokens.h3,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: DesignTokens.s16),

        _OneTimeCredentialPanel(
          credential: credential,
          assistantName: _name.text.trim(),
        ),

        const SizedBox(height: DesignTokens.s16),
        if (mandate != null) ...[
          _KeyFact(
            icon: Icons.payments_outlined,
            label: 'Spending limit',
            value: '$cap per order',
          ),
          const SizedBox(height: DesignTokens.s8),
          _KeyFact(
            icon: Icons.inventory_2_outlined,
            label: 'May buy',
            value: AgentCommerceCopy.allowlistSummary(
              mandate.allowedProductIds.length,
            ),
          ),
          const SizedBox(height: DesignTokens.s8),
          _KeyFact(
            icon: Icons.event_busy_outlined,
            label: 'Expires',
            value: expiry,
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
            'Changed your mind? Revoke this mandate from the assistant’s '
            'card at any time. ${AgentCommerceCopy.revocationPromise} If the '
            'credential goes astray, revoke it and connect the assistant '
            'again; a new credential is issued each time.',
            style: DesignTokens.mediumRegular,
          ),
        ),
        const SizedBox(height: DesignTokens.s24),
        Semantics(
          container: true,
          button: true,
          label:
              'I have given the credential to the assistant. Close and hide '
              'it for good.',
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              key: const ValueKey('agent-credential-done-button'),
              onPressed: () {
                // Clear before popping, so not even the closing animation
                // frame still holds it.
                setState(() => _issuedCredential = null);
                Navigator.of(context).pop(true);
              },
              child: const Text('I’ve handed it over — hide it'),
            ),
          ),
        ),
      ],
    );
  }
}

/// The mandate credential, drawn once.
///
/// Notes on what this widget deliberately does **not** offer, carried over
/// from the delegated-handover code panel that solved this first:
/// * **No copy button and no `SelectableText`.** The system clipboard is
///   readable by this app (`Clipboard.getData`) and by every other app on the
///   device, and it survives long after the sheet closes. A credential that
///   lets someone else's software act as this customer does not belong there.
/// * **No QR, no link, no deep link.** It never becomes a URL.
/// * **No screenshot prompt, no "save to notes".**
///
/// What it does offer is the system share sheet — the customer's own channel,
/// handed straight to the OS. Nothing written by that path is readable back by
/// this app.
class _OneTimeCredentialPanel extends StatelessWidget {
  const _OneTimeCredentialPanel({
    required this.credential,
    required this.assistantName,
  });

  final String credential;
  final String assistantName;

  /// Grouped in fours so it can be read aloud or checked character by
  /// character without losing your place.
  String get _grouped {
    final buffer = StringBuffer();
    for (var i = 0; i < credential.length; i++) {
      if (i > 0 && i % 4 == 0) buffer.write(' ');
      buffer.write(credential[i]);
    }
    return buffer.toString();
  }

  Future<void> _share() => SharePlus.instance.share(
    ShareParams(
      // Plain text only. No URL, nothing that could become a clickable route.
      text:
          'StyleMint mandate credential for $assistantName: $credential\n'
          'It works only within the limits I set, and I can withdraw it at '
          'any time.',
      subject: 'StyleMint mandate credential',
    ),
  );

  @override
  Widget build(BuildContext context) {
    final scaler = MallMetrics.scalerOf(context);
    return Container(
      key: const ValueKey('agent-one-time-credential'),
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 2),
                child: Icon(
                  Icons.visibility_off_outlined,
                  size: 18,
                  color: DesignTokens.warning300,
                ),
              ),
              const SizedBox(width: DesignTokens.s8),
              Expanded(
                child: Text(
                  AgentCommerceCopy.credentialWarning,
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
            label: 'Mandate credential: ${credential.split('').join(' ')}',
            excludeSemantics: true,
            child: Text(
              _grouped,
              key: const ValueKey('agent-credential-text'),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: scaler.scale(18),
                height: 1.35,
                letterSpacing: 1,
                fontWeight: FontWeight.w700,
                fontFamily: 'monospace',
                color: DesignTokens.textLight,
              ),
            ),
          ),
          const SizedBox(height: DesignTokens.s16),
          Text(
            'Paste this into $assistantName yourself. StyleMint keeps only a '
            'scrambled version, so we cannot show it or resend it — and '
            'neither can anyone who takes this phone.',
            style: DesignTokens.smallDescription,
          ),
          const SizedBox(height: DesignTokens.s12),
          Semantics(
            container: true,
            button: true,
            label: 'Send the credential using another app',
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                key: const ValueKey('agent-credential-share-button'),
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

/// What an external agent can never do, stated where authority is granted.
class _NeverCanPanel extends StatelessWidget {
  const _NeverCanPanel();

  @override
  Widget build(BuildContext context) => Container(
    key: const ValueKey('agent-never-can-panel'),
    width: double.infinity,
    padding: const EdgeInsets.all(DesignTokens.s12),
    decoration: BoxDecoration(
      color: DesignTokens.bgAppBodyLight,
      borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 2),
              child: Icon(
                Icons.shield_outlined,
                size: 18,
                color: DesignTokens.primaryGreen,
              ),
            ),
            const SizedBox(width: DesignTokens.s8),
            Expanded(
              child: Semantics(
                header: true,
                child: Text(
                  'Whatever you tick, it can never:',
                  style: DesignTokens.mediumRegular.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: DesignTokens.s8),
        for (final line in AgentCommerceCopy.neverCan)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 3, right: 6),
                  child: Icon(
                    Icons.block_rounded,
                    size: 13,
                    color: DesignTokens.textMuted,
                  ),
                ),
                Expanded(
                  child: Text(line, style: DesignTokens.smallDescription),
                ),
              ],
            ),
          ),
      ],
    ),
  );
}

/// "Anything in the catalogue" or "only these products", plus the list.
class _AllowlistPicker extends StatelessWidget {
  const _AllowlistPicker({
    required this.candidates,
    required this.limitToChosen,
    required this.chosen,
    required this.showErrors,
    required this.onModeChanged,
    required this.onToggle,
  });

  final List<AgentAllowlistCandidate> candidates;
  final bool? limitToChosen;
  final Set<String> chosen;
  final bool showErrors;
  final ValueChanged<bool> onModeChanged;
  final void Function(String productId, {required bool allowed}) onToggle;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const _SectionLabel('What may it buy?'),
      const SizedBox(height: DesignTokens.s8),
      const Text(
        'A product outside the list is refused, and the refusal shows up in '
        'your activity.',
        style: DesignTokens.smallDescription,
      ),
      const SizedBox(height: DesignTokens.s12),
      Wrap(
        spacing: DesignTokens.s8,
        runSpacing: DesignTokens.s8,
        children: [
          ChoiceChip(
            key: const ValueKey('agent-allowlist-any'),
            label: const Text('Anything in the catalogue'),
            selected: limitToChosen == false,
            onSelected: (_) => onModeChanged(false),
            tooltip: 'Any published product, still inside the spending limit',
          ),
          ChoiceChip(
            key: const ValueKey('agent-allowlist-chosen'),
            label: const Text('Only products I choose'),
            selected: limitToChosen == true,
            onSelected: (_) => onModeChanged(true),
            tooltip: 'Pick the products from the ones you have saved',
          ),
        ],
      ),
      if (showErrors && limitToChosen == null) ...[
        const SizedBox(height: DesignTokens.s8),
        const _Problem('Choose what this assistant may buy.'),
      ],
      if (limitToChosen ?? false) ...[
        const SizedBox(height: DesignTokens.s12),
        if (candidates.isEmpty)
          const Text(
            'You have no saved products to choose from yet. Save something '
            'first, or allow the whole catalogue and keep the spending limit '
            'tight.',
            key: ValueKey('agent-allowlist-empty'),
            style: DesignTokens.smallDescription,
          )
        else ...[
          Text(
            'At most $kAgentMandateMaxAllowedProducts products. '
            '${AgentCommerceCopy.allowlistSummary(chosen.length)} chosen.',
            key: const ValueKey('agent-allowlist-count'),
            style: DesignTokens.smallDescription,
          ),
          const SizedBox(height: DesignTokens.s8),
          for (final candidate in candidates)
            Semantics(
              toggled: chosen.contains(candidate.productId),
              label: candidate.subtitle == null
                  ? candidate.title
                  : '${candidate.title}. ${candidate.subtitle}',
              child: CheckboxListTile(
                key: ValueKey('agent-allowlist-${candidate.productId}'),
                value: chosen.contains(candidate.productId),
                onChanged: (v) =>
                    onToggle(candidate.productId, allowed: v ?? false),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
                dense: true,
                // Title and variant only. A product photograph belongs on
                // product detail, and this is a consent list.
                title: Text(candidate.title, style: DesignTokens.mediumRegular),
                subtitle: candidate.subtitle == null
                    ? null
                    : Text(
                        candidate.subtitle!,
                        style: DesignTokens.smallDescription,
                      ),
              ),
            ),
        ],
        if (showErrors && (limitToChosen ?? false) && chosen.isEmpty) ...[
          const SizedBox(height: DesignTokens.s8),
          const _Problem(
            'Tick at least one product, or allow the whole catalogue.',
          ),
        ],
      ],
    ],
  );
}

/// How long the mandate lasts, in days, with the resulting date written out.
///
/// A day count rather than a date picker: the limit the backend enforces is a
/// *length* (at most [kAgentMandateMaxLifetimeDays] days), so the control the
/// customer touches is the same quantity the rule is about. Typing a longer
/// one is possible, and refused here with the reason, rather than travelling
/// to the server to come back as a rejected request.
class _ExpiryPicker extends StatelessWidget {
  const _ExpiryPicker({
    required this.controller,
    required this.dayCount,
    required this.expiresUtc,
    required this.problem,
    required this.nowUtc,
    required this.presets,
    required this.showErrors,
    required this.onChanged,
    required this.onPreset,
  });

  final TextEditingController controller;
  final int? dayCount;
  final DateTime? expiresUtc;
  final MandateExpiryProblem? problem;
  final DateTime nowUtc;
  final List<int> presets;
  final bool showErrors;
  final VoidCallback onChanged;
  final ValueChanged<int> onPreset;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const _SectionLabel('How long should it last?'),
      const SizedBox(height: DesignTokens.s8),
      const Text(
        'A mandate expires by itself. StyleMint will not issue one longer than '
        '$kAgentMandateMaxLifetimeDays days.',
        style: DesignTokens.smallDescription,
      ),
      const SizedBox(height: DesignTokens.s12),
      Wrap(
        spacing: DesignTokens.s8,
        runSpacing: DesignTokens.s8,
        children: [
          for (final days in presets)
            ChoiceChip(
              key: ValueKey('agent-expiry-preset-$days'),
              label: Text(
                days == kAgentMandateMaxLifetimeDays
                    ? '$days days (the most)'
                    : '$days days',
              ),
              selected: dayCount == days,
              onSelected: (_) => onPreset(days),
              tooltip: 'Expire after $days days',
            ),
        ],
      ),
      const SizedBox(height: DesignTokens.s12),
      TextField(
        key: const ValueKey('agent-expiry-days-field'),
        controller: controller,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        maxLength: 4,
        onChanged: (_) => onChanged(),
        decoration: const InputDecoration(
          labelText: 'Days until it expires',
          counterText: '',
        ),
      ),
      if (expiresUtc != null && problem == null) ...[
        const SizedBox(height: DesignTokens.s8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(DesignTokens.s12),
          decoration: BoxDecoration(
            color: DesignTokens.bgAppBodyLight,
            borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
          ),
          child: Semantics(
            label:
                'Expires ${AgentCommerceCopy.date(expiresUtc!)}, '
                '${AgentCommerceCopy.daysFromNow(expiresUtc!, nowUtc)}',
            excludeSemantics: true,
            child: Text(
              'Expires ${AgentCommerceCopy.date(expiresUtc!)} '
              '(${AgentCommerceCopy.daysFromNow(expiresUtc!, nowUtc)})',
              key: const ValueKey('agent-expiry-readout'),
              style: DesignTokens.mediumRegular.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
      if (problem != null) ...[
        const SizedBox(height: DesignTokens.s8),
        _Problem(
          AgentCommerceCopy.expiryProblem(problem!, nowUtc),
          key: const ValueKey('agent-expiry-problem'),
        ),
      ],
      if (showErrors && dayCount == null && problem == null) ...[
        const SizedBox(height: DesignTokens.s8),
        const _Problem('Say how many days this mandate should last.'),
      ],
    ],
  );
}

/// A refused action of the customer's own, in words they can act on.
class AgentActionFailureNotice extends StatelessWidget {
  const AgentActionFailureNotice({
    required this.errorCode,
    this.onDismiss,
    super.key,
  });

  final String errorCode;
  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context) {
    final copy = AgentCommerceCopy.actionFailure(errorCode);
    return Container(
      key: const ValueKey('agent-action-failure-notice'),
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
