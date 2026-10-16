import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:stylemint_mobile_frontend/features/customer/checkout/presentation/widgets/checkout_emi_option.dart';
import 'package:stylemint_mobile_frontend/features/customer/emi/data/saved_credit_documents.dart';
import 'package:stylemint_mobile_frontend/features/customer/emi/domain/entities/credit.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// Why a picked file cannot be sent with an EMI application, or null when it
/// can: PDF or photo (JPEG, PNG, HEIC), at most 10 MB.
String? creditDocumentProblem(PickedCreditDocument doc) {
  final extension = doc.name.split('.').last.toLowerCase();
  if (doc.name.contains('.') && !creditDocumentExtensions.contains(extension)) {
    return 'Choose a PDF or a photo (JPEG, PNG or HEIC).';
  }
  if (doc.sizeBytes <= 0 || doc.sizeBytes > creditDocumentMaxBytes) {
    return 'That file is larger than 10 MB. Choose a smaller one.';
  }
  return null;
}

/// The EMI documents step on its own page: identity and financial proofs,
/// added and removed here, then "Send EMI request to the seller".
///
/// The page edits the plan card's own [identity] and [financial] lists, so
/// going back keeps the picks; Send pops `true` and the card sends them.
///
/// With the buyer's explicit consent (off by default) the picked files are
/// also kept in app-private storage, and offered next time as "Use saved
/// documents" — still uploaded fresh to the new application. Turning consent
/// off deletes everything saved.
class CreditDocumentsScreen extends ConsumerStatefulWidget {
  const CreditDocumentsScreen({
    required this.identity,
    required this.financial,
    required this.uploaded,
    this.productName,
    super.key,
  });

  final List<PickedCreditDocument> identity;
  final List<PickedCreditDocument> financial;

  /// Paths already uploaded to this application: they cannot be removed.
  final Set<String> uploaded;
  final String? productName;

  static const Key consentKey = Key('credit-docs-consent');
  static const Key savedKey = Key('credit-docs-saved');
  static const Key deleteAllKey = Key('credit-docs-delete-all');
  static const Key errorKey = Key('credit-docs-error');

  static const consentText =
      'Save these documents on this phone so you can reuse them for future '
      'EMI requests. They stay only on this device; you can delete them any '
      'time.';

  @override
  ConsumerState<CreditDocumentsScreen> createState() =>
      _CreditDocumentsScreenState();
}

class _CreditDocumentsScreenState extends ConsumerState<CreditDocumentsScreen> {
  bool _consent = false;
  List<SavedCreditDocument> _saved = const [];
  String? _error;
  bool _busy = false;

  /// Paths that came from the saved documents (already kept; not saved again).
  final Set<String> _fromSaved = {};

