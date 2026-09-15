import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/mall/mall.dart';

import 'mall_harness.dart';

void main() {
  group('MallCreatorCard', () {
    testMallLayouts('rail with a follow slot fits', (
      tester,
      width,
      scale,
    ) async {
      var railHeight = 0.0;
      await pumpMall(
        tester,
        Builder(
          builder: (context) {
            railHeight = MallCreatorCard.heightFor(context);
            return MallRail<MallCreatorVm>(
              items: const [verifiedCreator, untaggedCreator, verifiedCreator],
              itemWidth: MallCreatorCard.defaultWidth,
              height: railHeight,
              semanticLabel: 'Creators to follow',
              itemBuilder: (_, creator, _) => MallCreatorCard(
                creator: creator,
                onTap: () {},
                followAction: FilledButton(
                  onPressed: () {},
                  child: const Text('Follow'),
                ),
              ),
            );
          },
        ),
        width: width,
        textScale: scale,
      );
      expectNoLayoutErrors(tester);
      expect(
        tester.getSize(find.byType(MallCreatorCard).first).height,
        lessThanOrEqualTo(railHeight),
      );
    });

    testWidgets('semantics, verified tick, and separate follow action', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      var taps = 0;
      var follows = 0;
      await pumpMall(
        tester,
        Center(
          child: SizedBox(
            width: MallCreatorCard.defaultWidth,
            child: MallCreatorCard(
              creator: verifiedCreator,
              onTap: () => taps++,
              followAction: FilledButton(
                onPressed: () => follows++,
                child: const Text('Follow'),
              ),
            ),
          ),
        ),
      );
      expect(find.byType(MallVerifiedBadge), findsOneWidget);
      expect(find.text('Streetwear · Minimal · Y2K revival'), findsOneWidget);
      expect(find.text('128K followers'), findsOneWidget);
      expect(
        find.bySemanticsLabel(
          'Priya Shrestha, Verified, Streetwear · Minimal · Y2K revival, '
          '128K followers',
        ),
        findsOneWidget,
      );
      await tester.tap(find.text('Follow'));
      expect(follows, 1);
      expect(taps, 0);
      await tester.tap(find.byType(MallTapOverlay));
      expect(taps, 1);
      await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      semantics.dispose();
    });

    testWidgets('falls back to the handle when there are no style tags', (
      tester,
    ) async {
      await pumpMall(
        tester,
        const Center(
          child: SizedBox(
            width: MallCreatorCard.defaultWidth,
            child: MallCreatorCard(creator: untaggedCreator),
          ),
        ),
      );
      expect(find.text('@aarav.k'), findsOneWidget);
      expect(find.byType(MallVerifiedBadge), findsNothing);
    });
  });

  group('MallBrandCard', () {
    testMallLayouts('rail fits', (tester, width, scale) async {
      var railHeight = 0.0;
      await pumpMall(
        tester,
        Builder(
          builder: (context) {
            railHeight = MallBrandCard.heightFor(
              context,
              width: MallBrandCard.defaultWidth,
            );
            return MallRail<MallBrandVm>(
              items: const [
                verifiedBrand,
                MallBrandVm(id: 'b-2', name: 'Plain label'),
              ],
              itemWidth: MallBrandCard.defaultWidth,
              height: railHeight,
              semanticLabel: 'Verified brands',
              itemBuilder: (_, brand, _) =>
                  MallBrandCard(brand: brand, onTap: () {}),
            );
          },
        ),
        width: width,
        textScale: scale,
      );
      expectNoLayoutErrors(tester);
      expect(
        tester.getSize(find.byType(MallBrandCard).first).height,
        lessThanOrEqualTo(railHeight),
      );
    });

    testWidgets('semantics and tap', (tester) async {
      final semantics = tester.ensureSemantics();
      var taps = 0;
      await pumpMall(
        tester,
        Center(
          child: SizedBox(
            width: MallBrandCard.defaultWidth,
            child: MallBrandCard(brand: verifiedBrand, onTap: () => taps++),
          ),
        ),
      );
      expect(find.byType(MallVerifiedBadge), findsOneWidget);
      expect(
        find.bySemanticsLabel(
          'Kathmandu Atelier, Verified, '
          'Hand-loomed Himalayan textiles, cut for the city.',
        ),
        findsOneWidget,
      );
      await tester.tap(find.byType(MallBrandCard));
      expect(taps, 1);
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      semantics.dispose();
    });
  });
}
