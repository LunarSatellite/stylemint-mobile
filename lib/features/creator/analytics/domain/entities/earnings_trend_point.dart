import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';

class EarningsTrendPoint {
  const EarningsTrendPoint({required this.date, required this.amount});

  final DateTime date;
  final Money amount;
}