  SavedCreditDocumentStore get _store =>
      ref.read(savedCreditDocumentStoreProvider);

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    try {
      final consent = await _store.hasConsent();
      final saved = consent ? await _store.list() : <SavedCreditDocument>[];
      if (!mounted) return;
      setState(() {
        _consent = consent;
        _saved = saved;
        _fromSaved.addAll(saved.map((s) => s.path));
      });
    } catch (_) {
      // Saved documents are a convenience; the page works without them.
    }
  }

  List<PickedCreditDocument> _listFor(CreditDocumentKind kind) =>
      kind == CreditDocumentKind.identity ? widget.identity : widget.financial;

  int _maxFor(CreditDocumentKind kind) => kind == CreditDocumentKind.identity
      ? maxIdentityDocuments
      : maxFinancialDocuments;

  Future<void> _pick(CreditDocumentKind kind) async {
    final picked = await ref.read(creditDocumentPickerProvider)(context);
    if (picked == null || !mounted) return;
    setState(() {
      _error = creditDocumentProblem(picked);
      if (_error == null) _listFor(kind).add(picked);
    });
  }

  void _use(SavedCreditDocument saved) {
    final list = _listFor(saved.kind);
    if (list.any((d) => d.path == saved.path) ||
        list.length >= _maxFor(saved.kind)) {
      return;
    }
    final doc = PickedCreditDocument(
      path: saved.path,
      name: saved.name,
      sizeBytes: saved.sizeBytes,
    );
    setState(() {
      _error = creditDocumentProblem(doc);
      if (_error == null) list.add(doc);
    });
  }

  void _dropFromLists(String path) {
    if (widget.uploaded.contains(path)) return;
    widget.identity.removeWhere((d) => d.path == path);
    widget.financial.removeWhere((d) => d.path == path);
  }

  Future<void> _delete(SavedCreditDocument saved) async {
    await _store.delete(saved.id);
    if (!mounted) return;
    setState(() {
      _dropFromLists(saved.path);
      _saved = _saved.where((s) => s.id != saved.id).toList();
    });
  }

  Future<void> _deleteAll() async {
    await _store.deleteAll();
    if (!mounted) return;
    setState(() {
      for (final s in _saved) {
        _dropFromLists(s.path);
      }
      _saved = const [];
      _consent = false;
    });
  }

  Future<void> _setConsent(bool consent) async {
    if (!consent) {
      // No consent, nothing kept: what was saved is deleted.
      await _deleteAll();
      return;
    }
    await _store.setConsent(true);
    if (mounted) setState(() => _consent = true);
  }

  Future<void> _send() async {
    setState(() => _busy = true);
    if (_consent) {
      for (final (kind, docs) in [
        (CreditDocumentKind.identity, widget.identity),
        (CreditDocumentKind.financial, widget.financial),
      ]) {
        for (final d in docs) {
          if (_fromSaved.contains(d.path)) continue;
          try {
            final saved = await _store.save(
              kind: kind,
              path: d.path,
              name: d.name,
              sizeBytes: d.sizeBytes,
            );
            if (saved != null) _fromSaved.add(d.path);
          } catch (_) {
            // Keeping a copy is a convenience; never block the request.
          }
        }
      }
    }
    if (mounted) Navigator.of(context).pop(true);
  }

  static const _muted = TextStyle(
    fontFamily: DesignTokens.fontFamily,
    fontSize: 12,
    color: DesignTokens.textMuted,
  );

  Widget _section(CreditDocumentKind kind, String label, String hint) {
    final docs = _listFor(kind);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: DesignTokens.fontFamily,
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: DesignTokens.textWhite,
          ),
        ),
        Text(hint, style: _muted),
        for (final d in docs)
          Row(
            children: [
              const Icon(
                Icons.description_outlined,
                size: 16,
                color: DesignTokens.textMuted,
              ),
              const SizedBox(width: DesignTokens.s6),
              Expanded(
                child: Text(
                  d.name,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: DesignTokens.fontFamily,
                    fontSize: 13,
                    color: DesignTokens.textWhite,
                  ),
                ),
              ),
              if (!widget.uploaded.contains(d.path) && !_busy)
                IconButton(
                  tooltip: 'Remove',
                  color: DesignTokens.textMuted,
                  icon: const Icon(Icons.close, size: 16),
                  onPressed: () => setState(() => docs.remove(d)),
                ),
            ],
          ),
        if (docs.length < _maxFor(kind))
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              key: Key('checkout-emi-add-${kind.name}'),
              onPressed: _busy ? null : () => _pick(kind),
              icon: const Icon(Icons.upload_file),
              label: Text(docs.isEmpty ? 'Add file' : 'Add another'),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final ready = widget.identity.isNotEmpty && widget.financial.isNotEmpty;
    final date = DateFormat('MMM d, yyyy');
    return Scaffold(
      backgroundColor: DesignTokens.bgAppBody,
      appBar: AppBar(
        title: Text(
          widget.productName == null
              ? 'EMI documents'
              : 'EMI documents · ${widget.productName}',
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(DesignTokens.s16),
          children: [
            const Text(
              'The seller decides from these documents. Add your identity '
              'and 1–3 proofs of income, then send the request.',
              style: _muted,
            ),
            const SizedBox(height: DesignTokens.s16),
            if (_saved.isNotEmpty) ...[
              Container(
                key: CreditDocumentsScreen.savedKey,
                padding: const EdgeInsets.all(DesignTokens.s12),
                decoration: BoxDecoration(
                  color: DesignTokens.primaryGreenDark,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Use saved documents',
                      style: TextStyle(
                        fontFamily: DesignTokens.fontFamily,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: DesignTokens.textWhite,
                      ),
                    ),
                    for (final s in _saved)
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  s.name,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontFamily: DesignTokens.fontFamily,
                                    fontSize: 13,
                                    color: DesignTokens.textWhite,
                                  ),
                                ),
                                Text(
                                  '${s.kind.wire} · saved '
                                  '${date.format(s.savedAt)}',
                                  style: _muted,
                                ),
                              ],
                            ),
                          ),
                          TextButton(
                            key: Key('credit-docs-use-${s.id}'),
                            onPressed:
                                _busy ||
                                    _listFor(
                                      s.kind,
                                    ).any((d) => d.path == s.path)
                                ? null
                                : () => _use(s),
                            child: const Text('Use'),
                          ),
                          IconButton(
                            key: Key('credit-docs-delete-${s.id}'),
                            tooltip: 'Delete saved document',
                            color: DesignTokens.textMuted,
                            icon: const Icon(Icons.delete_outline, size: 18),
                            onPressed: _busy ? null : () => _delete(s),
                          ),
                        ],
                      ),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton(
                        key: CreditDocumentsScreen.deleteAllKey,
                        onPressed: _busy ? null : _deleteAll,
                        child: const Text('Delete all saved documents'),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: DesignTokens.s16),
            ],
            _section(
              CreditDocumentKind.identity,
              'Identity document',
              'Citizenship, national ID or passport (both sides if needed).',
            ),
            const SizedBox(height: DesignTokens.s16),
            _section(
              CreditDocumentKind.financial,
              'Financial proof (1–3 files)',
              'Salary slip, bank statement or income proof. PDF or photo, up '
                  'to 10 MB.',
            ),
            const SizedBox(height: DesignTokens.s16),
            SwitchListTile(
              key: CreditDocumentsScreen.consentKey,
              contentPadding: EdgeInsets.zero,
              value: _consent,
              onChanged: _busy ? null : (v) => unawaited(_setConsent(v)),
              title: const Text(
                CreditDocumentsScreen.consentText,
                style: TextStyle(
                  fontFamily: DesignTokens.fontFamily,
                  fontSize: 13,
                  color: DesignTokens.textWhite,
                ),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: DesignTokens.s8),
              Text(
                _error!,
                key: CreditDocumentsScreen.errorKey,
                style: const TextStyle(
                  fontFamily: DesignTokens.fontFamily,
                  fontSize: 12,
                  color: DesignTokens.colorError,
                ),
              ),
            ],
            const SizedBox(height: DesignTokens.s16),
            SizedBox(
              key: CheckoutEmiOption.sendKey,
              width: double.infinity,
              height: DesignTokens.buttonHeight,
              child: FilledButton(
                onPressed: ready && !_busy ? _send : null,
                child: const Text('Send EMI request to the seller'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
