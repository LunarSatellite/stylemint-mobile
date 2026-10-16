import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:stylemint_mobile_frontend/core/auth_gate/auth_gate.dart';
import 'package:stylemint_mobile_frontend/core/utils/format_money.dart';
import 'package:stylemint_mobile_frontend/features/customer/cart/domain/entities/cart.dart';
import 'package:stylemint_mobile_frontend/features/customer/checkout/presentation/widgets/credit_documents_screen.dart';
import 'package:stylemint_mobile_frontend/features/customer/emi/domain/credit_messages.dart';
import 'package:stylemint_mobile_frontend/features/customer/emi/domain/entities/credit.dart';
import 'package:stylemint_mobile_frontend/features/customer/emi/domain/entities/emi_eligibility.dart';
import 'package:stylemint_mobile_frontend/features/customer/emi/domain/entities/emi_failure.dart';
import 'package:stylemint_mobile_frontend/features/customer/emi/domain/entities/emi_plan.dart';
import 'package:stylemint_mobile_frontend/features/customer/emi/domain/entities/emi_quote.dart';
import 'package:stylemint_mobile_frontend/features/customer/emi/presentation/screens/plan_review_screen.dart';
import 'package:stylemint_mobile_frontend/features/customer/emi/shared/providers.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';
import 'package:uuid/uuid.dart';

/// A file the buyer picked to send with an EMI application.
class PickedCreditDocument {
  const PickedCreditDocument({
    required this.path,
    required this.name,
    required this.sizeBytes,
  });

  final String path;
  final String name;
  final int sizeBytes;
}

/// Picks one document: camera, photo library, or a file (PDF).
typedef CreditDocumentPicker =
    Future<PickedCreditDocument?> Function(BuildContext context);

/// Documents sent with an EMI application: PDF or image, at most 10 MB each.
const creditDocumentMaxBytes = 10 * 1024 * 1024;
const creditDocumentExtensions = ['pdf', 'jpg', 'jpeg', 'png', 'heic'];
const maxIdentityDocuments = 2;
const maxFinancialDocuments = 3;

enum _DocumentSource { camera, photos, file }

/// As the KYC screens do: a photo from the camera or the library, re-encoded
/// to JPEG and resized (`imageQuality`/`maxWidth`) so a phone photo is well
/// under 10 MB; or a file — a PDF statement, say.
Future<PickedCreditDocument?> _chooseDocument(BuildContext context) async {
  final source = await showModalBottomSheet<_DocumentSource>(
    context: context,
    builder: (sheet) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            key: const Key('credit-doc-camera'),
            leading: const Icon(Icons.photo_camera_outlined),
            title: const Text('Take a photo'),
            onTap: () => Navigator.of(sheet).pop(_DocumentSource.camera),
          ),
          ListTile(
            key: const Key('credit-doc-photos'),
            leading: const Icon(Icons.photo_library_outlined),
            title: const Text('Choose from photos'),
            onTap: () => Navigator.of(sheet).pop(_DocumentSource.photos),
          ),
          ListTile(
            key: const Key('credit-doc-file'),
            leading: const Icon(Icons.picture_as_pdf_outlined),
            title: const Text('Choose a file (PDF)'),
            onTap: () => Navigator.of(sheet).pop(_DocumentSource.file),
          ),
        ],
      ),
    ),
  );
  switch (source) {
    case null:
      return null;
    case _DocumentSource.camera || _DocumentSource.photos:
      final picked = await ImagePicker().pickImage(
        source: source == _DocumentSource.camera
            ? ImageSource.camera
            : ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 2000,
      );
      if (picked == null) return null;
      return PickedCreditDocument(
        path: picked.path,
        // The picked file's own name, so several photos are told apart.
        name: picked.name.isNotEmpty ? picked.name : 'photo.jpg',
        sizeBytes: await File(picked.path).length(),
      );
    case _DocumentSource.file:
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: creditDocumentExtensions,
      );
      final file = result?.files.firstOrNull;
      final path = file?.path;
      if (file == null || path == null) return null;
      return PickedCreditDocument(
        path: path,
        name: file.name,
        sizeBytes: file.size,
      );
  }
}

/// Whether a cart item has a seller-approved EMI plan still waiting to be
/// checked out. While it does, checkout offers only the EMI path for it: the
/// ordinary "Place Order" would buy the item outright at full price.
bool hasApprovedEmiAwaitingCheckout(WidgetRef ref, List<CartItem> items) {
  if (!ref.watch(emiSignedInProvider)) return false;
  final variants = {
    for (final i in items)
      if (i.variantId != null && i.variantId!.isNotEmpty) i.variantId!,
  };
  if (variants.isEmpty) return false;
  final plans = ref.watch(myPaymentPlansProvider).asData?.value ?? const [];
  return plans.any(
    (a) =>
        variants.contains(a.variantId) &&
        a.guarantor == PlanGuarantor.vendor &&
        a.status == AgreementStatus.approved &&
        a.needsCheckout &&
        a.documentsSubmittedAt != null,
  );
}

