class BestPostingWindow {
  const BestPostingWindow({
    this.dayOfWeekLabel,
    required this.startHourLocal,
    required this.endHourLocal,
    this.annotation,
  });

  final String? dayOfWeekLabel;
  final int startHourLocal;
  final int endHourLocal;
  final String? annotation;
}
