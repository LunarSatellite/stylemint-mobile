import 'package:flutter/material.dart';

/// Grants the screen's single reel play slot to the most visible reel tile.
///
/// The rule is a platform one, not a preference: YouTube's Required Minimum
/// Functionality allows one autoplaying player per screen and only while it
/// is more than half visible, and the test phone (Realme RMX3939, Unisoc,
/// 3.8 GB RAM) has room for about two WebView-backed players in total. So at
/// most one tile ever holds the slot, and it is the one the viewer is
/// actually looking at.
///
/// Nothing plays inline in the Mall today — Mall tiles are posters that open
/// the reel on tap. The slot still decides which single tile is "the one on
/// screen", which is what its play affordance reflects, and it is the seam
/// an inline player would plug into without any tile changing.
///
/// A tile that reports under [minVisibleFraction] can never hold the slot,
/// and a tile whose `MediaQuery.disableAnimations` is set reports nothing at
/// all, so reduced motion means no tile is ever granted one.
class MallReelPlaySlotController extends ChangeNotifier {
  /// The app-wide slot. One screen shows reels at a time, and tiles release
  /// the slot as they leave the tree, so a single instance is enough — and
  /// it is what guarantees two screens can never both hold one.
  static final MallReelPlaySlotController instance =
      MallReelPlaySlotController();

  /// A tile must be more than half on screen to be granted the slot.
  static const double minVisibleFraction = 0.5;

  /// How much more visible a challenger must be before it takes the slot
  /// from the current holder. Without it, two tiles a pixel apart would
  /// swap the slot on every scroll tick.
  static const double _handoverMargin = 0.08;

  final Map<String, double> _visible = {};
  String? _holder;

  /// The tile holding the play slot, or null when no tile qualifies.
  String? get holder => _holder;

  bool holds(String id) => _holder != null && _holder == id;

  /// How visible [id] last reported itself to be, 0 when it is not tracked.
  @visibleForTesting
  double visibleFractionOf(String id) => _visible[id] ?? 0;

  void report({required String id, required double fraction}) {
    final clamped = fraction.isFinite ? fraction.clamp(0.0, 1.0) : 0.0;
    if (_visible[id] == clamped) return;
    _visible[id] = clamped;
    _settle();
  }

  /// Called when a tile leaves the tree.
  void release(String id) {
    if (_visible.remove(id) == null) return;
    _settle();
  }

  void _settle() {
    String? best;
    var bestFraction = 0.0;
    for (final MapEntry(:key, :value) in _visible.entries) {
      if (value > bestFraction) {
        best = key;
        bestFraction = value;
      }
    }
    final holderFraction = _holder == null ? 0.0 : _visible[_holder] ?? 0.0;
    final next = switch (best) {
      null => null,
      _ when bestFraction < minVisibleFraction => null,
      // The holder keeps the slot until something is clearly more visible.
      _
          when _holder != null &&
              holderFraction >= minVisibleFraction &&
              bestFraction - holderFraction < _handoverMargin =>
        _holder,
      final winner => winner,
    };
    if (next == _holder) return;
    _holder = next;
    notifyListeners();
  }

  /// Forgets every tile. For tests, which share [instance].
  @visibleForTesting
  void reset() {
    _visible.clear();
    if (_holder == null) return;
    _holder = null;
    notifyListeners();
  }
}

/// Builds a tile that knows whether it holds the screen's single play slot.
typedef MallReelPlaySlotBuilder =
    Widget Function(BuildContext context, {required bool holdsSlot});

/// Reports how visible it is to a [MallReelPlaySlotController] and rebuilds
/// its builder with whether it holds the screen's single play slot.
///
/// Visibility is measured against the screen after each scroll of the
/// enclosing scrollable, so no visibility package and no host widget above
/// the page are needed.
class MallReelPlaySlot extends StatefulWidget {
  const MallReelPlaySlot({
    required this.id,
    required this.builder,
    super.key,
    this.controller,
  });

  /// Identifies the reel. Two tiles showing the same reel report as one.
  final String id;

  final MallReelPlaySlotBuilder builder;

  /// Defaults to [MallReelPlaySlotController.instance].
  final MallReelPlaySlotController? controller;

  @override
  State<MallReelPlaySlot> createState() => _MallReelPlaySlotState();
}

class _MallReelPlaySlotState extends State<MallReelPlaySlot> {
  ScrollPosition? _position;
  bool _scheduled = false;

  MallReelPlaySlotController get _controller =>
      widget.controller ?? MallReelPlaySlotController.instance;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onSlotChanged);
    _scheduleMeasure();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final position = Scrollable.maybeOf(context)?.position;
    if (!identical(position, _position)) {
      _position?.removeListener(_scheduleMeasure);
      _position = position?..addListener(_scheduleMeasure);
    }
    _scheduleMeasure();
  }

  @override
  void didUpdateWidget(MallReelPlaySlot oldWidget) {
    super.didUpdateWidget(oldWidget);
    final changed =
        oldWidget.id != widget.id ||
        oldWidget.controller != widget.controller;
    if (changed) {
      oldWidget.controller?.removeListener(_onSlotChanged);
      (oldWidget.controller ?? MallReelPlaySlotController.instance)
          .release(oldWidget.id);
      _controller.addListener(_onSlotChanged);
      _scheduleMeasure();
    }
  }

  @override
  void dispose() {
    _position?.removeListener(_scheduleMeasure);
    _controller
      ..removeListener(_onSlotChanged)
      ..release(widget.id);
    super.dispose();
  }

  void _onSlotChanged() {
    if (mounted) setState(() {});
  }

  /// Measures once per frame at most: a fling fires many scroll ticks and
  /// the answer cannot change more often than the layout does.
  void _scheduleMeasure() {
    if (_scheduled || !mounted) return;
    _scheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scheduled = false;
      _measure();
    });
  }

  void _measure() {
    if (!mounted) return;
    // Reduced motion: nothing may play, so nothing is ever granted the slot.
    if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) {
      _controller.release(widget.id);
      return;
    }
    final box = context.findRenderObject();
    if (box is! RenderBox || !box.hasSize) return;
    _controller.report(
      id: widget.id,
      fraction: _visibleFraction(box, MediaQuery.sizeOf(context)),
    );
  }

  /// The share of the tile inside the screen. Ancestor clipping (a rail's
  /// own viewport) is not modelled: a tile clipped out of a rail is also
  /// scrolled off the screen edge in practice, and over-reporting can only
  /// make a tile the holder — never make two tiles hold the slot.
  static double _visibleFraction(RenderBox box, Size screen) {
    final size = box.size;
    final area = size.width * size.height;
    if (area <= 0) return 0;
    final rect = box.localToGlobal(Offset.zero) & size;
    final visible = rect.intersect(Offset.zero & screen);
    if (visible.width <= 0 || visible.height <= 0) return 0;
    return (visible.width * visible.height) / area;
  }

  @override
  Widget build(BuildContext context) {
    _scheduleMeasure();
    return widget.builder(
      context,
      holdsSlot: _controller.holds(widget.id),
    );
  }
}
