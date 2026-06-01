import 'package:flutter_riverpod/legacy.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../core/network/network_exceptions.dart';
import '../../data/models/registration_dto.dart';
import '../../domain/repositories/auth_repository.dart';

part 'registration_notifier.freezed.dart';

@freezed
abstract class RegistrationState with _$RegistrationState {
  const RegistrationState._();

  const factory RegistrationState.initial() = _RegistrationInitial;

  const factory RegistrationState.step1Sending() = _Step1Sending;
  const factory RegistrationState.step1LoadSuccess(
    RegistrationStartResponseDto response,
  ) = _Step1LoadSuccess;
  const factory RegistrationState.step1LoadNetworkExceptions(NetworkExceptions failure) =
      _Step1LoadNetworkExceptions;

  const factory RegistrationState.step2Sending() = _Step2Sending;
  const factory RegistrationState.step2Success() = _Step2Success;
  const factory RegistrationState.step2NetworkExceptions(NetworkExceptions failure) =
      _Step2NetworkExceptions;

  const factory RegistrationState.step3Sending() = _Step3Sending;
  const factory RegistrationState.step3Success() = _Step3Success;
  const factory RegistrationState.step3NetworkExceptions(NetworkExceptions failure) =
      _Step3NetworkExceptions;

  const factory RegistrationState.step4Sending() = _Step4Sending;
  const factory RegistrationState.step4Success() = _Step4Success;
  const factory RegistrationState.step4NetworkExceptions(NetworkExceptions failure) =
      _Step4NetworkExceptions;

  const factory RegistrationState.step5Sending() = _Step5Sending;
  const factory RegistrationState.step5Success(
    RegistrationCompletionDto completion,
  ) = _Step5Success;
  const factory RegistrationState.step5NetworkExceptions(NetworkExceptions failure) =
      _Step5NetworkExceptions;

  bool get isLoading => maybeWhen(
        step1Sending: () => true,
        step2Sending: () => true,
        step3Sending: () => true,
        step4Sending: () => true,
        step5Sending: () => true,
        orElse: () => false,
      );
}

class RegistrationNotifier extends StateNotifier<RegistrationState> {
  RegistrationNotifier({required this.authRepository})
      : super(const RegistrationState.initial());

  final AuthRepository authRepository;

  String? _accountId;
  String? _email;
  String? _phoneE164;
  RegistrationStartResponseDto? _startResponse;
  RegistrationCompletionDto? _completion;

  String? get accountId => _accountId;
  String? get email => _email;
  String? get phoneE164 => _phoneE164;
  RegistrationStartResponseDto? get startResponse => _startResponse;
  RegistrationCompletionDto? get completion => _completion;

  Future<void> startRegistration({
    required String displayName,
    required String locale,
    required String timezone,
    required String email,
    required String phoneE164,
    required String countryDialCode,
  }) async {
    _email = email;
    _phoneE164 = phoneE164;
    state = const RegistrationState.step1Sending();
    final result = await authRepository.startRegistration(
      displayName: displayName,
      locale: locale,
      timezone: timezone,
      email: email,
      phoneE164: phoneE164,
      countryDialCode: countryDialCode,
    );
    state = result.fold(
      RegistrationState.step1LoadNetworkExceptions,
      (response) {
        _accountId = response.accountId;
        _startResponse = response;
        return RegistrationState.step1LoadSuccess(response);
      },
    );
  }

  Future<void> verifyEmail(String code) async {
    final accountId = _accountId;
    final email = _email;
    if (accountId == null || email == null) return;
    state = const RegistrationState.step2Sending();
    final result = await authRepository.verifyRegistrationEmail(
      accountId,
      email,
      code,
    );
    state = result.fold(
      RegistrationState.step2NetworkExceptions,
      (_) => const RegistrationState.step2Success(),
    );
  }

  Future<void> verifyPhone(String code) async {
    final accountId = _accountId;
    final phoneE164 = _phoneE164;
    if (accountId == null || phoneE164 == null) return;
    state = const RegistrationState.step3Sending();
    final result = await authRepository.verifyRegistrationPhone(
      accountId,
      phoneE164,
      code,
    );
    state = result.fold(
      RegistrationState.step3NetworkExceptions,
      (_) => const RegistrationState.step3Success(),
    );
  }

  Future<void> setPassword(String password) async {
    final accountId = _accountId;
    if (accountId == null) return;
    state = const RegistrationState.step4Sending();
    final result = await authRepository.setRegistrationPassword(
      accountId,
      password,
    );
    state = result.fold(
      RegistrationState.step4NetworkExceptions,
      (_) => const RegistrationState.step4Success(),
    );
  }

  Future<void> acceptTerms(String consentVersion) async {
    final accountId = _accountId;
    if (accountId == null) return;
    state = const RegistrationState.step5Sending();
    final result = await authRepository.acceptRegistrationTerms(
      accountId,
      consentVersion: consentVersion,
    );
    state = result.fold(
      RegistrationState.step5NetworkExceptions,
      (completion) {
        _completion = completion;
        return RegistrationState.step5Success(completion);
      },
    );
  }

  void reset() {
    _accountId = null;
    _email = null;
    _phoneE164 = null;
    _startResponse = null;
    _completion = null;
    state = const RegistrationState.initial();
  }
}
