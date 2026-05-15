class ApiConstants {
  ApiConstants._();

  static const String apiKey = 'AIzaSyCSdeBsc-c8BXU0hivTLOz8kt8epGRgJr0';
  static const String baseUrl = 'https://www.googleapis.com/youtube/v3';

  static const int maxResults = 20;

  static String searchUrl(String query, {String? pageToken}) {
    final buffer = StringBuffer(
      '$baseUrl/search?part=snippet&q=$query&type=video&maxResults=$maxResults&key=$apiKey',
    );
    if (pageToken != null) {
      buffer.write('&pageToken=$pageToken');
    }
    return buffer.toString();
  }

  static String trendingUrl({String? pageToken, String regionCode = 'US'}) {
    final buffer = StringBuffer(
      '$baseUrl/videos?part=snippet,statistics,contentDetails&chart=mostPopular&regionCode=$regionCode&maxResults=$maxResults&key=$apiKey',
    );
    if (pageToken != null) {
      buffer.write('&pageToken=$pageToken');
    }
    return buffer.toString();
  }

  static String videoDetailsUrl(String videoId) {
    return '$baseUrl/videos?part=snippet,statistics,contentDetails&id=$videoId&key=$apiKey';
  }

  static String channelUrl(String channelId) {
    return '$baseUrl/channels?part=snippet,statistics&id=$channelId&key=$apiKey';
  }

  static String videoThumbnailUrl(String videoId, {String quality = 'maxresdefault'}) {
    return 'https://img.youtube.com/vi/$videoId/$quality.jpg';
  }
}
