import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stylemint_mobile_frontend/features/customer/mall_home/presentation/home_mode.dart';
import 'package:stylemint_mobile_frontend/features/customer/mall_home/presentation/screens/mall_home_page.dart';
import 'package:stylemint_mobile_frontend/features/customer/mall_home/presentation/widgets/home_mode_switch.dart';
import 'package:stylemint_mobile_frontend/features/customer/mall_home/shared/providers.dart';
import 'package:stylemint_mobile_frontend/features/customer/reels/presentation/screens/reels_feed_screen.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/mall/mall.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// The Home tab: the Mall (default) or the full-screen reels feed, chosen
/// with the "Mall | Reels" switch at the top.
///
/// The reels feed is built the first time Reels is chosen and then kept, so
/// its position and warm players survive switching back and forth. The
/// hidden view runs under `TickerMode(enabled: false)`: the reels pause
/// (ReelsPager and ReelPlayer both follow TickerMode, as they do for an
/// inactive tab) and the Mall hero stops auto-advancing.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _reelsBuilt = false;

  @override
  Widget build(BuildContext context) {
    final mode = ref.watch(homeModeProvider);
    final showReels = mode == HomeMode.reels;
    if (showReels) _reelsBuilt = true;

    return Scaffold(
      backgroundColor: DesignTokens.bgAppFoundation,
      body: Stack(
        fit: StackFit.expand,
        children: [
          IndexedStack(
            index: showReels ? 1 : 0,
            sizing: StackFit.expand,
            children: [
              TickerMode(enabled: !showReels, child: const MallHomePage()),
              TickerMode(
                enabled: showReels,
                child: _reelsBuilt
                    ? const ReelsFeedScreen()
                    : const SizedBox.shrink(),
              ),
            ],
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _HomeTopBar(
              mode: mode,
              onChanged: (value) =>
                  ref.read(homeModeProvider.notifier).state = value,
            ),
          ),
        ],
      ),
    );
  }
}

/// The switch, centred under the status bar. Over the Mall a soft fade keeps
/// scrolled content from running under it; over reels it floats on its own.
class _HomeTopBar extends StatelessWidget {
  const _HomeTopBar({required this.mode, required this.onChanged});

  final HomeMode mode;
  final ValueChanged<HomeMode> onChanged;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    return SizedBox(
      height: top + homeTopBarExtent,
      child: Stack(
        children: [
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedOpacity(
                opacity: mode == HomeMode.mall ? 1 : 0,
                duration: MallMetrics.reduceMotion(context)
                    ? Duration.zero
                    : DesignTokens.motionMedium,
                child: const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0xF209090B),
                        Color(0xB309090B),
                        Color(0x0009090B),
                      ],
                      stops: [0, 0.6, 1],
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: top + 6,
            left: 0,
            right: 0,
            child: Center(
              child: HomeModeSwitch(mode: mode, onChanged: onChanged),
            ),
          ),
        ],
      ),
    );
  }
}
