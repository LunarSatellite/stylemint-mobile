/// Short relative age for feed surfaces, Instagram-style: "now", "5m", "2h",
/// "3d", "2w", then a plain date once a post is older than a month.
String feedTimeAgo(DateTime dateTime, {DateTime? now}) {
  final diff = (now ?? DateTime.now()).difference(dateTime);
  if (diff.inMinutes < 1) return 'now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m';
  if (diff.inHours < 24) return '${diff.inHours}h';
  if (diff.inDays < 7) return '${diff.inDays}d';
  if (diff.inDays < 31) return '${diff.inDays ~/ 7}w';
  return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
}

/// Like/comment counts: "987", "1,234", then "12.3K" and "4.5M" once the exact
/// number stops being readable at a glance.
String feedCount(int count) {
  if (count >= 1000000) return '${_trim(count / 1000000)}M';
  if (count >= 10000) return '${_trim(count / 1000)}K';
  final digits = count.toString();
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buffer.write(',');
    buffer.write(digits[i]);
  }
  return buffer.toString();
}

String _trim(double value) {
  final fixed = value.toStringAsFixed(1);
  return fixed.endsWith('.0') ? fixed.substring(0, fixed.length - 2) : fixed;
}
