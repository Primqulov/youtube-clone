const _defaultThumbnailPreference = [
  'maxres',
  'high',
  'medium',
  'default',
];

String pickBestThumbnailUrl(
  Map<String, dynamic>? thumbnails, {
  List<String> preference = _defaultThumbnailPreference,
}) {
  if (thumbnails == null || thumbnails.isEmpty) return '';
  for (final key in preference) {
    final entry = thumbnails[key] as Map<String, dynamic>?;
    final url = entry?['url'] as String?;
    if (url != null && url.isNotEmpty) return url;
  }
  return '';
}
