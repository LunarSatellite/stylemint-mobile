import 'package:flutter_test/flutter_test.dart';
import 'package:stylemint_mobile_frontend/features/settings/data/datasources/memory_vault_remote_datasource.dart';

void main() {
  test('maps a backend memory with a named category', () {
    final memory = companionMemoryFromJson({
      'id': 'm1',
      'content': 'Prefers size M',
      'category': 'Liked',
      'createdUtc': '2026-09-01T10:00:00Z',
    });

    expect(memory.id, 'm1');
    expect(memory.content, 'Prefers size M');
    expect(memory.category, 'Liked');
    expect(memory.rememberedAt.toUtc(), DateTime.utc(2026, 9, 1, 10));
  });

  test('reads a numeric category and tolerates unknown ones', () {
    expect(companionMemoryFromJson({'category': 1}).category, 'Purchase');
    expect(companionMemoryFromJson({'category': 42}).category, isNull);
  });
}
