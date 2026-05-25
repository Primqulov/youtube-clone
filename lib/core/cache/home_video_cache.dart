import '../../features/youtube/domain/entities/video.dart';

class _CacheEntry {
  final List<Video> videos;
  final DateTime fetchTime;

  _CacheEntry(this.videos, this.fetchTime);

  bool get isFresh =>
      DateTime.now().difference(fetchTime) < HomeVideoCache.cacheDuration;
}

class HomeVideoCache {
  static final HomeVideoCache _instance = HomeVideoCache._();
  factory HomeVideoCache() => _instance;
  HomeVideoCache._();

  final Map<String?, _CacheEntry> _cache = {};
  String? _lastQuery;

  static const Duration cacheDuration = Duration(minutes: 30);

  /// Videos cached for the given [query] (null = home/trending).
  List<Video>? getVideos(String? query) => _cache[query]?.videos;

  /// The last query used for the home feed.
  String? get lastQuery => _lastQuery;

  /// Whether the home feed (query=null) has cached data.
  bool get hasData => _cache[null] != null && _cache[null]!.videos.isNotEmpty;

  /// Whether data for [query] is still fresh (within 30 min).
  bool isFresh(String? query) => _cache[query]?.isFresh ?? false;

  /// Save videos under [query] (null = home/trending).
  void save(List<Video> videos, {String? query}) {
    _cache[query] = _CacheEntry(List.from(videos), DateTime.now());
    if (query != null) _lastQuery = query;
  }

  /// Remove cached data for [query]. If [query] is null, removes home cache.
  void remove(String? query) {
    _cache.remove(query);
  }

  /// Clear ALL cached data.
  void clear() {
    _cache.clear();
    _lastQuery = null;
  }
}
