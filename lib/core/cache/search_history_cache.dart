import 'package:hive_flutter/hive_flutter.dart';

/// Hive yordamida so'nggi 15 ta qidiruv so'rovlarini saqlash.
class SearchHistoryCache {
  static const String _boxName = 'search_history';
  static const String _key = 'queries';
  static const int _maxItems = 15;

  Box? _box;

  Future<void> init() async {
    _box = await Hive.openBox(_boxName);
  }

  Box get _safeBox {
    if (_box == null) {
      throw StateError('SearchHistoryCache not initialized. Call init() first.');
    }
    return _box!;
  }

  /// Barcha saqlangan qidiruv tarixini qaytaradi (eng yangisi birinchi).
  List<String> getQueries() {
    final list = _safeBox.get(_key, defaultValue: <String>[]) as List;
    return list.cast<String>();
  }

  /// Yangi qidiruv so'rovini qo'shadi.
  /// Agar allaqachon mavjud bo'lsa, uni o'rnini yangilaydi.
  /// Faqat oxirgi 15 ta saqlanadi.
  Future<void> addQuery(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return;

    final queries = getQueries();
    queries.remove(trimmed);
    queries.insert(0, trimmed);
    if (queries.length > _maxItems) {
      queries.removeRange(_maxItems, queries.length);
    }
    await _safeBox.put(_key, queries);
  }

  /// Barcha tarixni tozalaydi.
  Future<void> clear() async {
    await _safeBox.put(_key, <String>[]);
  }

  /// Berilgan so'rovni tarixdan o'chiradi.
  Future<void> removeQuery(String query) async {
    final queries = getQueries();
    queries.remove(query);
    await _safeBox.put(_key, queries);
  }
}
