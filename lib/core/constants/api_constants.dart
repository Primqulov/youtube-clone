class ApiConstants {
  ApiConstants._();

  // Build vaqtida o'rnatish: --dart-define=YOUTUBE_API_KEY=YOUR_KEY
  // Default qiymat git tarixiga tushgan eski kalit — uni iloji boricha
  // almashtirib, defaultValue'ni bo'sh stringga o'tkazing.
  static const String apiKey = String.fromEnvironment(
    'YOUTUBE_API_KEY',
    defaultValue: 'AIzaSyCSdeBsc-c8BXU0hivTLOz8kt8epGRgJr0',
  );

  static const String baseUrl = 'https://www.googleapis.com/youtube/v3';
  static const int maxResults = 50;

  static String searchUrl(
    String query, {
    String? pageToken,
    String? videoDuration,
  }) {
    final encodedQuery = Uri.encodeQueryComponent(query);
    final buffer = StringBuffer(
      '$baseUrl/search?part=snippet&q=$encodedQuery&type=video'
      '&videoEmbeddable=true&videoSyndicated=true'
      '&maxResults=$maxResults&key=$apiKey',
    );
    if (videoDuration != null) buffer.write('&videoDuration=$videoDuration');
    if (pageToken != null) buffer.write('&pageToken=$pageToken');
    return buffer.toString();
  }

  static String trendingUrl({String? pageToken, String regionCode = 'US'}) {
    final buffer = StringBuffer(
      '$baseUrl/videos?part=snippet,statistics,contentDetails'
      '&chart=mostPopular&regionCode=$regionCode'
      '&maxResults=$maxResults&key=$apiKey',
    );
    if (pageToken != null) buffer.write('&pageToken=$pageToken');
    return buffer.toString();
  }

  static String videoDetailsUrl(String videoId) {
    return '$baseUrl/videos?part=snippet,statistics,contentDetails'
        '&id=$videoId&key=$apiKey';
  }

  static String videosByIdsUrl(Iterable<String> videoIds) {
    final ids = videoIds.where((id) => id.isNotEmpty).join(',');
    return '$baseUrl/videos?part=snippet,statistics,contentDetails'
        '&id=$ids&maxResults=$maxResults&key=$apiKey';
  }

  static String channelUrl(String channelId) {
    return '$baseUrl/channels?part=snippet,statistics'
        '&id=$channelId&key=$apiKey';
  }

  static String channelsByIdsUrl(Iterable<String> channelIds) {
    final ids = channelIds.where((id) => id.isNotEmpty).join(',');
    return '$baseUrl/channels?part=snippet&id=$ids'
        '&maxResults=$maxResults&key=$apiKey';
  }

  static String channelVideosUrl(String channelId, {String? pageToken}) {
    final buffer = StringBuffer(
      '$baseUrl/search?part=snippet&channelId=$channelId&type=video'
      '&order=date&maxResults=$maxResults&key=$apiKey',
    );
    if (pageToken != null) buffer.write('&pageToken=$pageToken');
    return buffer.toString();
  }

  static String commentsUrl(
    String videoId, {
    String? pageToken,
    String order = 'relevance',
  }) {
    final buffer = StringBuffer(
      '$baseUrl/commentThreads?part=snippet&videoId=$videoId'
      '&order=$order&maxResults=$maxResults&key=$apiKey',
    );
    if (pageToken != null) buffer.write('&pageToken=$pageToken');
    return buffer.toString();
  }

  static String videoThumbnailUrl(
    String videoId, {
    String quality = 'maxresdefault',
  }) {
    return 'https://img.youtube.com/vi/$videoId/$quality.jpg';
  }
}
