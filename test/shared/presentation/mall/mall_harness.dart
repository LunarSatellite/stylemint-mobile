import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/mall/mall.dart';
import 'package:stylemint_mobile_frontend/theme/app_theme.dart';

/// Phone (small, standard) and tablet logical widths every kit component is
/// laid out at.
const List<double> mallTestWidths = [320, 390, 768];

/// Default and enlarged accessibility text scales.
const List<double> mallTestTextScales = [1, 1.3];

double _screenHeightFor(double width) {
  if (width <= 320) return 568;
  if (width < 600) return 844;
  return 1024;
}

/// Pumps [child] in the dark app theme on a [width]-wide screen with the given
/// text scale, motion preference and text direction. By default the child sits
/// in a vertical ListView, like a Mall page section.
Future<void> pumpMall(
  WidgetTester tester,
  Widget child, {
  double width = 390,
  double textScale = 1,
  bool disableAnimations = false,
  TextDirection textDirection = TextDirection.ltr,
  bool inList = true,
}) async {
  tester.view
    ..physicalSize = Size(width, _screenHeightFor(width))
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      builder: (context, app) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(textScale),
          disableAnimations: disableAnimations,
        ),
        child: Directionality(
          textDirection: textDirection,
          child: app ?? const SizedBox.shrink(),
        ),
      ),
      home: Scaffold(body: inList ? ListView(children: [child]) : child),
    ),
  );
  await tester.pump();
}

/// Registers one widget test per width in [mallTestWidths] × text scale in
/// [mallTestTextScales].
void testMallLayouts(
  String description,
  Future<void> Function(WidgetTester tester, double width, double textScale)
  body,
) {
  for (final width in mallTestWidths) {
    for (final scale in mallTestTextScales) {
      testWidgets(
        '$description — ${width.toInt()}dp, text ×$scale',
        (tester) => body(tester, width, scale),
      );
    }
  }
}

/// Fails if layout reported an exception such as a RenderFlex overflow.
void expectNoLayoutErrors(WidgetTester tester) =>
    expect(tester.takeException(), isNull);

// ── Fixtures ────────────────────────────────────────────────────────────────

const String npr = 'NPR';

const String longProductName =
    'Oversized linen co-ord set in washed sand with contrast stitching';

const MallProductVm saleProduct = MallProductVm(
  id: 'p-sale',
  brandName: 'Kathmandu Atelier',
  name: longProductName,
  price: Money(amount: 3499, currency: npr),
  compareAtPrice: Money(amount: 4999, currency: npr),
  rating: 4.6,
  isNew: true,
  isLowStock: true,
);

const MallProductVm plainProduct = MallProductVm(
  id: 'p-plain',
  name: 'Canvas tote',
  price: Money(amount: 1800, currency: npr),
);

const MallReelVm aiReel = MallReelVm(
  id: 'r-ai',
  creatorName: 'Priya Styles With A Long Display Name',
  caption: 'Weekend edit',
  taggedProductCount: 3,
  isAiGenerated: true,
  likeCount: 12400,
);

const MallReelVm humanReel = MallReelVm(
  id: 'r-human',
  creatorName: 'Aarav',
  taggedProductCount: 1,
  likeCount: 1,
);

const MallCreatorVm verifiedCreator = MallCreatorVm(
  id: 'c-1',
  name: 'Priya Shrestha',
  handle: 'priya.styles',
  isVerified: true,
  styleTags: ['Streetwear', 'Minimal', 'Y2K revival'],
  followerCount: 128400,
);

const MallCreatorVm untaggedCreator = MallCreatorVm(
  id: 'c-2',
  name: 'Aarav Karki',
  handle: 'aarav.k',
);

const MallBrandVm verifiedBrand = MallBrandVm(
  id: 'b-1',
  name: 'Kathmandu Atelier',
  isVerified: true,
  tagline: 'Hand-loomed Himalayan textiles, cut for the city.',
);

const MallCategoryVm sneakers = MallCategoryVm(
  id: 'cat-1',
  label: 'Sneakers & streetwear',
);

const MallCollectionVm monsoonEdit = MallCollectionVm(
  id: 'col-1',
  eyebrow: 'Edit',
  title: 'Monsoon layers for city days',
  itemCount: 24,
);

const MallCampaignVm monsoonCampaign = MallCampaignVm(
  id: 'k-1',
  eyebrow: 'The monsoon edit',
  title: 'Layers that move with the city',
  subtitle: 'New-season outerwear from verified Kathmandu labels.',
  actions: [
    MallCampaignAction(id: 'shop', label: 'Shop the edit'),
    MallCampaignAction(id: 'reels', label: 'Watch reels'),
    MallCampaignAction(id: 'makers', label: 'Meet the makers'),
  ],
);

const List<MallCampaignVm> heroCampaigns = [
  monsoonCampaign,
  MallCampaignVm(
    id: 'k-2',
    title: 'Second campaign',
    actions: [MallCampaignAction(id: 'go', label: 'Explore')],
  ),
  MallCampaignVm(id: 'k-3', title: 'Third campaign'),
];
