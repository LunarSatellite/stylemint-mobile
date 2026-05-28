import 'package:flutter/material.dart';
import 'package:stylemint_mobile_frontend/features/customer/reels/domain/entities/reel.dart';

/// Right-side action buttons for reel interactions
/// Shows like, comment, share, wishlist, and add to cart actions
class ReelActions extends StatefulWidget {
  final Reel reel;

  const ReelActions({
    Key? key,
    required this.reel,
  }) : super(key: key);

  @override
  State<ReelActions> createState() => _ReelActionsState();
}

class _ReelActionsState extends State<ReelActions> {
  late bool isLiked;
  late bool isWishlisted;
  late int likeCount;
  late int commentCount;
  late int shareCount;

  @override
  void initState() {
    super.initState();
    isLiked = widget.reel.isLikedByUser ?? false;
    isWishlisted = widget.reel.isWishlistedByUser ?? false;
    likeCount = widget.reel.likeCount;
    commentCount = widget.reel.commentCount;
    shareCount = widget.reel.shareCount;
  }

  void _toggleLike() {
    setState(() {
      isLiked = !isLiked;
      likeCount += isLiked ? 1 : -1;
    });
    // TODO: Call domain use case to like/unlike reel
  }

  void _toggleWishlist() {
    setState(() {
      isWishlisted = !isWishlisted;
    });
    // TODO: Call domain use case to add/remove from wishlist
  }

  void _showComments() {
    // TODO: Navigate to comments screen
  }

  void _share() {
    // TODO: Call share functionality
  }

  void _addToCart() {
    // TODO: Call domain use case to add product to cart
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Like button
        _ActionButton(
          icon: isLiked ? Icons.favorite : Icons.favorite_outline,
          label: _formatCount(likeCount),
          color: isLiked ? Colors.red : Colors.white,
          onTap: _toggleLike,
        ),

        const SizedBox(height: 16),

        // Comment button
        _ActionButton(
          icon: Icons.chat_bubble_outline,
          label: _formatCount(commentCount),
          color: Colors.white,
          onTap: _showComments,
        ),

        const SizedBox(height: 16),

        // Share button
        _ActionButton(
          icon: Icons.share,
          label: _formatCount(shareCount),
          color: Colors.white,
          onTap: _share,
        ),

        const SizedBox(height: 16),

        // Wishlist button
        _ActionButton(
          icon: isWishlisted ? Icons.bookmark : Icons.bookmark_outline,
          label: '',
          color: isWishlisted ? Colors.white : Colors.white70,
          onTap: _toggleWishlist,
        ),

        const SizedBox(height: 16),

        // Add to cart button
        _ActionButton(
          icon: Icons.shopping_cart,
          label: widget.reel.taggedProducts.isEmpty ? '' : '${widget.reel.taggedProducts.length}',
          color: Colors.white,
          onTap: _addToCart,
        ),
      ],
    );
  }

  String _formatCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    } else {
      return count.toString();
    }
  }
}

/// Individual action button for reel interactions
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.black.withOpacity(0.3),
            ),
            child: Icon(
              icon,
              color: color,
              size: 24,
            ),
          ),
          if (label.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
