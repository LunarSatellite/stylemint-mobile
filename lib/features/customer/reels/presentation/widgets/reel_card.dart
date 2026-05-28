import 'package:flutter/material.dart';
import 'package:stylemint_mobile_frontend/features/customer/reels/domain/entities/reel.dart';
import 'package:stylemint_mobile_frontend/theme/app_theme.dart';
import 'creator_info.dart';
import 'reel_actions.dart';
import 'tagged_products_section.dart';
import 'reel_player.dart';

/// Individual reel card displaying video, creator info, caption, actions, and products
class ReelCard extends StatelessWidget {
  final Reel reel;

  const ReelCard({
    Key? key,
    required this.reel,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Video background / image
        ReelPlayer(reel: reel),

        // Overlay with content
        Positioned.fill(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Status bar (top)
              SafeArea(
                bottom: false,
                child: Container(
                  height: 44,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Reels',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      Icon(Icons.more_vert, color: Colors.white),
                    ],
                  ),
                ),
              ),

              // Bottom section with creator info, caption, products, actions, and navbar
              SafeArea(
                top: false,
                child: Container(
                  color: Colors.black54,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Creator info + caption
                      CreatorInfo(reel: reel),

                      const SizedBox(height: 16),

                      // Tagged products
                      if (reel.taggedProducts.isNotEmpty)
                        TaggedProductsSection(products: reel.taggedProducts),

                      const SizedBox(height: 16),

                      // Bottom navbar
                      _buildBottomNavbar(context),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        // Right side action buttons
        Positioned(
          right: 12,
          bottom: 200, // Adjust based on navbar height
          child: ReelActions(reel: reel),
        ),
      ],
    );
  }

  Widget _buildBottomNavbar(BuildContext context) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.8),
        border: Border(
          top: BorderSide(color: Colors.white10),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _navItem(Icons.home, 'Home', true),
          _navItem(Icons.explore, 'Explore', false),
          _navItem(Icons.add_circle, 'Post', false),
          _navItem(Icons.notifications, 'Notifications', false),
          _navItem(Icons.person, 'Profile', false),
        ],
      ),
    );
  }

  Widget _navItem(IconData icon, String label, bool isActive) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          icon,
          color: isActive ? Colors.white : Colors.grey,
          size: 24,
        ),
      ],
    );
  }
}
