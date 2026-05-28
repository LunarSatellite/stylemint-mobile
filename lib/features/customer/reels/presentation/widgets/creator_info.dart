import 'package:flutter/material.dart';
import 'package:stylemint_mobile_frontend/features/customer/reels/domain/entities/reel.dart';

/// Creator info section showing avatar, creator name, music, follow button, and caption
class CreatorInfo extends StatefulWidget {
  final Reel reel;

  const CreatorInfo({
    Key? key,
    required this.reel,
  }) : super(key: key);

  @override
  State<CreatorInfo> createState() => _CreatorInfoState();
}

class _CreatorInfoState extends State<CreatorInfo> {
  late bool isFollowing;

  @override
  void initState() {
    super.initState();
    isFollowing = widget.reel.isCreatorFollowed ?? false;
  }

  void _toggleFollow() {
    setState(() {
      isFollowing = !isFollowing;
    });
    // TODO: Call domain use case to follow/unfollow creator
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Creator info row + follow button
          Row(
            children: [
              // Avatar
              if (widget.reel.creatorAvatarUrl.isNotEmpty)
                CircleAvatar(
                  radius: 20,
                  backgroundImage: NetworkImage(widget.reel.creatorAvatarUrl),
                ),

              const SizedBox(width: 12),

              // Creator name + music info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.reel.creatorName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Music info
                    if (widget.reel.musicTitle.isNotEmpty)
                      Row(
                        children: [
                          Icon(
                            Icons.music_note,
                            color: Colors.white70,
                            size: 12,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              widget.reel.musicTitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),

              const SizedBox(width: 12),

              // Follow button
              _buildFollowButton(),
            ],
          ),

          const SizedBox(height: 12),

          // Caption text
          if (widget.reel.caption.isNotEmpty)
            Text(
              widget.reel.caption,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                height: 1.4,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFollowButton() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
      ),
      child: GestureDetector(
        onTap: _toggleFollow,
        child: Text(
          isFollowing ? 'Following' : 'Follow',
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}
