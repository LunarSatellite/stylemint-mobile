/// How long ago a story went up, Instagram-short: "now", "12m", "3h".
///
/// Stories live 24 hours, so days never come up in practice; anything older
/// still reads sensibly ("2d").
String storyAge(DateTime postedAt, {DateTime? now}) {
  final diff = (now ?? DateTime.now()).toUtc().difference(postedAt.toUtc());
  if (diff.inMinutes < 1) return 'now';
  if (diff.inHours < 1) return '${diff.inMinutes}m';
  if (diff.inDays < 1) return '${diff.inHours}h';
  return '${diff.inDays}d';
}
