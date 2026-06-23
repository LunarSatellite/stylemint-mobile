import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

// ─── Args ─────────────────────────────────────────────────────────────────────

class AdjustCommissionArgs {
  const AdjustCommissionArgs({
    required this.creatorName,
    required this.handle,
    required this.followersLabel,
    required this.currentCommission,
    this.avatarAsset = '',
  });

  final String creatorName;
  final String handle;
  final String followersLabel;
  final int currentCommission;
  final String avatarAsset;
}

// ─── Screen ───────────────────────────────────────────────────────────────────

class AdjustCommissionScreen extends StatefulWidget {
  const AdjustCommissionScreen({super.key, required this.args});

  final AdjustCommissionArgs args;

  @override
  State<AdjustCommissionScreen> createState() =>
      _AdjustCommissionScreenState();
}

class _AdjustCommissionScreenState extends State<AdjustCommissionScreen> {
  late double _rate;
  bool _notifyCreator = false;
  final _dateCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _rate = widget.args.currentCommission.toDouble();
  }

  @override
  void dispose() {
    _dateCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: DesignTokens.primaryGreen,
            surface: DesignTokens.bgAppBodyLight,
            onSurface: DesignTokens.textWhite,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null && mounted) {
      setState(() {
        _dateCtrl.text =
            '${picked.month.toString().padLeft(2, '0')}/${picked.day.toString().padLeft(2, '0')}/${picked.year}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignTokens.bgAppFoundation,
      appBar: AppBar(
        backgroundColor: DesignTokens.bgAppFoundation,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: DesignTokens.textWhite,
            size: 20,
          ),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Adjust Commission',
          style: TextStyle(
            fontFamily: DesignTokens.fontFamily,
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: DesignTokens.textWhite,
          ),
        ),
        actions: [
          _DarkIconButton(
            assetPath: 'assets/images/money-bag-rounded.png',
            onTap: () {},
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(DesignTokens.s16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _CreatorCard(args: widget.args),
                  const SizedBox(height: DesignTokens.s16),
                  _SliderCard(
                    rate: _rate,
                    onChanged: (v) => setState(() => _rate = v),
                  ),
                  const SizedBox(height: DesignTokens.s16),
                  _DateField(
                    controller: _dateCtrl,
                    onTap: _pickDate,
                  ),
                  const SizedBox(height: DesignTokens.s16),
                  _NotifyCard(
                    value: _notifyCreator,
                    onChanged: (v) => setState(() => _notifyCreator = v),
                  ),
                ],
              ),
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                  DesignTokens.s16, 12, DesignTokens.s16, 16),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Commission rate updated!'),
                        behavior: SnackBarBehavior.floating,
                        backgroundColor: DesignTokens.primaryGreen,
                      ),
                    );
                    context.pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: DesignTokens.primaryGreen,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(100),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Update Commission Rate',
                    style: TextStyle(
                      fontFamily: DesignTokens.fontFamily,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Dark icon button (AppBar action) ────────────────────────────────────────

class _DarkIconButton extends StatelessWidget {
  const _DarkIconButton({this.icon, this.assetPath, required this.onTap});

  final IconData? icon;
  final String? assetPath;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: const Color(0xFF27272A),
          borderRadius: BorderRadius.circular(10),
        ),
        padding: assetPath != null ? const EdgeInsets.all(8) : EdgeInsets.zero,
        child: assetPath != null
            ? Image.asset(
                assetPath!,
                fit: BoxFit.contain,
                color: DesignTokens.textWhite,
                colorBlendMode: BlendMode.srcIn,
                errorBuilder: (_, __, ___) =>
                    const Icon(Icons.monetization_on_outlined,
                        color: DesignTokens.textWhite, size: 20),
              )
            : Icon(icon, color: DesignTokens.textWhite, size: 20),
      ),
    );
  }
}

// ─── Creator card ─────────────────────────────────────────────────────────────

class _CreatorCard extends StatelessWidget {
  const _CreatorCard({required this.args});

  final AdjustCommissionArgs args;

