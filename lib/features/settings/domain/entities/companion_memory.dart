import 'package:stylemint_mobile_frontend/features/settings/domain/entities/memory_consent.dart';

/// Something the StyleMint companion remembers about the customer.
class CompanionMemory {
  const CompanionMemory({
    required this.id,
    required this.content,
    required this.rememberedAt,
    this.category,
  });

  final String id;
  final String content;
  final DateTime rememberedAt;

  /// What kind of memory it is (e.g. "Purchase", "Liked"), when known.
  final String? category;

  CompanionMemory copyWith({String? content}) => CompanionMemory(
    id: id,
    content: content ?? this.content,
    rememberedAt: rememberedAt,
    category: category,
  );
}

/// Everything the companion remembers, and whether it may remember more.
class MemoryVault {
  const MemoryVault({
    required this.paused,
    required this.memories,
    this.consents = const [],
  });

  /// True while the customer has paused memory: nothing new is kept. This
  /// stays the kill switch — it overrides every entry in [consents].
  final bool paused;
  final List<CompanionMemory> memories;

  /// The decision for each vault purpose. Empty means nothing was reported,
  /// which reads as undecided, never as agreement.
  final List<MemoryConsent> consents;

  /// The decision for [purpose], or an undecided one when the backend did
  /// not mention it. Absence is not consent.
  MemoryConsent consentFor(MemoryPurpose purpose) {
    for (final consent in consents) {
      if (consent.purpose == purpose) return consent;
    }
    return MemoryConsent.undecidedFor(purpose);
  }

  /// Decisions for purposes this build cannot name, kept so a customer can
  /// still see and refuse them.
  Iterable<MemoryConsent> get unknownConsents =>
      consents.where((consent) => consent.purpose == null);

  MemoryVault copyWith({
    bool? paused,
    List<CompanionMemory>? memories,
    List<MemoryConsent>? consents,
  }) => MemoryVault(
    paused: paused ?? this.paused,
    memories: memories ?? this.memories,
    consents: consents ?? this.consents,
  );

  /// [consents] with the decision for [code] replaced, adding it when the
  /// backend had not reported that purpose at all.
  List<MemoryConsent> withConsent(int code, MemoryConsent replacement) {
    final replaced = [
      for (final consent in consents)
        consent.purposeCode == code ? replacement : consent,
    ];
    final hit = consents.any((consent) => consent.purposeCode == code);
    return hit ? replaced : [...replaced, replacement];
  }
}
