import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/features/customer/services/domain/entities/banks.dart';
import 'package:stylemint_mobile_frontend/features/customer/services/domain/entities/service_failure.dart';
import 'package:stylemint_mobile_frontend/features/customer/services/domain/entities/service_search.dart';
import 'package:stylemint_mobile_frontend/features/customer/services/domain/service_messages.dart';
import 'package:stylemint_mobile_frontend/features/customer/services/presentation/widgets/bank_widgets.dart';
import 'package:stylemint_mobile_frontend/features/customer/services/presentation/widgets/service_widgets.dart';
import 'package:stylemint_mobile_frontend/features/customer/services/shared/banks_providers.dart';
import 'package:stylemint_mobile_frontend/features/customer/services/shared/services_providers.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_brand_loader.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';
import 'package:uuid/uuid.dart';

/// Keys shared by both forms.
abstract final class BankFormKeys {
  static const Key submit = Key('bank-form-submit');
  static const Key error = Key('bank-form-error');
  static const Key message = Key('bank-enquiry-message');
  static const Key purpose = Key('bank-appointment-purpose');
  static Key field(String key) => Key('bank-field-$key');
  static Key branch(String id) => Key('bank-branch-$id');
  static Key day(DateTime d) => Key('bank-day-${serviceWireDate(d)}');
  static Key slot(String id) => Key('bank-slot-$id');
}

/// Contact fields + consent, shared by the enquiry and appointment forms.
mixin _ContactFormState<T extends ConsumerStatefulWidget> on ConsumerState<T> {
  final formKey = GlobalKey<FormState>();
  final name = TextEditingController();
  final phone = TextEditingController();
  final email = TextEditingController();
  PreferredContactMethod method = PreferredContactMethod.phone;
  bool consent = false;
  bool consentError = false;
  bool busy = false;
  String? error;

  /// One key per request the buyer means to send; a retry reuses it.
  String requestKey = const Uuid().v4();

  void initContact() {
    final known = ref.read(servicesBuyerNameProvider);
    if (known != null) name.text = known;
  }

  void disposeContact() {
    name.dispose();
    phone.dispose();
    email.dispose();
  }

  ContactDetails get contact => ContactDetails(
    name: name.text.trim(),
    phone: phone.text.replaceAll(RegExp(r'[\s\-]'), ''),
    email: email.text.trim().isEmpty ? null : email.text.trim(),
    preferredMethod: method,
  );

  /// The form is valid and the buyer ticked consent. Nothing is sent
  /// otherwise.
  bool readyToSend() {
    final valid = formKey.currentState?.validate() ?? false;
    setState(() => consentError = !consent);
    return valid && consent;
  }

  Widget contactSection(String bankName, BankConsent consentWording) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const ServiceSectionTitle('How the bank reaches you'),
      Text(
        'Only what you enter here is shared, and only with $bankName.',
        style: DesignTokens.tiny.copyWith(color: DesignTokens.textMuted),
      ),
      const SizedBox(height: DesignTokens.s12),
      BankContactFields(
        name: name,
        phone: phone,
        email: email,
        method: method,
        onMethodChanged: (m) => setState(() => method = m),
      ),
      const SizedBox(height: DesignTokens.s16),
      BankConsentBox(
        bankName: bankName,
        consent: consentWording,
        accepted: consent,
        showError: consentError,
        onChanged: (v) => setState(() {
          consent = v;
          if (v) consentError = false;
        }),
      ),
    ],
  );

  Widget errorLine() => error == null
      ? const SizedBox.shrink()
      : Padding(
          padding: const EdgeInsets.only(top: DesignTokens.s8),
          child: Text(
            error!,
            key: BankFormKeys.error,
            style: DesignTokens.smallRegular.copyWith(
              color: DesignTokens.colorError,
            ),
          ),
        );

  /// A failed send: its sentence, and — when the consent wording changed —
  /// the new wording, unticked.
  void onSendFailed(ServiceFailure failure, EnquiryFormKey formKeyUsed) {
    setState(() {
      busy = false;
      error = serviceFailureMessage(failure, what: 'your request');
      if (failure.code == 'service_enquiry.consent_outdated' ||
          failure.code == 'service_enquiry.consent_required') {
        consent = false;
      }
    });
    if (failure.code == 'service_enquiry.consent_outdated') {
      ref.invalidate(enquiryFormProvider(formKeyUsed));
    }
  }
}

