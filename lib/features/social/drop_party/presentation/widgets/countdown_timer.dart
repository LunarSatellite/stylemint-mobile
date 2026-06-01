import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

class CountdownTimer extends StatefulWidget {
  const CountdownTimer({
    super.key,
    required this.startsAt,
    required this.endsAt,
  });

  final DateTime startsAt;
  final DateTime endsAt;

  @override
  State<CountdownTimer> createState() => _CountdownTimerState();
}

class _CountdownTimerState extends State<CountdownTimer>
    with SingleTickerProviderStateMixin {
  late DateTime _target;
  Duration _remaining = Duration.zero;
  late final Ticker _ticker;

  @override
  void initState() {
    super.initState();
    _target = widget.startsAt.isAfter(DateTime.now())
        ? widget.startsAt
        : widget.endsAt;
    _ticker = createTicker(_onTick)..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  void _onTick(Duration elapsed) {
    final now = DateTime.now();
    final remaining = _target.difference(now);
    if (remaining.isNegative) {
      _ticker.stop();
      setState(() => _remaining = Duration.zero);
      return;
    }
    setState(() => _remaining = remaining);
  }

  @override
  Widget build(BuildContext context) {
    if (_remaining == Duration.zero) {
      return const Text('Ended',
          style: TextStyle(
              fontFamily: DesignTokens.fontFamily,
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: DesignTokens.colorError));
    }

    final days = _remaining.inDays;
    final hours = _remaining.inHours.remainder(24);
    final minutes = _remaining.inMinutes.remainder(60);
    final seconds = _remaining.inSeconds.remainder(60);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (days > 0) ...[
          _buildUnit(days, 'D'),
          _buildSeparator(),
        ],
        _buildUnit(hours, 'H'),
        _buildSeparator(),
        _buildUnit(minutes, 'M'),
        _buildSeparator(),
        _buildUnit(seconds, 'S'),
      ],
    );
  }

  Widget _buildUnit(int value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: DesignTokens.s8, vertical: DesignTokens.s4),
      decoration: BoxDecoration(
        color: DesignTokens.primaryGreenDark,
        borderRadius: BorderRadius.circular(DesignTokens.inputRadius),
        border: Border.all(
            color: DesignTokens.primaryGreen.withOpacity(0.5), width: 1),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('${value.toString().padLeft(2, '0')}',
              style: DesignTokens.titleMedium.copyWith(
                  color: DesignTokens.primaryGreen)),
          Text(label, style: DesignTokens.tiny),
        ],
      ),
    );
  }

  Widget _buildSeparator() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 4),
      child: Text(':', style: DesignTokens.titleLarge),
    );
  }
}