/// Picks one document from the device. Overridden in tests.
final creditDocumentPickerProvider = Provider<CreditDocumentPicker>(
  (ref) => _chooseDocument,
);

/// "Pay with EMI", inline on the checkout screen.
///
/// Every cart line whose variant has plan options (`GET /v1/credit/offers/
/// {variantId}`) gets a card that shows the plans right here: each kind on
/// offer, its tenures as chips, the down payment (adjustable when the offer
/// allows), the monthly amount and the total. The figures come from the same
/// arithmetic and quote endpoint as the product page's plan sheet.
///
/// EMI never asks for StyleMint identity verification: the buyer adds an
/// identity document and 1–3 financial proofs on their own page
/// ([CreditDocumentsScreen], opened from "Add documents"), sends the request
/// to the seller, waits for their decision, then pays the down payment. Only pay
/// later / prepay plans the server marks `requiresVerifiedIdentity` (and not
/// `requiresDocuments`) still go through verification.
///
/// A plan covers one item and checks it out on its own
/// (`POST /v1/checkout/sessions/payment-plan`); the rest of the cart stays.
class CheckoutEmiOption extends ConsumerWidget {
  const CheckoutEmiOption({required this.items, super.key});

  final List<CartItem> items;

  static const Key cardKey = Key('checkout-emi-card');

  /// "Add documents" on the plan card: opens [CreditDocumentsScreen].
  static const Key addDocumentsKey = Key('checkout-emi-add-documents');
  static const Key noteKey = Key('checkout-emi-note');
  static const Key loadingKey = Key('checkout-emi-loading');
  static const Key payKey = Key('checkout-emi-pay');
  static const Key verifyKey = Key('checkout-emi-verify');
  static const Key inReviewKey = Key('checkout-emi-in-review');
  static const Key errorKey = Key('checkout-emi-error');
  static const Key documentsKey = Key('checkout-emi-documents');
  static const Key sendKey = Key('checkout-emi-send');
  static const Key waitingKey = Key('checkout-emi-waiting');
  static const Key approvedKey = Key('checkout-emi-approved');
  static const Key payCashKey = Key('checkout-emi-pay-cash');
  static const Key cashPendingKey = Key('checkout-emi-cash-pending');

  /// Ordered on an approved plan, the down payment to be paid online.
  static const Key orderedKey = Key('checkout-emi-ordered');
  static const Key orderedPayKey = Key('checkout-emi-ordered-pay');
  static const Key viewPlanKey = Key('checkout-emi-view-plan');
  static const Key declinedKey = Key('checkout-emi-declined');

  /// Whether a plan-options failure just means "no plan on this item"
  /// (draw nothing) rather than "could not ask" (offer a retry).
  static bool _meansNoPlan(EmiFailure f) =>
      f.isNotFound || f.kind == EmiFailureKind.rejected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final children = <Widget>[];
    var plans = 0;
    for (final item in items) {
      final id = item.variantId;
      if (id == null || id.isEmpty) continue;
      final async = ref.watch(planOptionsProvider(id));
      async.when(
        loading: () => children.add(
          _LoadingRow(key: ValueKey('checkout-emi-loading-$id')),
        ),
        error: (error, _) {
          final failure = error is EmiLoadException ? error.failure : null;
          if (failure != null && _meansNoPlan(failure)) return;
          // Not silently nothing: a buyer whose plans could not be fetched
          // can try again rather than conclude there are none.
          children.add(
            _RetryRow(
              key: ValueKey('checkout-emi-error-$id'),
              onRetry: () => ref.invalidate(planOptionsProvider(id)),
            ),
          );
        },
        data: (options) {
          if (options.options.isEmpty) return;
          plans++;
          // The plans, inline on checkout; only the documents open on their
          // own page.
          children.add(
            CheckoutEmiPlans(
              key: ValueKey('checkout-emi-plans-$id'),
              item: item,
              options: options,
              named: items.length > 1,
            ),
          );
        },
      );
    }
    if (children.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ...children,
        if (plans > 0 && (items.length > 1 || items.any((i) => i.quantity > 1)))
          Padding(
            key: noteKey,
            padding: const EdgeInsets.only(bottom: DesignTokens.s16),
            child: const Text(
              'A payment plan covers one item: paying with EMI checks out that '
              'item on its own, and the rest stays in your cart.',
              style: TextStyle(
                fontFamily: DesignTokens.fontFamily,
                fontSize: 12,
                color: DesignTokens.textMuted,
              ),
            ),
          ),
      ],
    );
  }
}

class _LoadingRow extends StatelessWidget {
  const _LoadingRow({super.key});

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.only(bottom: DesignTokens.s16),
    child: Row(
      children: [
        SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
        SizedBox(width: DesignTokens.s8),
        Text(
          'Checking payment plans…',
          key: CheckoutEmiOption.loadingKey,
          style: TextStyle(
            fontFamily: DesignTokens.fontFamily,
            fontSize: 13,
            color: DesignTokens.textMuted,
          ),
        ),
      ],
    ),
  );
}

