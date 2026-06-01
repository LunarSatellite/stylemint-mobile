import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_sticky_bottom_bar.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

class _Slide {
  final String title;
  final String subtitle;
  final IconData icon;
  const _Slide(this.title, this.subtitle, this.icon);
}

/// Onboarding intro carousel — pixel-matched to Figma section `9365:10823`
/// (slides 9615:35799 / 36317 / 36782 / 37145).
///
/// Swipeable illustration + title (22px) + subtitle (14px) + 4-dot indicator,
/// with a sticky Next / Skip bottom bar. Last slide's primary action reads
/// "Get Started". Both Skip and finishing route to the home screen (reels feed).
class OnboardingCarouselScreen extends StatefulWidget {
  const OnboardingCarouselScreen({super.key});

  @override
  State<OnboardingCarouselScreen> createState() =>
      _OnboardingCarouselScreenState();
}

class _OnboardingCarouselScreenState extends State<OnboardingCarouselScreen> {
  final PageController _controller = PageController();
  int _page = 0;

  static const List<_Slide> _slides = [
    _Slide(
      'Your Favorite Creators Are the New Stylists.',
      "Discover trending fits, tips, and products directly from the people who know what's up",
      Icons.groups_rounded,
    ),
    _Slide(
      'Tap. Try. Buy. Just Like That With Vibe Try',
      'See a product in a reel? Tap it. Try it in AR. Cop it in seconds. No fluff, no fuss.',
      Icons.view_in_ar_rounded,
    ),
    _Slide(
      'Find Your Tribe, Make Your Squad, Share the Drip',
      'Start fashion challenges, shop in squads, and earn rewards together',
      Icons.diversity_3_rounded,
    ),
    _Slide(
      'Get Rewarded for Being Stylish.',
      'Earn points for engaging, shopping, and showing off your style',
      Icons.card_giftcard_rounded,
    ),
  ];

  bool get _isLast => _page == _slides.length - 1;

  void _finish() => context.go(RouteNames.home);

  void _next() {
    if (_isLast) {
      _finish();
    } else {
      _controller.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignTokens.bgAppFoundation,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _slides.length,
                onPageChanged: (i) => setState(() => _page = i),
                itemBuilder: (_, i) => _SlideView(slide: _slides[i]),
              ),
            ),
            // Page dots
            _Dots(count: _slides.length, active: _page),
            const SizedBox(height: DesignTokens.s24),
            // Sticky Next / Skip
            SmStickyBottomBar(
              primaryLabel: _isLast ? 'Get Started' : 'Next',
              onPrimary: _next,
              secondaryLabel: 'Skip',
              onSecondary: _finish,
            ),
          ],
        ),
      ),
    );
  }
}

class _SlideView extends StatelessWidget {
  final _Slide slide;
  const _SlideView({required this.slide});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: DesignTokens.s16),
      child: Column(
        children: [
          const SizedBox(height: DesignTokens.s24),
          // Illustration (placeholder — TODO: real Figma rafiki asset)
          Expanded(
            child: Center(
              child: Container(
                width: 240,
                height: 240,
                decoration: BoxDecoration(
                  color: DesignTokens.bgAppBodyLight,
                  borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
                ),
                child: Icon(slide.icon,
                    size: 120, color: DesignTokens.primaryGreen),
              ),
            ),
          ),
          const SizedBox(height: DesignTokens.s24),
          // Text block (gap 12)
          Column(
            children: [
              Text(slide.title,
                  textAlign: TextAlign.center, style: DesignTokens.titleMedium),
              const SizedBox(height: DesignTokens.s12),
              Text(
                slide.subtitle,
                textAlign: TextAlign.center,
                style: DesignTokens.mediumRegular
                    .copyWith(color: DesignTokens.textWhite),
              ),
            ],
          ),
          const SizedBox(height: DesignTokens.s24),
        ],
      ),
    );
  }
}

/// Page indicator: active = 16×8 green pill, inactive = 8×8 grey dot.
class _Dots extends StatelessWidget {
  final int count;
  final int active;
  const _Dots({required this.count, required this.active});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final isActive = i == active;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: const EdgeInsets.symmetric(horizontal: DesignTokens.s4),
          width: isActive ? 16 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: isActive
                ? DesignTokens.primaryGreen
                : DesignTokens.bgAppBodyLight,
            borderRadius: BorderRadius.circular(999),
          ),
        );
      }),
    );
  }
}