// ── Enquiry ──────────────────────────────────────────────────────────────────

/// An enquiry about one product: the bank's own questions for the product
/// type, a message, the buyer's contact details and an explicit consent
/// naming the bank.
class BankEnquiryScreen extends ConsumerWidget {
  const BankEnquiryScreen({required this.productId, super.key});

  final String productId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final product = ref.watch(bankProductProvider(productId));
    return Scaffold(
      backgroundColor: DesignTokens.bgAppFoundation,
      appBar: AppBar(
        backgroundColor: DesignTokens.bgAppFoundation,
        title: const Text('Enquire'),
      ),
      body: SafeArea(
        child: product.when(
          loading: () => const SmPageLoader(),
          error: (error, _) => ListView(
            children: [
              ServiceFailureView(
                error: error,
                what: 'this product',
                onRetry: () => ref.invalidate(bankProductProvider(productId)),
              ),
            ],
          ),
          data: (p) {
            final key = (
              bankId: p.bankId,
              productType: p.type,
              kind: LeadKind.enquiry,
            );
            return ref
                .watch(enquiryFormProvider(key))
                .when(
                  loading: () => const SmPageLoader(),
                  error: (error, _) => ListView(
                    children: [
                      ServiceFailureView(
                        error: error,
                        what: 'the enquiry form',
                        onRetry: () => ref.invalidate(enquiryFormProvider(key)),
                      ),
                    ],
                  ),
                  data: (form) =>
                      _EnquiryForm(product: p, form: form, formKey: key),
                );
          },
        ),
      ),
    );
  }
}

class _EnquiryForm extends ConsumerStatefulWidget {
  const _EnquiryForm({
    required this.product,
    required this.form,
    required this.formKey,
  });

  final BankProduct product;
  final EnquiryForm form;
  final EnquiryFormKey formKey;

  @override
  ConsumerState<_EnquiryForm> createState() => _EnquiryFormState();
}

