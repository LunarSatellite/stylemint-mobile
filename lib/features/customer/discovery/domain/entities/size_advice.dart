/// Return-derived fit advice for a product (`GET /v1/products/{id}/size-advice`).
///
/// [adviceKey] is `size_advice.runs_small` / `size_advice.runs_large`;
/// [basisKey] is `size_advice.basis.product` / `size_advice.basis.brand_category`.
/// Both are localization keys, resolved on the client.
class SizeAdvice {
  const SizeAdvice({
    required this.productId,
    required this.adviceKey,
    required this.basisKey,
  });

  final String productId;
  final String adviceKey;
  final String? basisKey;

  /// Parses the `{ "advice": ... }` envelope. Null when the server has no
  /// advice, or the body is not the expected shape.
  static SizeAdvice? fromEnvelope(Object? body) {
    if (body is! Map) return null;
    final advice = body['advice'];
    if (advice is! Map) return null;
    final key = advice['adviceKey'];
    if (key is! String || key.isEmpty) return null;
    final basis = advice['basisKey'];
    return SizeAdvice(
      productId: advice['productId']?.toString() ?? '',
      adviceKey: key,
      basisKey: basis is String && basis.isNotEmpty ? basis : null,
    );
  }
}