class _RetryRow extends StatelessWidget {
  const _RetryRow({required this.onRetry, super.key});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: DesignTokens.s16),
    child: Row(
      children: [
        const Expanded(
          child: Text(
            'Could not load payment plans.',
            key: CheckoutEmiOption.errorKey,
            style: TextStyle(
              fontFamily: DesignTokens.fontFamily,
              fontSize: 13,
              color: DesignTokens.textMuted,
            ),
          ),
        ),
        TextButton(onPressed: onRetry, child: const Text('Retry')),
      ],
    ),
  );
}

/// One kind of plan, as the checkout card offers it.
class _Kind {
  _Kind(this.option)
    : minPercent = option.minDownPaymentPercent,
      maxPercent = option.downPaymentFixed
          ? option.minDownPaymentPercent
          : (option.maxDownPaymentPercent < option.minDownPaymentPercent
                ? option.minDownPaymentPercent
                : option.maxDownPaymentPercent);

  final PlanOption option;
  final int minPercent;
  final int maxPercent;

  PlanKind get kind => option.kind;
  bool get adjustable => maxPercent > minPercent;
}

/// The plans for one cart line, inline.
class CheckoutEmiPlans extends ConsumerStatefulWidget {
  const CheckoutEmiPlans({
    required this.item,
    required this.options,
    this.named = false,
    this.onlyKind,
    this.quoteDebounce = const Duration(milliseconds: 300),
    super.key,
  });

  final CartItem item;
  final PlanOptions options;
  final bool named;

  /// Offer only this kind (the product page's EMI application offers EMI).
  final PlanKind? onlyKind;
  final Duration quoteDebounce;

  @override
  ConsumerState<CheckoutEmiPlans> createState() => _CheckoutEmiPlansState();
}

class _CheckoutEmiPlansState extends ConsumerState<CheckoutEmiPlans> {
  static const _uuid = Uuid();

  late final List<_Kind> _kinds = _orderedKinds();
  late _Kind _kind = _kinds.first;
  late int _percent = _kind.minPercent;
  late int _tenure = _kind.option.tenures.last;

  EmiQuote? _quote;
  Timer? _debounce;
  int _request = 0;

  bool _paying = false;
  String? _error;

  // ── EMI with documents, decided by the seller ──
  final List<PickedCreditDocument> _identity = [];
  final List<PickedCreditDocument> _financial = [];
  final Set<String> _uploaded = {};
  String? _agreementId;
  CreditAgreement? _latest;
  bool _reapplying = false;
  String _submitKey = _uuid.v4();

  /// One key per selection the buyer means to pay for: a retry after a
  /// dropped connection is the same application, not a second one.
  String _applyKey = _uuid.v4();

  String get _variantId => widget.item.variantId!;

  /// EMI (instalment) always goes through the seller with documents; other
  /// kinds when the server says so.
  static bool _needsDocuments(PlanOption o) =>
      o.kind == PlanKind.instalment || o.requiresDocuments;

  /// EMI first, then pay later, then prepay.
  List<_Kind> _orderedKinds() {
    final kinds = [
      for (final o in widget.options.options)
        if (widget.onlyKind == null || o.kind == widget.onlyKind) _Kind(o),
    ];
    int rank(PlanKind k) => switch (k) {
      PlanKind.instalment => 0,
      PlanKind.payLater => 1,
      PlanKind.prepay => 2,
    };
    kinds.sort((a, b) => rank(a.kind).compareTo(rank(b.kind)));
    return kinds;
  }