class _EnquiryFormState extends ConsumerState<_EnquiryForm>
    with _ContactFormState<_EnquiryForm> {
  final _answers = <String, String>{};
  final _controllers = <String, TextEditingController>{};
  final _message = TextEditingController();

  @override
  void initState() {
    super.initState();
    initContact();
  }

  @override
  void dispose() {
    disposeContact();
    _message.dispose();
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  String get _bankName => widget.form.bankName.isNotEmpty
      ? widget.form.bankName
      : widget.product.bankName;

  TextEditingController _controller(String key) =>
      _controllers.putIfAbsent(key, TextEditingController.new);

  Map<String, String> get _answerMap => {
    for (final f in widget.form.fields)
      if (switch (f.type) {
            FormFieldType.select ||
            FormFieldType.date ||
            FormFieldType.boolean => _answers[f.key],
            _ => _controllers[f.key]?.text.trim(),
          }
          case final v? when v.isNotEmpty)
        f.key: v,
  };

  Future<void> _send() async {
    if (!readyToSend()) return;
    setState(() {
      busy = true;
      error = null;
    });
    final result = await ref
        .read(banksRepositoryProvider)
        .submitEnquiry(
          bankId: widget.product.bankId,
          productType: widget.product.type,
          productId: widget.product.id,
          answers: _answerMap,
          message: _message.text,
          contact: contact,
          consentVersion: widget.form.consent.version,
          idempotencyKey: requestKey,
        );
    if (!mounted) return;
    result.fold((failure) => onSendFailed(failure, widget.formKey), (lead) {
      ref.invalidate(myEnquiriesProvider);
      context.pushReplacement(
        '${RouteNames.bankEnquiryDetailPath(lead.id)}?sent=1',
      );
    });
  }

  String? _validate(EnquiryFormField f, String? raw) {
    final v = raw?.trim() ?? '';
    if (v.isEmpty) return f.required ? 'Required' : null;
    if (f.maxLength != null && v.length > f.maxLength!) {
      return 'Keep it under ${f.maxLength} characters';
    }
    if (v.length > 200) return 'Keep it under 200 characters';
    if (f.type == FormFieldType.number || f.type == FormFieldType.amount) {
      final n = double.tryParse(v.replaceAll(',', ''));
      if (n == null) return 'Enter a number';
      if (f.min != null && n < f.min!) return 'At least ${_num(f.min!)}';
      if (f.max != null && n > f.max!) return 'At most ${_num(f.max!)}';
    }
    return null;
  }

  static String _num(double v) =>
      v == v.roundToDouble() ? '${v.toInt()}' : '$v';

  Widget _field(EnquiryFormField f) {
    final label = f.required ? '${f.label} *' : f.label;
    switch (f.type) {
      case FormFieldType.select:
        return DropdownButtonFormField<String>(
          key: BankFormKeys.field(f.key),
          initialValue: _answers[f.key],
          decoration: serviceInputDecoration(label),
          dropdownColor: DesignTokens.bgAppBodyLight,
          items: [
            for (final o in f.options)
              DropdownMenuItem(value: o, child: Text(o)),
          ],
          onChanged: (v) => setState(() {
            if (v == null) {
              _answers.remove(f.key);
            } else {
              _answers[f.key] = v;
            }
          }),
          validator: (v) => f.required && (v == null || v.isEmpty)
              ? 'Choose one'
              : null,
        );
      case FormFieldType.boolean:
        return SwitchListTile(
          key: BankFormKeys.field(f.key),
          contentPadding: EdgeInsets.zero,
          title: Text(f.label, style: DesignTokens.smallRegular),
          value: _answers[f.key] == 'true',
          onChanged: (v) => setState(() => _answers[f.key] = '$v'),
        );
      case FormFieldType.date:
        final picked = _answers[f.key];
        return FormField<String>(
          key: BankFormKeys.field(f.key),
          validator: (_) =>
              f.required && (picked == null || picked.isEmpty) ? 'Required' : null,
          builder: (state) => ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(label, style: DesignTokens.smallRegular),
            subtitle: Text(
              state.errorText ?? picked ?? 'Choose a date',
              style: DesignTokens.tiny.copyWith(
                color: state.hasError
                    ? DesignTokens.colorError
                    : DesignTokens.textMuted,
              ),
            ),
            trailing: const Icon(Icons.calendar_today_outlined, size: 18),
            onTap: () async {
              final today = kathmanduDay(ref.read(servicesClockProvider)());
              final d = await showDatePicker(
                context: context,
                firstDate: DateTime(today.year - 100),
                lastDate: DateTime(today.year + 30),
                initialDate: today,
              );
              if (d != null && mounted) {
                setState(() => _answers[f.key] = serviceWireDate(d));
              }
            },
          ),
        );
      case FormFieldType.text:
      case FormFieldType.textArea:
      case FormFieldType.number:
      case FormFieldType.amount:
        final numeric =
            f.type == FormFieldType.number || f.type == FormFieldType.amount;
        return TextFormField(
          key: BankFormKeys.field(f.key),
          controller: _controller(f.key),
          keyboardType: numeric ? TextInputType.number : TextInputType.text,
          maxLines: f.type == FormFieldType.textArea ? 4 : 1,
          style: DesignTokens.smallRegular,
          decoration: serviceInputDecoration(label),
          validator: (v) => _validate(f, v),
        );
    }
  }

  @override
  Widget build(BuildContext context) => Form(
    key: formKey,
    child: ListView(
      padding: const EdgeInsets.all(DesignTokens.s16),
      children: [
        Text(widget.product.name, style: DesignTokens.h3),
        Text(
          _bankName,
          style: DesignTokens.smallRegular.copyWith(
            color: DesignTokens.textMuted,
          ),
        ),
        if (widget.form.fields.isNotEmpty) ...[
          const ServiceSectionTitle('About your enquiry'),
          for (final f in widget.form.fields) ...[
            _field(f),
            const SizedBox(height: DesignTokens.s12),
          ],
        ],
        TextFormField(
          key: BankFormKeys.message,
          controller: _message,
          maxLines: 3,
          maxLength: 1000,
          style: DesignTokens.smallRegular,
          decoration: serviceInputDecoration('Anything else? (optional)'),
        ),
        contactSection(_bankName, widget.form.consent),
        errorLine(),
        const SizedBox(height: DesignTokens.s16),
        ServicePrimaryButton(
          key: BankFormKeys.submit,
          label: 'Send enquiry to $_bankName',
          busy: busy,
          onPressed: () => unawaited(_send()),
        ),
        const SizedBox(height: DesignTokens.s24),
      ],
    ),
  );
}

// ── Appointment ─────────────────────────────────────────────────────────────

