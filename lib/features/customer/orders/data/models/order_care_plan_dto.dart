import 'package:stylemint_mobile_frontend/features/customer/orders/domain/entities/order_care_plan.dart';

/// Wire shape of GET `/v1/orders/{orderNumber}/care` — backend
/// `OrderCarePlanDto { OrderNumber, GeneratedUtc, NextReturnDeadlineUtc?,
/// Items[] }` serialized camelCase. The backend registers no
/// `JsonStringEnumConverter`, so `stage` arrives as the `CareStage` int
/// (1..6); string names are accepted too in case that ever changes.
/// Missing or malformed fields degrade to safe defaults rather than failing
/// the whole plan.
class OrderCarePlanDto {
  const OrderCarePlanDto({
    required this.orderNumber,
    required this.items,
    this.generatedUtc,
    this.nextReturnDeadlineUtc,
  });

  factory OrderCarePlanDto.fromJson(Map<String, dynamic> json) =>
      OrderCarePlanDto(
        orderNumber: json['orderNumber']?.toString() ?? '',
        generatedUtc: _parseDate(json['generatedUtc']),
        nextReturnDeadlineUtc: _parseDate(json['nextReturnDeadlineUtc']),
        items: (json['items'] as List<dynamic>? ?? const <dynamic>[])
            .whereType<Map<String, dynamic>>()
            .map(CareItemDto.fromJson)
            .toList(growable: false),
      );

  final String orderNumber;
  final DateTime? generatedUtc;
  final DateTime? nextReturnDeadlineUtc;
  final List<CareItemDto> items;

  OrderCarePlan toDomain() => OrderCarePlan(
    orderNumber: orderNumber,
    generatedUtc: generatedUtc,
    nextReturnDeadlineUtc: nextReturnDeadlineUtc,
    items: items.map((i) => i.toDomain()).toList(growable: false),
  );
}

class CareItemDto {
  const CareItemDto({
    required this.subOrderId,
    required this.subOrderLineId,
    required this.productVariantId,
    required this.title,
    required this.stage,
    required this.actions,
    required this.guidance,
    this.variantLabel,
    this.thumbnailUrl,
    this.deliveredUtc,
    this.returnWindowClosesUtc,
    this.daysLeftToReturn,
    this.trackingNumber,
    this.warrantyEligible = false,
    this.hasOpenWarrantyClaim = false,
    this.warrantyCoverageDays,
    this.warrantyEndsUtc,
    this.warrantyTerms,
  });

  factory CareItemDto.fromJson(Map<String, dynamic> json) => CareItemDto(
    subOrderId: json['subOrderId']?.toString() ?? '',
    subOrderLineId: json['subOrderLineId']?.toString() ?? '',
    productVariantId: json['productVariantId']?.toString() ?? '',
    title: json['title']?.toString() ?? '',
    variantLabel: _nonEmpty(json['variantLabel']),
    thumbnailUrl: _nonEmpty(json['thumbnailUrl']),
    stage: parseCareStage(json['stage']),
    deliveredUtc: _parseDate(json['deliveredUtc']),
    returnWindowClosesUtc: _parseDate(json['returnWindowClosesUtc']),
    daysLeftToReturn: _parseInt(json['daysLeftToReturn']),
    trackingNumber: _nonEmpty(json['trackingNumber']),
    warrantyEligible: json['warrantyEligible'] == true,
    hasOpenWarrantyClaim: json['hasOpenWarrantyClaim'] == true,
    warrantyCoverageDays: _parseInt(json['warrantyCoverageDays']),
    warrantyEndsUtc: _parseDate(json['warrantyEndsUtc']),
    warrantyTerms: _nonEmpty(json['warrantyTerms']),
    actions: parseCareActions(json['actions']),
    guidance: json['guidance']?.toString() ?? '',
  );