  @override
  void initState() {
    super.initState();
    _scheduleQuote();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _scheduleQuote() {
    _debounce?.cancel();
    if (_kind.kind != PlanKind.instalment) return;
    _debounce = Timer(widget.quoteDebounce, () => unawaited(_fetchQuote()));
  }

  /// The server's figures for EMI (`GET /v1/emi/quote`), as the plan sheet
  /// uses. Until they arrive — or if they cannot — the device's own
  /// arithmetic (the same contract rounding) is shown.
  Future<void> _fetchQuote() async {
    final request = ++_request;
    final result = await ref
        .read(emiRepositoryProvider)
        .getQuote(
          variantId: _variantId,
          downPaymentPercent: _percent,
          tenureMonths: _tenure,
        );
    if (!mounted || request != _request) return;
    setState(() => _quote = result.fold((_) => null, (q) => q));
  }

  void _select({_Kind? kind, int? percent, int? tenure}) {
    setState(() {
      if (kind != null && !identical(kind, _kind)) {
        _kind = kind;
        _percent = kind.minPercent;
        _tenure = kind.option.tenures.last;
      }
      _percent = percent ?? _percent;
      _tenure = tenure ?? _tenure;
      _quote = null;
      _error = null;
      _applyKey = _uuid.v4();
      _request++;
    });
    _scheduleQuote();
  }

  Future<void> _openKyc() async {
    await context.push(RouteNames.customerKyc);
    // Back at checkout: read the buyer's standing again.
    if (mounted) ref.invalidate(emiEligibilityProvider);
  }

  Future<void> _signIn() async {
    final signedIn = await ensureAuth(context, ref, reason: AuthReason.general);
    if (signedIn && mounted) ref.invalidate(emiEligibilityProvider);
  }

  /// Quote → apply → plan checkout (where the down payment is paid online).
  Future<void> _pay() async {
    final router = GoRouter.of(context);
    setState(() {
      _paying = true;
      _error = null;
    });
    final repo = ref.read(creditRepositoryProvider);
    final quoted = await repo.createQuote(
      variantId: _variantId,
      kind: _kind.kind,
      downPaymentPercent: _kind.adjustable ? _percent : null,
      tenureMonths: _tenure,
    );
    if (!mounted) return;
    final quote = quoted.fold((f) {
      setState(() {
        _paying = false;
        _error = creditFailureMessage(f);
      });
      return null;
    }, (q) => q);
    if (quote == null) return;

    final applied = await repo.apply(
      quoteToken: quote.token,
      idempotencyKey: _applyKey,
    );
    if (!mounted) return;
    applied.fold(
      (f) => setState(() {
        _paying = false;
        _error = creditFailureMessage(f);
      }),
      (agreement) {
        refreshPaymentPlans(ref);
        final args = PlanDetailArgs(
          productName: widget.item.productName,
          justApplied: true,
        );
        switch (agreement.status) {
          case AgreementStatus.approved:
            setState(() => _paying = false);
            unawaited(
              router.push(
                RouteNames.paymentPlanCheckoutPath(agreement.id),
                extra: args,
              ),
            );
          case AgreementStatus.declined:
            setState(() {
              _paying = false;
              _error = agreement.reasons.isEmpty
                  ? 'This plan was not approved.'
                  : 'Not approved: '
                        '${agreement.reasons.map(reasonForBuyer).join(' ')}';
            });
          case AgreementStatus.pendingApproval ||
              AgreementStatus.active ||
              AgreementStatus.completed ||
              AgreementStatus.defaulted ||
              AgreementStatus.cancelled ||
              AgreementStatus.expired ||
              AgreementStatus.reversed:
            // Sent to the seller (a real risk reason), or anything else: the
            // plan's own screen says where it stands and what comes next.
            setState(() => _paying = false);
            unawaited(
              router.push(
                RouteNames.paymentPlanDetailPath(agreement.id),
                extra: args,
              ),
            );
        }
      },
    );
  }

  /// The buyer's latest application for this item, while it is still the
  /// purchase in progress: waiting on the seller, approved and not yet used
  /// for an order, approved and ordered but not yet started (its down payment
  /// still to be paid online, or collected in cash on delivery), or just
  /// declined. An approval buys exactly one order: once the plan starts (or
  /// it is cancelled or lapses) the next attempt is a new application the
  /// seller must approve again.
  CreditAgreement? _liveAgreement() {
    if (!ref.watch(emiSignedInProvider)) return null;
    final plans = ref.watch(myPaymentPlansProvider).asData?.value ?? const [];
    final mine = [
      for (final a in plans)
        if (a.variantId == _variantId && a.guarantor == PlanGuarantor.vendor) a,
    ];

    // An order already placed on a plan for this item is the purchase in
    // progress, whatever else was applied for since: the buyer is shown that
    // order, never offered the plan again.
    final ordered = [
      for (final a in mine)
        if (_isOrdered(a)) a,
    ];
    if (ordered.isNotEmpty) {
      ordered.sort(
        (x, y) => (y.appliedAt ?? DateTime(0)).compareTo(
          x.appliedAt ?? DateTime(0),
        ),
      );
      return ordered.first;
    }

    // What the server says about an application this card started wins over
    // the copy the card kept: it may have been used for an order since.
    final local = _latest;
    final ownId = local?.id ?? _agreementId;
    final server = ownId == null
        ? null
        : mine.where((a) => a.id == ownId).firstOrNull;
    if (server != null && !_isLive(server)) _forgetSpentApplication();

    CreditAgreement? latest = server != null && _isLive(server) ? server : _latest;
    for (final a in mine) {
      if (latest == null ||
          (a.appliedAt != null &&
              latest.appliedAt != null &&
              a.appliedAt!.isAfter(latest.appliedAt!))) {
        latest = a;
      }
    }
    return latest != null && _isLive(latest) ? latest : null;
  }

  /// Approved and checked out: its order exists and waits for the down
  /// payment (online, or in cash when the item is delivered).
  static bool _isOrdered(CreditAgreement a) =>
      a.status == AgreementStatus.approved && !a.needsCheckout;

  bool _isLive(CreditAgreement a) => switch (a.status) {
    AgreementStatus.pendingApproval => true,
    // Ordered on this approval: the order is what the buyer sees until the
    // plan starts.
    AgreementStatus.approved when _isOrdered(a) => true,
    // An approval only counts when the seller decided it from documents the
    // buyer sent with that application. One approved before documents were
    // required (no documentsSubmittedAt) is not carried over: the buyer
    // applies afresh, with documents.
    AgreementStatus.approved => a.documentsSubmittedAt != null,
    AgreementStatus.declined => !_reapplying,
    _ => false,
  };

  /// The application this card started is spent: the next send is a new
  /// application, with new keys, so nothing of the old one is replayed.
  void _forgetSpentApplication() {
    if (_paying) return;
    _latest = null;
    _agreementId = null;
    _uploaded.clear();
    _applyKey = _uuid.v4();
    _submitKey = _uuid.v4();
  }

  /// Opens the documents page for this application. The page edits this
  /// card's own lists, so the picks survive going back; "Send" on that page
  /// comes back here and sends.
  Future<void> _openDocuments(String? resumeAgreementId) async {
    final send = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => CreditDocumentsScreen(
          identity: _identity,
          financial: _financial,
          uploaded: _uploaded,
          productName: widget.item.productName,
        ),
      ),
    );
    if (!mounted) return;
    setState(() => _error = null);
    if (send == true &&
        _identity.isNotEmpty &&
        _financial.isNotEmpty &&
        !_paying) {
      await _sendToSeller(resumeAgreementId);
    }
  }

  /// Quote → apply → upload each document → send to the seller. Each write
  /// keeps its idempotency key across retries; documents already uploaded
  /// are not sent twice.
  Future<void> _sendToSeller(String? resumeAgreementId) async {
    setState(() {
      _paying = true;
      _error = null;
    });
    final repo = ref.read(creditRepositoryProvider);
    var agreementId = resumeAgreementId ?? _agreementId;

    void fail(String message) => setState(() {
      _paying = false;
      _error = message;
    });

    if (agreementId == null) {
      final quoted = await repo.createQuote(
        variantId: _variantId,
        kind: _kind.kind,
        downPaymentPercent: _kind.adjustable ? _percent : null,
        tenureMonths: _tenure,
      );
      if (!mounted) return;
      final quote = quoted.fold((f) {
        fail(creditFailureMessage(f));
        return null;
      }, (q) => q);
      if (quote == null) return;
      final applied = await repo.apply(
        quoteToken: quote.token,
        idempotencyKey: _applyKey,
      );
      if (!mounted) return;
      final agreement = applied.fold((f) {
        fail(creditFailureMessage(f));
        return null;
      }, (a) => a);
      if (agreement == null) return;
      if (agreement.status != AgreementStatus.pendingApproval) {
        // Declined outright (a hard reason), or already decided.
        refreshPaymentPlans(ref);
        setState(() {
          _paying = false;
          _reapplying = false;
          _latest = agreement;
        });
        return;
      }
      agreementId = agreement.id;
      setState(() => _agreementId = agreementId);
    }

    for (final (kind, docs) in [
      (CreditDocumentKind.identity, _identity),
      (CreditDocumentKind.financial, _financial),
    ]) {
      for (final doc in docs) {
        if (_uploaded.contains(doc.path)) continue;
        final up = await repo.uploadDocument(
          agreementId: agreementId,
          kind: kind,
          file: File(doc.path),
          filename: doc.name,
        );
        if (!mounted) return;
        final failure = up.fold((f) => f, (_) => null);
        if (failure != null) {
          fail(
            'Could not upload ${doc.name}: ${creditFailureMessage(failure)}',
          );
          return;
        }
        _uploaded.add(doc.path);
      }
    }

    final submitted = await repo.submitDocuments(
      agreementId: agreementId,
      idempotencyKey: _submitKey,
    );
    if (!mounted) return;
    submitted.fold((f) => fail(creditFailureMessage(f)), (agreement) {
      refreshPaymentPlans(ref);
      setState(() {
        _paying = false;
        _reapplying = false;
        _latest = agreement;
      });
    });
  }

  void _applyAgain() => setState(() {
    _reapplying = true;
    _latest = null;
    _agreementId = null;
    _identity.clear();
    _financial.clear();
    _uploaded.clear();
    _applyKey = _uuid.v4();
    _submitKey = _uuid.v4();
    _error = null;
  });

  void _payDownPayment(CreditAgreement agreement, {bool cash = false}) {
    final args = PlanDetailArgs(
      productName: widget.item.productName,
      justApplied: true,
      cashOnDelivery: cash,
    );
    unawaited(
      context.push(
        agreement.needsCheckout
            ? RouteNames.paymentPlanCheckoutPath(agreement.id)
            : RouteNames.paymentPlanDetailPath(agreement.id),
        extra: args,
      ),
    );
  }

  Widget _documentsSection(Money down, {String? resumeAgreementId}) {
    if (!ref.watch(emiSignedInProvider)) {
      return _Button(label: 'Sign in to apply for EMI', onPressed: _signIn);
    }
    final picked = _identity.length + _financial.length;
    return Column(
      key: CheckoutEmiOption.documentsKey,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'The seller approves EMI on their product. Send them your identity '
          'and proof of income; once they approve, you pay the down payment '
          'here.',
          style: TextStyle(
            fontFamily: DesignTokens.fontFamily,
            fontSize: 12,
            color: DesignTokens.textMuted,
          ),
        ),
        if (picked > 0) ...[
          const SizedBox(height: DesignTokens.s6),
          Text(
            '${_identity.length} identity · ${_financial.length} financial '
            'document${_financial.length == 1 ? '' : 's'} added',
            style: const TextStyle(
              fontFamily: DesignTokens.fontFamily,
              fontSize: 12,
              color: DesignTokens.textWhite,
            ),
          ),
        ],
        const SizedBox(height: DesignTokens.s8),
        _Button(
          key: CheckoutEmiOption.addDocumentsKey,
          label: _paying
              ? 'Sending to the seller…'
              : picked == 0
              ? 'Add documents'
              : 'Review documents and send',
          onPressed: _paying ? null : () => _openDocuments(resumeAgreementId),
        ),
      ],
    );
  }

  Widget _status(CreditAgreement a) {
    final plan =
        '${a.tenureMonths} months · down payment ${_money(a.downPayment)} · '
        'total ${_money(a.totalPayable)}';
    TextStyle muted() => const TextStyle(
      fontFamily: DesignTokens.fontFamily,
      fontSize: 13,
      color: DesignTokens.textMuted,
    );
    return switch (a.status) {
      AgreementStatus.pendingApproval when a.documentsSubmittedAt == null =>
        _documentsSection(a.downPayment, resumeAgreementId: a.id),
      AgreementStatus.pendingApproval => Column(
        key: CheckoutEmiOption.waitingKey,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _Label('Waiting for the seller to approve'),
          Text(plan, style: muted()),
          const SizedBox(height: DesignTokens.s4),
          Text(
            'We will let you know as soon as they decide. Once approved, '
            'you pay the down payment here.',
            style: muted(),
          ),
          const SizedBox(height: DesignTokens.s8),
          _Button(
            label: 'Refresh status',
            outlined: true,
            onPressed: () => setState(() {
              _latest = null;
              refreshPaymentPlans(ref);
            }),
          ),
        ],
      ),
      // Ordered with the down payment in cash: nothing to apply for or pay
      // here — the rider collects the down payment, and the plan starts then.
      AgreementStatus.approved when _isOrdered(a) && a.downPaymentOnDelivery =>
        Column(
          key: CheckoutEmiOption.cashPendingKey,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Label(
              'Ordered — pay ${_money(a.downPayment)} down payment in cash '
              'on delivery',
            ),
            Text(plan, style: muted()),
            const SizedBox(height: DesignTokens.s4),
            Text(
              'Pay the rider ${_money(a.downPayment)} in cash when the item '
              'arrives — only the down payment, not the full price. Your plan '
              'starts that day.',
              style: muted(),
            ),
            const SizedBox(height: DesignTokens.s8),
            _Button(
              key: CheckoutEmiOption.viewPlanKey,
              label: 'View plan',
              outlined: true,
              onPressed: () => _payDownPayment(a),
            ),
          ],
        ),
      // Ordered, the down payment to be paid online: finish that payment from
      // the plan — never a new application.
      AgreementStatus.approved when _isOrdered(a) => Column(
        key: CheckoutEmiOption.orderedKey,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _Label('Ordered — down payment due'),
          Text(plan, style: muted()),
          const SizedBox(height: DesignTokens.s4),
          Text(
            'Your order is placed. Pay the down payment of '
            '${_money(a.downPayment)} to start the plan.',
            style: muted(),
          ),
          const SizedBox(height: DesignTokens.s8),
          _Button(
            key: CheckoutEmiOption.orderedPayKey,
            label: 'Pay down payment ${_money(a.downPayment)}',
            onPressed: () => _payDownPayment(a),
          ),
        ],
      ),
      AgreementStatus.approved => Column(
        key: CheckoutEmiOption.approvedKey,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _Label('Approved by the seller'),
          Text(plan, style: muted()),
          const SizedBox(height: DesignTokens.s8),
          _Button(
            key: CheckoutEmiOption.payKey,
            label: a.cashOnDeliveryDownPaymentAllowed
                ? 'Pay down payment ${_money(a.downPayment)} online'
                : 'Pay down payment ${_money(a.downPayment)}',
            onPressed: () => _payDownPayment(a),
          ),
          if (a.cashOnDeliveryDownPaymentAllowed && a.needsCheckout) ...[
            const SizedBox(height: DesignTokens.s8),
            _Button(
              key: CheckoutEmiOption.payCashKey,
              label:
                  'Pay down payment on delivery (cash) · '
                  '${_money(a.downPayment)}',
              outlined: true,
              onPressed: () => _payDownPayment(a, cash: true),
            ),
            const SizedBox(height: DesignTokens.s4),
            Text(
              'With cash, the rider collects only the down payment. Your '
              'plan starts the day the item is delivered.',
              style: muted(),
            ),
          ],
        ],
      ),
      _ => Column(
        key: CheckoutEmiOption.declinedKey,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _Label('The seller declined this EMI request'),
          Text(
            (a.decisionNote?.isNotEmpty ?? false)
                ? 'Seller’s reason: ${a.decisionNote}'
                : a.reasons.isEmpty
                ? 'No reason was given.'
                : a.reasons.map(reasonForBuyer).join(' '),
            style: muted(),
          ),
          const SizedBox(height: DesignTokens.s8),
          _Button(label: 'Apply again', outlined: true, onPressed: _applyAgain),
        ],
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final price = widget.options.price;
    final local = EmiPlan.compute(
      price: price,
      downPaymentPercent: _percent,
      tenureMonths: _tenure,
    );
    final quote = _quote;
    final confirmed =
        _kind.kind == PlanKind.instalment &&
        quote != null &&
        quote.matches(
          variantId: _variantId,
          downPaymentPercent: _percent,
          tenureMonths: _tenure,
        );
    final down = confirmed ? quote.downPayment : local.downPayment;
    final monthly = confirmed
        ? quote.monthlyInstallment
        : local.monthlyInstallment;
    final total = confirmed ? quote.totalPayable : local.totalPayable;

    final live = _liveAgreement();
    // Already ordered on a plan: the card names the order, not the offer.
    final base = live != null && _isOrdered(live)
        ? 'EMI ordered'
        : 'Pay with EMI';
    final title = widget.named ? '$base · ${widget.item.productName}' : base;

    return Padding(
      padding: const EdgeInsets.only(bottom: DesignTokens.s16),
      child: Container(
        key: widget.named
            ? ValueKey('checkout-emi-card-${widget.item.variantId}')
            : CheckoutEmiOption.cardKey,
        padding: const EdgeInsets.all(DesignTokens.s16),
        decoration: BoxDecoration(
          color: DesignTokens.primaryGreenDark,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.calendar_month_outlined,
                  color: DesignTokens.primaryGreen,
                ),
                const SizedBox(width: DesignTokens.s12),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontFamily: DesignTokens.fontFamily,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: DesignTokens.textWhite,
                    ),
                  ),
                ),
              ],
            ),
            if (live != null) ...[
              const SizedBox(height: DesignTokens.s12),
              _status(live),
            ] else ...[
              if (_kinds.length > 1) ...[
                const SizedBox(height: DesignTokens.s12),
                Wrap(
                  spacing: DesignTokens.s8,
                  runSpacing: DesignTokens.s8,
                  children: [
                    for (final k in _kinds)
                      ChoiceChip(
                        key: Key('checkout-emi-kind-${k.kind.name}'),
                        label: Text(k.kind.label),
                        selected: identical(k, _kind),
                        selectedColor: DesignTokens.chipsSelectedFill,
                        onSelected: (_) => _select(kind: k),
                      ),
                  ],
                ),
              ],
              const SizedBox(height: DesignTokens.s12),
              const _Label('Months'),
              const SizedBox(height: DesignTokens.s6),
              Wrap(
                spacing: DesignTokens.s8,
                runSpacing: DesignTokens.s8,
                children: [
                  for (final months in _kind.option.tenures)
                    ChoiceChip(
                      key: Key('checkout-emi-tenure-$months'),
                      label: Text('$months months'),
                      selected: months == _tenure,
                      selectedColor: DesignTokens.chipsSelectedFill,
                      onSelected: (_) => _select(tenure: months),
                    ),
                ],
              ),
              const SizedBox(height: DesignTokens.s12),
              Row(
                children: [
                  Expanded(
                    child: _Label(
                      _kind.adjustable
                          ? 'Down payment $_percent% (min ${_kind.minPercent}%)'
                          : 'Down payment $_percent%',
                    ),
                  ),
                  if (_kind.adjustable) ...[
                    IconButton(
                      key: const Key('checkout-emi-down-minus'),
                      tooltip: 'Lower down payment',
                      color: DesignTokens.textWhite,
                      onPressed:
                          _percent - emiDownPaymentStep >= _kind.minPercent
                          ? () =>
                                _select(percent: _percent - emiDownPaymentStep)
                          : null,
                      icon: const Icon(Icons.remove_circle_outline),
                    ),
                    IconButton(
                      key: const Key('checkout-emi-down-plus'),
                      tooltip: 'Raise down payment',
                      color: DesignTokens.textWhite,
                      onPressed:
                          _percent + emiDownPaymentStep <= _kind.maxPercent
                          ? () =>
                                _select(percent: _percent + emiDownPaymentStep)
                          : null,
                      icon: const Icon(Icons.add_circle_outline),
                    ),
                  ],
                ],
              ),
              _Figure(
                key: const Key('checkout-emi-down'),
                label: 'Down payment now',
                value: _money(down),
              ),
              _Figure(
                key: const Key('checkout-emi-monthly'),
                label: 'Then monthly',
                value: '${_money(monthly)} × $_tenure',
                emphasised: true,
              ),
              _Figure(
                key: const Key('checkout-emi-total'),
                label: 'Total',
                value: _money(total),
              ),
              const SizedBox(height: DesignTokens.s12),
              // EMI is decided by the seller from the buyer's documents — never
              // by StyleMint identity verification, even when an older server
              // still reports `requiresVerifiedIdentity` for it.
              if (_needsDocuments(_kind.option))
                _documentsSection(down)
              else
                _Cta(
                  requiresVerification: _kind.option.requiresVerifiedIdentity,
                  downPayment: down,
                  paying: _paying,
                  onPay: _pay,
                  onVerify: _openKyc,
                  onSignIn: _signIn,
                ),
              if (_error != null) ...[
                const SizedBox(height: DesignTokens.s8),
                Text(
                  _error!,
                  key: const Key('checkout-emi-pay-error'),
                  style: const TextStyle(
                    fontFamily: DesignTokens.fontFamily,
                    fontSize: 12,
                    color: DesignTokens.colorError,
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

/// Whole rupees without decimals, anything else with two.
String _money(Money money) => formatMoney(
  money,
  decimalDigits: money.amount == money.amount.roundToDouble() ? 0 : 2,
);

class _Label extends StatelessWidget {
  const _Label(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(
      fontFamily: DesignTokens.fontFamily,
      fontSize: 13,
      fontWeight: FontWeight.w600,
      color: DesignTokens.textWhite,
    ),
  );
}

class _Figure extends StatelessWidget {
  const _Figure({
    required this.label,
    required this.value,
    this.emphasised = false,
    super.key,
  });

  final String label;
  final String value;
  final bool emphasised;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontFamily: DesignTokens.fontFamily,
              fontSize: 13,
              color: DesignTokens.textMuted,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontFamily: DesignTokens.fontFamily,
            fontSize: emphasised ? 15 : 13,
            fontWeight: emphasised ? FontWeight.w700 : FontWeight.w500,
            color: emphasised
                ? DesignTokens.primaryGreen
                : DesignTokens.textWhite,
          ),
        ),
      ],
    ),
  );
}

