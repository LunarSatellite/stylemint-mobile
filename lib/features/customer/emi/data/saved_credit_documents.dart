import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:stylemint_mobile_frontend/features/customer/emi/domain/entities/credit.dart';
import 'package:uuid/uuid.dart';

/// A document the buyer chose to keep on this phone for future EMI requests.
class SavedCreditDocument {
  const SavedCreditDocument({
    required this.id,
    required this.kind,
    required this.name,
    required this.sizeBytes,
    required this.savedAt,
    required this.path,
  });

  final String id;
  final CreditDocumentKind kind;

  /// The file's original name.
  final String name;
  final int sizeBytes;
  final DateTime savedAt;

  /// The private copy on this device.
  final String path;

  Map<String, dynamic> toJson(String fileName) => {
    'id': id,
    'kind': kind.name,
    'name': name,
    'sizeBytes': sizeBytes,
    'savedAt': savedAt.toUtc().toIso8601String(),
    'file': fileName,
  };
}

/// EMI documents kept on this device, only with the buyer's consent. Nothing
/// is ever sent from here by itself: a saved document is offered on the next
/// application and uploaded fresh to it.
abstract class SavedCreditDocumentStore {
  /// Whether the buyer agreed to keep documents on this phone. Off by
  /// default.
  Future<bool> hasConsent();

  /// Records the buyer's choice. Turning it off deletes everything saved.
  Future<void> setConsent(bool consent);

  Future<List<SavedCreditDocument>> list();

  /// Keeps a private copy of a picked file. Refused (null) without consent.
  Future<SavedCreditDocument?> save({
    required CreditDocumentKind kind,
    required String path,
    required String name,
    required int sizeBytes,
  });

  Future<void> delete(String id);
  Future<void> deleteAll();
}

/// Files under the app's private support directory (`emi-documents/`), never
/// the gallery or shared storage, with an `index.json` of their metadata.
class FileSavedCreditDocumentStore implements SavedCreditDocumentStore {
  FileSavedCreditDocumentStore({Future<Directory> Function()? root})
    : _root = root ?? getApplicationSupportDirectory;

  final Future<Directory> Function() _root;
  static const _uuid = Uuid();

  Future<Directory> _dir() async {
    final dir = Directory('${(await _root()).path}/emi-documents');
    if (!dir.existsSync()) await dir.create(recursive: true);
    return dir;
  }

  Future<File> _index() async => File('${(await _dir()).path}/index.json');

  Future<Map<String, dynamic>> _read() async {
    final file = await _index();
    if (!file.existsSync()) return {'consent': false, 'documents': <dynamic>[]};
    try {
      final json = jsonDecode(await file.readAsString());
      if (json is Map<String, dynamic>) return json;
    } catch (_) {}
    return {'consent': false, 'documents': <dynamic>[]};
  }

  Future<void> _write(Map<String, dynamic> json) async =>
      (await _index()).writeAsString(jsonEncode(json), flush: true);

  @override
  Future<bool> hasConsent() async => (await _read())['consent'] == true;

  @override
  Future<void> setConsent(bool consent) async {
    if (!consent) {
      await deleteAll();
      return;
    }
    final json = await _read();
    json['consent'] = true;
    await _write(json);
  }

  @override
  Future<List<SavedCreditDocument>> list() async {
    final json = await _read();
    if (json['consent'] != true) return const [];
    final dir = await _dir();
    final out = <SavedCreditDocument>[];
    for (final e in (json['documents'] as List<dynamic>? ?? const [])) {
      if (e is! Map) continue;
      final path = '${dir.path}/${e['file']}';
      if (!File(path).existsSync()) continue;
      out.add(
        SavedCreditDocument(
          id: '${e['id']}',
          kind: CreditDocumentKind.values.firstWhere(
            (k) => k.name == e['kind'],
            orElse: () => CreditDocumentKind.financial,
          ),
          name: '${e['name']}',
          sizeBytes: e['sizeBytes'] is num ? (e['sizeBytes'] as num).toInt() : 0,
          savedAt:
              DateTime.tryParse('${e['savedAt']}')?.toLocal() ?? DateTime.now(),
          path: path,
        ),
      );
    }
    return out;
  }

  @override
  Future<SavedCreditDocument?> save({
    required CreditDocumentKind kind,
    required String path,
    required String name,
    required int sizeBytes,
  }) async {
    final json = await _read();
    if (json['consent'] != true) return null;
    final dir = await _dir();
    final id = _uuid.v4();
    final dot = name.lastIndexOf('.');
    final extension = dot >= 0 ? name.substring(dot) : '';
    final fileName = '$id$extension';
    await File(path).copy('${dir.path}/$fileName');
    final doc = SavedCreditDocument(
      id: id,
      kind: kind,
      name: name,
      sizeBytes: sizeBytes,
      savedAt: DateTime.now(),
      path: '${dir.path}/$fileName',
    );
    json['documents'] = [
      ...(json['documents'] as List<dynamic>? ?? const []),
      doc.toJson(fileName),
    ];
    await _write(json);
    return doc;
  }

  @override
  Future<void> delete(String id) async {
    final json = await _read();
    final dir = await _dir();
    final docs = [...(json['documents'] as List<dynamic>? ?? const [])];
    for (final e in docs.whereType<Map<String, dynamic>>().where((e) => e['id'] == id)) {
      final file = File('${dir.path}/${e['file']}');
      if (file.existsSync()) await file.delete();
    }
    json['documents'] = docs
        .where((e) => e is! Map || e['id'] != id)
        .toList();
    await _write(json);
  }

  @override
  Future<void> deleteAll() async {
    final dir = await _dir();
    if (dir.existsSync()) await dir.delete(recursive: true);
    await _write({'consent': false, 'documents': <dynamic>[]});
  }
}

/// The device's saved EMI documents. Overridden in tests.
final savedCreditDocumentStoreProvider = Provider<SavedCreditDocumentStore>(
  (ref) => FileSavedCreditDocumentStore(),
);