  final String subOrderId;
  final String subOrderLineId;
  final String productVariantId;
  final String title;
  final String? variantLabel;
  final String? thumbnailUrl;
  final CareStage stage;
  final DateTime? deliveredUtc;
  final DateTime? returnWindowClosesUtc;
  final int? daysLeftToReturn;
  final String? trackingNumber;
  final bool warrantyEligible;
  final bool hasOpenWarrantyClaim;
  final int? warrantyCoverageDays;
  final DateTime? warrantyEndsUtc;
  final String? warrantyTerms;
  final List<CareAction> actions;
  final String guidance;

  CareItem toDomain() => CareItem(
    subOrderId: subOrderId,
    subOrderLineId: subOrderLineId,
    productVariantId: productVariantId,
    title: title,
    variantLabel: variantLabel,
    thumbnailUrl: thumbnailUrl,
    stage: stage,
    deliveredUtc: deliveredUtc,
    returnWindowClosesUtc: returnWindowClosesUtc,
    daysLeftToReturn: daysLeftToReturn,
    trackingNumber: trackingNumber,
    warrantyEligible: warrantyEligible,
    hasOpenWarrantyClaim: hasOpenWarrantyClaim,
    warrantyCoverageDays: warrantyCoverageDays,
    warrantyEndsUtc: warrantyEndsUtc,
    warrantyTerms: warrantyTerms,
    actions: actions,
    guidance: guidance,
  );
}

const _stagesByWireInt = <int, CareStage>{
  1: CareStage.inProgress,
  2: CareStage.returnWindowOpen,
  3: CareStage.returnWindowClosed,
  4: CareStage.returnInProgress,
  5: CareStage.returned,
  6: CareStage.cancelled,
};

const _stagesByWireName = <String, CareStage>{
  'inprogress': CareStage.inProgress,
  'returnwindowopen': CareStage.returnWindowOpen,
  'returnwindowclosed': CareStage.returnWindowClosed,
  'returninprogress': CareStage.returnInProgress,
  'returned': CareStage.returned,
  'cancelled': CareStage.cancelled,
  'canceled': CareStage.cancelled,
};

const _actionsByWireName = <String, CareAction>{
  'track': CareAction.track,
  'return': CareAction.returnItem,
  'review': CareAction.review,
  'reorder': CareAction.reorder,
  'gethelp': CareAction.getHelp,
  'warrantyclaim': CareAction.warrantyClaim,
  'warrantystatus': CareAction.warrantyStatus,
};

/// `CareStage` from its int value (`2`, `"2"`) or its name in any casing
/// (`"ReturnWindowOpen"`, `"returnWindowOpen"`, `"return_window_open"`).
/// Anything else maps to [CareStage.unknown].
CareStage parseCareStage(Object? raw) {
  if (raw is num) return _stagesByWireInt[raw.toInt()] ?? CareStage.unknown;
  if (raw is String) {
    final asInt = int.tryParse(raw.trim());
    if (asInt != null) return _stagesByWireInt[asInt] ?? CareStage.unknown;
    return _stagesByWireName[_normalize(raw)] ?? CareStage.unknown;
  }
  return CareStage.unknown;
}

/// Known actions in server order, de-duplicated; unknown values are dropped
/// so a newer backend action never breaks the card.
List<CareAction> parseCareActions(Object? raw) {
  if (raw is! List) return const <CareAction>[];
  final actions = <CareAction>[];
  for (final value in raw) {
    if (value is! String) continue;
    final action = _actionsByWireName[_normalize(value)];
    if (action != null && !actions.contains(action)) actions.add(action);
  }
  return List.unmodifiable(actions);
}

String _normalize(String value) =>
    value.trim().toLowerCase().replaceAll(RegExp('[_\\-\\s]'), '');

DateTime? _parseDate(Object? raw) =>
    raw is String ? DateTime.tryParse(raw) : null;

int? _parseInt(Object? raw) {
  if (raw is num) return raw.toInt();
  if (raw is String) return int.tryParse(raw.trim());
  return null;
}

String? _nonEmpty(Object? raw) {
  final value = raw?.toString().trim();
  return value == null || value.isEmpty ? null : value;
}