/// The card's button: sign in → get verified → in review → pay.
class _Cta extends ConsumerWidget {
  const _Cta({
    required this.requiresVerification,
    required this.downPayment,
    required this.paying,
    required this.onPay,
    required this.onVerify,
    required this.onSignIn,
  });

  final bool requiresVerification;
  final Money downPayment;
  final bool paying;
  final VoidCallback onPay;
  final VoidCallback onVerify;
  final VoidCallback onSignIn;

  Widget _payButton() => _Button(
    key: CheckoutEmiOption.payKey,
    label: paying
        ? 'Preparing your plan…'
        : 'Pay down payment ${_money(downPayment)}',
    onPressed: paying ? null : onPay,
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ref.watch(emiSignedInProvider)) {
      return _Button(label: 'Sign in to use this plan', onPressed: onSignIn);
    }
    if (!requiresVerification) return _payButton();

    return ref
        .watch(emiEligibilityProvider)
        .when(
          loading: () => const _Button(
            label: 'Checking your verification…',
            onPressed: null,
          ),
          error: (_, _) => _Button(
            label: 'Could not check your verification — try again',
            outlined: true,
            onPressed: () => ref.invalidate(emiEligibilityProvider),
          ),
          data: (value) => switch (value.cta) {
            EmiCta.eligible => _payButton(),
            EmiCta.inReview => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Your verification is in review. You can use this plan as '
                  'soon as it is approved — we will let you know.',
                  key: CheckoutEmiOption.inReviewKey,
                  style: TextStyle(
                    fontFamily: DesignTokens.fontFamily,
                    fontSize: 12,
                    color: DesignTokens.textMuted,
                  ),
                ),
                const SizedBox(height: DesignTokens.s8),
                _Button(
                  label: 'Verification in review',
                  outlined: true,
                  onPressed: onVerify,
                ),
              ],
            ),
            EmiCta.signIn || EmiCta.getVerified => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'This plan needs a verified identity. It takes a few minutes, '
                  'and you come straight back here.',
                  style: TextStyle(
                    fontFamily: DesignTokens.fontFamily,
                    fontSize: 12,
                    color: DesignTokens.textMuted,
                  ),
                ),
                const SizedBox(height: DesignTokens.s8),
                _Button(
                  key: CheckoutEmiOption.verifyKey,
                  label: 'Get verified to use this plan',
                  onPressed: onVerify,
                ),
              ],
            ),
          },
        );
  }
}

class _Button extends StatelessWidget {
  const _Button({
    required this.label,
    required this.onPressed,
    this.outlined = false,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool outlined;

  @override
  Widget build(BuildContext context) {
    final child = Text(label, textAlign: TextAlign.center);
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(DesignTokens.buttonRadius),
    );
    return SizedBox(
      width: double.infinity,
      height: DesignTokens.buttonHeight,
      child: outlined
          ? OutlinedButton(
              onPressed: onPressed,
              style: OutlinedButton.styleFrom(
                foregroundColor: DesignTokens.primaryGreen,
                side: const BorderSide(color: DesignTokens.primaryGreen),
                shape: shape,
              ),
              child: child,
            )
          : FilledButton(
              onPressed: onPressed,
              style: FilledButton.styleFrom(
                backgroundColor: DesignTokens.buttonPrimaryFill,
                foregroundColor: DesignTokens.buttonPrimaryText,
                disabledBackgroundColor: DesignTokens.buttonGrayFill,
                disabledForegroundColor: DesignTokens.buttonGrayText,
                shape: shape,
              ),
              child: child,
            ),
    );
  }
}
