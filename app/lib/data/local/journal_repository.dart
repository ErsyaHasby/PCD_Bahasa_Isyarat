import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import 'models/translation_entry.dart';

class JournalRepository {
  static const _boxName = 'translation_journal';
  final _uuid = const Uuid();

  Box<TranslationEntry> get _box => Hive.box<TranslationEntry>(_boxName);

  /// Simpan entri terjemahan baru ke jurnal (Hive)
  Future<TranslationEntry> saveEntry({
    required String translatedText,
    required double confidenceScore,
    String? gestureLabel,
  }) async {
    final entry = TranslationEntry(
      id: _uuid.v4(),
      translatedText: translatedText,
      timestamp: DateTime.now(),
      confidenceScore: confidenceScore,
      gestureLabel: gestureLabel,
    );
    await _box.put(entry.id, entry);
    return entry;
  }

  /// Ambil semua entri, urutkan terbaru dulu
  List<TranslationEntry> getAllEntries() {
    final entries = _box.values.toList();
    entries.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return entries;
  }

  /// Ambil entri berdasarkan ID
  TranslationEntry? getEntryById(String id) => _box.get(id);

  /// Hapus entri
  Future<void> deleteEntry(String id) async => await _box.delete(id);

  /// Hapus semua entri (clear journal)
  Future<void> clearAll() async => await _box.clear();

  /// Jumlah total entri
  int get totalEntries => _box.length;

  /// Entri hari ini
  List<TranslationEntry> getTodayEntries() {
    final now = DateTime.now();
    return getAllEntries().where((e) =>
      e.timestamp.year == now.year &&
      e.timestamp.month == now.month &&
      e.timestamp.day == now.day
    ).toList();
  }
}