/// A branch appointment: branch, day, slot, purpose, contact and consent.
class BankAppointmentScreen extends ConsumerWidget {
  const BankAppointmentScreen({required this.bankId, this.productId, super.key});

  final String bankId;
  final String? productId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bank = ref.watch(bankDetailProvider(bankId));
    return Scaffold(
      backgroundColor: DesignTokens.bgAppFoundation,
      appBar: AppBar(
        backgroundColor: DesignTokens.bgAppFoundation,
        title: const Text('Branch appointment'),
      ),
      body: SafeArea(
        child: bank.when(
          loading: () => const SmPageLoader(),
          error: (error, _) => ListView(
            children: [
              ServiceFailureView(
                error: error,
                what: 'this bank',
                onRetry: () => ref.invalidate(bankDetailProvider(bankId)),
              ),
            ],
          ),
          data: (b) {
            final product = productId == null
                ? null
                : b.products.where((p) => p.id == productId).firstOrNull;
            final key = (
              bankId: b.id,
              productType: product?.type ?? BankProductType.other,
              kind: LeadKind.appointment,
            );
            return ref
                .watch(enquiryFormProvider(key))
                .when(
                  loading: () => const SmPageLoader(),
                  error: (error, _) => ListView(
                    children: [
                      ServiceFailureView(
                        error: error,
                        what: 'the appointment form',
                        onRetry: () => ref.invalidate(enquiryFormProvider(key)),
                      ),
                    ],
                  ),
                  data: (form) => _AppointmentForm(
                    bank: b,
                    product: product,
                    form: form,
                    formKey: key,
                  ),
                );
          },
        ),
      ),
    );
  }
}

class _AppointmentForm extends ConsumerStatefulWidget {
  const _AppointmentForm({
    required this.bank,
    required this.product,
    required this.form,
    required this.formKey,
  });

  final BankDetail bank;
  final BankProduct? product;
  final EnquiryForm form;
  final EnquiryFormKey formKey;

  @override
  ConsumerState<_AppointmentForm> createState() => _AppointmentFormState();
}

