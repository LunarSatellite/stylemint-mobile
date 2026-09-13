import 'dart:ui';

/// Silhouette of `assets/branding/stylemint-mark.png`, traced from its alpha
/// channel with the gaps between the mark's shapes closed. Flat x, y pairs as
/// fractions of the square image, clockwise from the top.
const smBrandMarkOutline = <double>[
  0.4788, 0.0623, 0.5162, 0.0612, 0.5437, 0.0652, 0.5737, 0.0741,
  0.6188, 0.0970, 0.6637, 0.1338, 0.7370, 0.2213, 0.7652, 0.2448,
  0.7723, 0.2616, 0.8187, 0.2816, 0.8413, 0.2988, 0.8552, 0.3137,
  0.8677, 0.3337, 0.8752, 0.3538, 0.8780, 0.3713, 0.8752, 0.3937,
  0.8705, 0.4062, 0.8605, 0.4213, 0.8337, 0.4437, 0.8098, 0.4688,
  0.8063, 0.4788, 0.8066, 0.5038, 0.8116, 0.5116, 0.8588, 0.5427,
  0.8788, 0.5598, 0.9023, 0.5863, 0.9163, 0.6062, 0.9337, 0.6412,
  0.9423, 0.6687, 0.9463, 0.6913, 0.9463, 0.7262, 0.9423, 0.7488,
  0.9270, 0.7913, 0.9130, 0.8137, 0.8912, 0.8413, 0.8712, 0.8595,
  0.8363, 0.8823, 0.8063, 0.8959, 0.7688, 0.9070, 0.7388, 0.9113,
  0.6887, 0.9113, 0.6412, 0.9045, 0.5962, 0.8948, 0.5212, 0.8730,
  0.4913, 0.8712, 0.4562, 0.8759, 0.4213, 0.8827, 0.3513, 0.9023,
  0.2938, 0.9113, 0.2637, 0.9113, 0.2338, 0.9070, 0.2013, 0.8988,
  0.1638, 0.8830, 0.1437, 0.8705, 0.1163, 0.8488, 0.0980, 0.8287,
  0.0795, 0.8013, 0.0638, 0.7662, 0.0537, 0.7238, 0.0537, 0.6913,
  0.0577, 0.6687, 0.0730, 0.6238, 0.0912, 0.5913, 0.1113, 0.5663,
  0.1338, 0.5455, 0.1537, 0.5312, 0.1884, 0.5116, 0.1934, 0.5038,
  0.1938, 0.4813, 0.1902, 0.4713, 0.1688, 0.4487, 0.1391, 0.4238,
  0.1313, 0.4138, 0.1245, 0.3987, 0.1212, 0.3837, 0.1223, 0.3588,
  0.1363, 0.3262, 0.1512, 0.3063, 0.1737, 0.2870, 0.1988, 0.2730,
  0.2277, 0.2620, 0.2366, 0.2423, 0.2612, 0.2188, 0.3212, 0.1462,
  0.3613, 0.1102, 0.3912, 0.0905, 0.4213, 0.0762, 0.4487, 0.0673,
];

/// [smBrandMarkOutline] as a smooth closed path for an image drawn at [size].
Path smBrandMarkOutlinePath(Size size) {
  final points = <Offset>[
    for (var i = 0; i + 1 < smBrandMarkOutline.length; i += 2)
      Offset(
        smBrandMarkOutline[i] * size.width,
        smBrandMarkOutline[i + 1] * size.height,
      ),
  ];
  final count = points.length;
  final path = Path()..moveTo(points.first.dx, points.first.dy);
  // Catmull-Rom through the traced points, as cubic Béziers.
  for (var i = 0; i < count; i++) {
    final p0 = points[(i - 1 + count) % count];
    final p1 = points[i];
    final p2 = points[(i + 1) % count];
    final p3 = points[(i + 2) % count];
    final c1 = p1 + (p2 - p0) / 6;
    final c2 = p2 - (p3 - p1) / 6;
    path.cubicTo(c1.dx, c1.dy, c2.dx, c2.dy, p2.dx, p2.dy);
  }
  return path..close();
}
