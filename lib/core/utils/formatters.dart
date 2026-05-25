import '../constants/app_strings.dart';

class Formatters {
  Formatters._();

  static String compactCount(String count) {
    final n = int.tryParse(count) ?? 0;
    if (n >= 1000000000) return '${(n / 1000000000).toStringAsFixed(1)}${AppStrings.compactB}';
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}${AppStrings.compactM}';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}${AppStrings.compactK}';
    return n.toString();
  }

  static String timeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inDays >= 365) return '${(diff.inDays / 365).floor()}${AppStrings.timeAgoYears}';
    if (diff.inDays >= 30) return '${(diff.inDays / 30).floor()}${AppStrings.timeAgoMonths}';
    if (diff.inDays >= 7) return '${(diff.inDays / 7).floor()}${AppStrings.timeAgoWeeks}';
    if (diff.inDays > 0) return '${diff.inDays}${AppStrings.timeAgoDays}';
    if (diff.inHours > 0) return '${diff.inHours}${AppStrings.timeAgoHours}';
    if (diff.inMinutes > 0) return '${diff.inMinutes}${AppStrings.timeAgoMinutes}';
    return AppStrings.timeAgoJustNow;
  }

  static final RegExp _isoDurationRegex = RegExp(
    r'PT(?:(\d+)H)?(?:(\d+)M)?(?:(\d+)S)?',
  );

  static (int h, int m, int s)? _parseIsoDuration(String iso) {
    if (iso.isEmpty) return null;
    final match = _isoDurationRegex.firstMatch(iso);
    if (match == null) return null;
    return (
      int.tryParse(match.group(1) ?? '') ?? 0,
      int.tryParse(match.group(2) ?? '') ?? 0,
      int.tryParse(match.group(3) ?? '') ?? 0,
    );
  }

  static String isoDuration(String iso) {
    final parts = _parseIsoDuration(iso);
    if (parts == null) return '';
    final (h, m, s) = parts;
    if (h > 0) {
      return '$h:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    }
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  static int isoDurationSeconds(String iso) {
    final parts = _parseIsoDuration(iso);
    if (parts == null) return 0;
    final (h, m, s) = parts;
    return h * 3600 + m * 60 + s;
  }

  static int durationStringToSeconds(String formatted) {
    if (formatted.isEmpty) return 0;
    final parts = formatted.split(':');
    final nums = parts.map(int.tryParse).toList();
    if (nums.any((n) => n == null)) return 0;
    if (nums.length == 3) return nums[0]! * 3600 + nums[1]! * 60 + nums[2]!;
    if (nums.length == 2) return nums[0]! * 60 + nums[1]!;
    return nums[0]!;
  }
}
