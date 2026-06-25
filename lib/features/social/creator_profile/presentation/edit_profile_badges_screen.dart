import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

class EditProfileBadgesScreen extends StatefulWidget {
  const EditProfileBadgesScreen({super.key});

  @override
  State<EditProfileBadgesScreen> createState() =>
      _EditProfileBadgesScreenState();
}

class _EditProfileBadgesScreenState extends State<EditProfileBadgesScreen> {
  static const int _maxSelection = 4;

  static const List<_BadgeItem> _badges = [
    _BadgeItem(
      asset: 'assets/images/profile_badges/diamond_badge.png',
      label: 'Diamond',
    ),
    _BadgeItem(
      asset: 'assets/images/profile_badges/red_badge.png',
      label: 'Ruby',
    ),
    _BadgeItem(
      asset: 'assets/images/profile_badges/golden_badge.png',
      label: 'Gold',
    ),
    _BadgeItem(
      asset: 'assets/images/profile_badges/silver_badge.png',
      label: 'Silver',
    ),
    _BadgeItem(
      asset: 'assets/images/profile_badges/badge_5.png',
      label: 'Crystal',
    ),
    _BadgeItem(
      asset: 'assets/images/profile_badges/badge_6.png',
      label: 'Amethyst',
    ),
    _BadgeItem(
      asset: 'assets/images/profile_badges/badge_7.png',
      label: 'Champion',
    ),
  ];

  final Set<int> _selected = {0, 1, 2, 3};

  void _toggle(int index) {
    setState(() {
      if (_selected.contains(index)) {
        _selected.remove(index);
      } else if (_selected.length < _maxSelection) {
        _selected.add(index);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding =
        MediaQuery.of(context).padding.bottom + DesignTokens.s16;

    return Scaffold(
      backgroundColor: DesignTokens.bgAppFoundation,
      appBar: AppBar(
        backgroundColor: DesignTokens.bgAppFoundation,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              size: 18, color: DesignTokens.textWhite),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Edit Profile Badges',
          style: TextStyle(
            fontFamily: DesignTokens.fontFamily,
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: DesignTokens.textWhite,
          ),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(
              DesignTokens.s16,
              DesignTokens.s16,
              DesignTokens.s16,
              DesignTokens.s20,
            ),
            child: Text(
              'Select any 4 badges you want to showcase in your profile',
              style: TextStyle(
                fontFamily: DesignTokens.fontFamily,
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: DesignTokens.textLight,
                height: 1.5,
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: DesignTokens.s16),
              child: GridView.builder(
                itemCount: _badges.length,
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  mainAxisSpacing: DesignTokens.s12,
                  crossAxisSpacing: DesignTokens.s12,
                ),
                itemBuilder: (context, i) => _BadgeTile(
                  badge: _badges[i],
                  isSelected: _selected.contains(i),
                  onTap: () => _toggle(i),
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              DesignTokens.s16,
              DesignTokens.s16,
              DesignTokens.s16,
              bottomPadding,
            ),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () => context.pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: DesignTokens.primaryGreen,
                  foregroundColor: DesignTokens.textWhite,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Submit',
                      style: TextStyle(
                        fontFamily: DesignTokens.fontFamily,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(width: DesignTokens.s8),
                    Icon(Icons.arrow_forward_rounded, size: 18),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BadgeItem {
  const _BadgeItem({required this.asset, required this.label});
  final String asset;
  final String label;
}

class _BadgeTile extends StatelessWidget {
  const _BadgeTile({
    required this.badge,
    required this.isSelected,
    required this.onTap,
  });

  final _BadgeItem badge;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: DesignTokens.bgAppBody,
          borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
          border: Border.all(
            color: isSelected
                ? DesignTokens.primaryGreen
                : Colors.transparent,
            width: 2,
          ),
        ),
        child: Stack(
          children: [
            Center(
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Image.asset(
                  badge.asset,
                  fit: BoxFit.contain,
                  errorBuilder: (_, _, _) => const Icon(
                    Icons.verified_outlined,
                    color: DesignTokens.textMuted,
                  ),
                ),
              ),
            ),
            if (isSelected)
              Positioned(
                top: 4,
                right: 4,
                child: Container(
                  width: 18,
                  height: 18,
                  decoration: const BoxDecoration(
                    color: DesignTokens.primaryGreen,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    size: 12,
                    color: Colors.white,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
