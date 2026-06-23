import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

class OrderSuccessScreen extends StatefulWidget {
  const OrderSuccessScreen({super.key, required this.orderId});

  final String orderId;

  @override
  State<OrderSuccessScreen> createState() => _OrderSuccessScreenState();
}

class _OrderSuccessScreenState extends State<OrderSuccessScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final List<_Piece> _pieces;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat();
    _pieces = List.generate(64, _Piece.new);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF09090B),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 300,
                    height: 300,
                    child: AnimatedBuilder(
                      animation: _controller,
                      builder: (_, __) => CustomPaint(
                        painter: _ConfettiPainter(
                          pieces: _pieces,
                          t: _controller.value,
                        ),
                        child: const _Circles(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 36),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      'Thank you! Your purchase was\nsuccessful.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: DesignTokens.fontFamily,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        height: 1.35,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 40),
                    child: Text(
                      'You can track your order from the Order History section to see real-time updates and know exactly when it will be delivered.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: DesignTokens.fontFamily,
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFF9CA3AF),
                        height: 1.55,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              decoration: const BoxDecoration(
                color: Color(0xFF09090B),
                border: Border(top: BorderSide(color: Color(0xFF27272A))),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: DesignTokens.primaryGreen,
                        foregroundColor: const Color(0xFF06190E),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(26),
                        ),
                      ),
                      onPressed: () => context.pushReplacement(
                        RouteNames.orderDetail
                            .replaceAll(':orderId', widget.orderId),
                      ),
                      child: const Text(
                        'View Order',
                        style: TextStyle(
                          fontFamily: DesignTokens.fontFamily,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF27272A),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(26),
                        ),
                      ),
                      onPressed: () => context.go(RouteNames.home),
                      child: const Text(
                        'Go To Home',
                        style: TextStyle(
                          fontFamily: DesignTokens.fontFamily,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── CONCENTRIC CIRCLES ───────────────────────────────────────────────────────
class _Circles extends StatelessWidget {
  const _Circles();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 240,
        height: 240,
        decoration: const BoxDecoration(
          color: Color(0xFF14271A),
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: Container(
          width: 184,
          height: 184,
          decoration: const BoxDecoration(
            color: Color(0xFF1D4A2A),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Container(
            width: 128,
            height: 128,
            decoration: const BoxDecoration(
              color: DesignTokens.primaryGreen,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.check_rounded,
              color: Colors.white,
              size: 64,
            ),
          ),
        ),
      ),
    );
  }
}

// ─── CONFETTI ─────────────────────────────────────────────────────────────────
class _Piece {
  _Piece(int seed) {
    final rng = math.Random(seed * 17 + 3);
    angle = rng.nextDouble() * math.pi * 2;
    radius = 90 + rng.nextDouble() * 70;
    size = 5 + rng.nextDouble() * 9;
    colorIndex = rng.nextInt(_colors.length);
    phaseOffset = rng.nextDouble();
    isRect = rng.nextBool();
    spin = rng.nextDouble() * math.pi;
  }

  late final double angle;
  late final double radius;
  late final double size;
  late final int colorIndex;
  late final double phaseOffset;
  late final bool isRect;
  late final double spin;

  static const _colors = [
    Color(0xFFFF6B6B),
    Color(0xFF4ECDC4),
    Color(0xFFFFE66D),
    Color(0xFFA29BFE),
    Color(0xFF55EFC4),
    Color(0xFFFF7675),
    Color(0xFF74B9FF),
    Color(0xFFFD79A8),
    Color(0xFF00B894),
    Color(0xFFFFB347),
  ];

  Color get color => _colors[colorIndex];
}

class _ConfettiPainter extends CustomPainter {
  const _ConfettiPainter({required this.pieces, required this.t});

  final List<_Piece> pieces;
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    for (final p in pieces) {
      final phase = (t + p.phaseOffset) % 1.0;
      final r = p.radius * (0.88 + 0.12 * math.sin(phase * math.pi * 2));
      final a = p.angle + phase * 0.6;
      final x = cx + math.cos(a) * r;
      final y = cy + math.sin(a) * r;
      final opacity = 0.65 + 0.35 * math.sin(phase * math.pi * 2);

      final paint = Paint()
        ..color = p.color.withOpacity(opacity)
        ..style = PaintingStyle.fill;

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(p.spin + phase * math.pi * 2);

      if (p.isRect) {
        canvas.drawRect(
          Rect.fromCenter(
              center: Offset.zero, width: p.size, height: p.size * 0.45),
          paint,
        );
      } else {
        canvas.drawOval(
          Rect.fromCenter(
              center: Offset.zero, width: p.size, height: p.size * 0.55),
          paint,
        );
      }

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => old.t != t;
}