  @override
  Widget build(BuildContext context) {
    final hasAsset = args.avatarAsset.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(DesignTokens.s16),
      decoration: BoxDecoration(
        color: DesignTokens.bgAppBodyLight,
        borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ClipOval(
            child: hasAsset
                ? Image.asset(
                    args.avatarAsset,
                    width: 48,
                    height: 48,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _InitialAvatar(
                        name: args.creatorName, size: 48),
                  )
                : _InitialAvatar(name: args.creatorName, size: 48),
          ),
          const SizedBox(width: DesignTokens.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  args.creatorName,
                  style: const TextStyle(
                    fontFamily: DesignTokens.fontFamily,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: DesignTokens.textWhite,
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    const Icon(
                      Icons.person_outline_rounded,
                      size: 12,
                      color: DesignTokens.textMuted,
                    ),
                    const SizedBox(width: 3),
                    Flexible(
                      child: Text(
                        '${args.followersLabel} Followers · ${args.handle}',
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: DesignTokens.fontFamily,
                          fontSize: 12,
                          color: DesignTokens.textMuted,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: DesignTokens.s8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: DesignTokens.primaryGreen.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Current Commission: ${args.currentCommission}%',
                    style: const TextStyle(
                      fontFamily: DesignTokens.fontFamily,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: DesignTokens.primaryGreen,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Slider card ──────────────────────────────────────────────────────────────

class _SliderCard extends StatelessWidget {
  const _SliderCard({required this.rate, required this.onChanged});

  final double rate;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
          DesignTokens.s16, DesignTokens.s16, DesignTokens.s16, 12),
      decoration: BoxDecoration(
        color: DesignTokens.bgAppBodyLight,
        borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'New Commission Rate: ${rate.round()}%',
            style: const TextStyle(
              fontFamily: DesignTokens.fontFamily,
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: DesignTokens.textWhite,
            ),
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: DesignTokens.primaryGreen,
              inactiveTrackColor: DesignTokens.borderDefault,
              overlayColor: DesignTokens.primaryGreen.withOpacity(0.1),
              trackHeight: 4,
              thumbShape: const _GreenThumb(),
            ),
            child: Slider(
              value: rate,
              min: 5,
              max: 25,
              divisions: 20,
              onChanged: onChanged,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text(
                  '5%',
                  style: TextStyle(
                    fontFamily: DesignTokens.fontFamily,
                    fontSize: 12,
                    color: DesignTokens.textMuted,
                  ),
                ),
                Text(
                  '25%',
                  style: TextStyle(
                    fontFamily: DesignTokens.fontFamily,
                    fontSize: 12,
                    color: DesignTokens.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Custom slider thumb ──────────────────────────────────────────────────────

class _GreenThumb extends SliderComponentShape {
  const _GreenThumb();

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) =>
      const Size(20, 20);

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    required bool isDiscrete,
    required TextPainter labelPainter,
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required TextDirection textDirection,
    required double value,
    required double textScaleFactor,
    required Size sizeWithOverflow,
  }) {
    final canvas = context.canvas;
    canvas.drawCircle(center, 10, Paint()..color = Colors.white);
    canvas.drawCircle(center, 6.7, Paint()..color = DesignTokens.primaryGreen);
  }
}

// ─── Effective date field ─────────────────────────────────────────────────────

class _DateField extends StatelessWidget {
  const _DateField({required this.controller, required this.onTap});

  final TextEditingController controller;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: DesignTokens.s16, vertical: 16),
        decoration: BoxDecoration(
          color: DesignTokens.bgAppBodyLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: DesignTokens.borderDefault),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                controller.text.isEmpty ? 'Effective Date' : controller.text,
                style: TextStyle(
                  fontFamily: DesignTokens.fontFamily,
                  fontSize: 14,
                  color: controller.text.isEmpty
                      ? DesignTokens.textMuted
                      : DesignTokens.textWhite,
                ),
              ),
            ),
            const Icon(
              Icons.calendar_month_outlined,
              color: DesignTokens.textMuted,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Notify creator card ──────────────────────────────────────────────────────

class _NotifyCard extends StatelessWidget {
  const _NotifyCard({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(DesignTokens.s16),
      decoration: BoxDecoration(
        color: DesignTokens.bgAppBodyLight,
        borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 24,
            height: 24,
            child: Checkbox(
              value: value,
              onChanged: (v) => onChanged(v ?? false),
              activeColor: DesignTokens.primaryGreen,
              checkColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
              side: const BorderSide(
                  color: DesignTokens.borderDefault, width: 1.5),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
          const SizedBox(width: DesignTokens.s12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Notify Creator',
                  style: TextStyle(
                    fontFamily: DesignTokens.fontFamily,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: DesignTokens.textWhite,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Notify the creator about the change in commission rates',
                  style: TextStyle(
                    fontFamily: DesignTokens.fontFamily,
                    fontSize: 12,
                    color: DesignTokens.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Initial avatar helper ────────────────────────────────────────────────────

class _InitialAvatar extends StatelessWidget {
  const _InitialAvatar({required this.name, required this.size});

  final String name;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      color: DesignTokens.bgAppFoundation,
      alignment: Alignment.center,
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : '?',
        style: TextStyle(
          fontFamily: DesignTokens.fontFamily,
          fontSize: size * 0.38,
          fontWeight: FontWeight.w600,
          color: DesignTokens.textWhite,
        ),
      ),
    );
  }
}
