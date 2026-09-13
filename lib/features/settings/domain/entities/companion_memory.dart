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
  const MemoryVault({required this.paused, required this.memories});

  /// True while the customer has paused memory: nothing new is kept.
  final bool paused;
  final List<CompanionMemory> memories;

  MemoryVault copyWith({bool? paused, List<CompanionMemory>? memories}) =>
      MemoryVault(
        paused: paused ?? this.paused,
        memories: memories ?? this.memories,
      );
}