class _AppointmentFormState extends ConsumerState<_AppointmentForm>
    with _ContactFormState<_AppointmentForm> {
  final _purpose = TextEditingController();
  String? _branchId;
  DateTime? _day;
  AvailabilitySlot? _slot;
  bool _slotError = false;

  List<BankBranch> get _branches => [
    for (final b in widget.bank.branches)
      if (b.appointmentsEnabled) b,
  ];

  @override
  void initState() {
    super.initState();
    initContact();
    final branches = _branches;
    if (branches.length == 1) _branchId = branches.single.id;
    if (widget.product != null) {
      _purpose.text = 'About ${widget.product!.name}';
    }
  }

  @override
  void dispose() {
    disposeContact();
    _purpose.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final ready = readyToSend();
    final slot = _slot;
    final day = _day;
    final branchId = _branchId;
    setState(() => _slotError = slot == null);
    if (!ready || slot == null || day == null || branchId == null) return;
    setState(() {
      busy = true;
      error = null;
    });
    final result = await ref
        .read(banksRepositoryProvider)
        .bookAppointment(
          branchId: branchId,
          slotId: slot.slotId,
          date: day,
          productId: widget.product?.id,
          productType: widget.product?.type,
          purpose: _purpose.text,
          contact: contact,
          consentVersion: widget.form.consent.version,
          idempotencyKey: requestKey,
        );
    if (!mounted) return;
    result.fold(
      (failure) {
        onSendFailed(failure, widget.formKey);
        // A full or vanished slot: show the branch's fresh availability.
        if (failure.kind == ServiceFailureKind.conflict) {
          ref.invalidate(branchAvailabilityProvider(branchId));
          setState(() {
            _slot = null;
            requestKey = const Uuid().v4();
          });
        }
      },
      (appointment) {
        ref
          ..invalidate(myAppointmentsProvider)
          ..invalidate(myEnquiriesProvider);
        context.pushReplacement(
          '${RouteNames.bankAppointmentDetailPath(appointment.id)}?sent=1',
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final branches = _branches;
    final branchId = _branchId;
    return Form(
      key: formKey,
      child: ListView(
        padding: const EdgeInsets.all(DesignTokens.s16),
        children: [
          Text(widget.bank.name, style: DesignTokens.h3),
          if (widget.product != null)
            Text(
              widget.product!.name,
              style: DesignTokens.smallRegular.copyWith(
                color: DesignTokens.textMuted,
              ),
            ),
          const ServiceSectionTitle('Branch'),
          if (branches.isEmpty)
            Text(
              'No branch of this bank takes appointments on StyleMint yet.',
              key: const Key('bank-no-branches'),
              style: DesignTokens.smallRegular.copyWith(
                color: DesignTokens.textMuted,
              ),
            )
          else
            RadioGroup<String>(
              groupValue: branchId,
              onChanged: (id) => setState(() {
                _branchId = id;
                _day = null;
                _slot = null;
              }),
              child: Column(
                children: [
                  for (final br in branches)
                    RadioListTile<String>(
                      key: BankFormKeys.branch(br.id),
                      value: br.id,
                      contentPadding: EdgeInsets.zero,
                      title: Text(br.name, style: DesignTokens.smallRegular),
                      subtitle: br.address.isEmpty
                          ? null
                          : Text(
                              br.address,
                              style: DesignTokens.tiny.copyWith(
                                color: DesignTokens.textMuted,
                              ),
                            ),
                    ),
                ],
              ),
            ),
          if (branchId != null) _availability(branchId),
          if (_slotError && _slot == null)
            Text(
              'Choose a day and a time.',
              key: const Key('bank-slot-error'),
              style: DesignTokens.tiny.copyWith(color: DesignTokens.colorError),
            ),
          const SizedBox(height: DesignTokens.s12),
          TextFormField(
            key: BankFormKeys.purpose,
            controller: _purpose,
            maxLength: 200,
            style: DesignTokens.smallRegular,
            decoration: serviceInputDecoration(
              'What is it about? (optional)',
              hint: 'Open a savings account',
            ),
          ),
          contactSection(widget.bank.name, widget.form.consent),
          errorLine(),
          const SizedBox(height: DesignTokens.s16),
          ServicePrimaryButton(
            key: BankFormKeys.submit,
            label: 'Book appointment',
            busy: busy,
            onPressed: branches.isEmpty ? null : () => unawaited(_send()),
          ),
          const SizedBox(height: DesignTokens.s24),
        ],
      ),
    );
  }

  Widget _availability(String branchId) => ref
      .watch(branchAvailabilityProvider(branchId))
      .when(
        loading: () => const Padding(
          padding: EdgeInsets.all(DesignTokens.s16),
          child: Center(child: CircularProgressIndicator()),
        ),
        error: (error, _) => ServiceFailureView(
          error: error,
          what: 'the free times',
          compact: true,
          onRetry: () => ref.invalidate(branchAvailabilityProvider(branchId)),
        ),
        data: (availability) {
          final days = [
            for (final d in availability.days)
              if (d.hasBookable) d,
          ];
          if (days.isEmpty) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: DesignTokens.s8),
              child: Text(
                'No free times in the next two weeks. Try another branch.',
                key: const Key('bank-no-slots'),
                style: DesignTokens.smallRegular.copyWith(
                  color: DesignTokens.textMuted,
                ),
              ),
            );
          }
          final day = days.where((d) => d.date == _day).firstOrNull;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const ServiceSectionTitle('Day'),
              SizedBox(
                height: 40,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    for (final d in days)
                      Padding(
                        padding: const EdgeInsets.only(right: DesignTokens.s8),
                        child: ChoiceChip(
                          key: BankFormKeys.day(d.date),
                          label: Text(serviceShortDate(d.date)),
                          selected: _day == d.date,
                          onSelected: (_) => setState(() {
                            _day = d.date;
                            _slot = null;
                          }),
                        ),
                      ),
                  ],
                ),
              ),
              if (day != null) ...[
                const ServiceSectionTitle('Time'),
                Wrap(
                  spacing: DesignTokens.s8,
                  runSpacing: DesignTokens.s8,
                  children: [
                    for (final s in day.slots)
                      ChoiceChip(
                        key: BankFormKeys.slot(s.slotId),
                        label: Text(
                          s.endTime.isEmpty
                              ? s.startTime
                              : '${s.startTime}–${s.endTime}',
                        ),
                        selected: _slot?.slotId == s.slotId,
                        onSelected: s.bookable
                            ? (_) => setState(() => _slot = s)
                            : null,
                      ),
                  ],
                ),
              ],
            ],
          );
        },
      );
}
