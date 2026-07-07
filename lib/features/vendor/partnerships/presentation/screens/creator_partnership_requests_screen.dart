import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

class CreatorPartnershipRequestsScreen extends StatelessWidget {
  const CreatorPartnershipRequestsScreen({super.key});

  static final _requests = [
    _PartnershipRequest(
      id: '1',
      creatorName: 'Immovable Royale',
      handle: '@immovableroyale',
      commission: '12% - 18%',
      assetAvatar: null,
      niche: 'Fitness & Sports',
      audienceGroup: 'Fitness Enthusiasts, Sport People & Athletes',
      message:
          'Hi there! We love your sports content and think you\'d be a great fit for our winter collection. Interested in a collaboration?',
      followers: '250k',
      likes: '5k',
      posts: '1000+',
      rating: '4.9',
      reach: '250k',
      engagement: '5k',
      subscribers: '105k',
      reels: '227k',
      statusChip: 'Request Pending',
    ),
    _PartnershipRequest(
      id: '2',
      creatorName: 'Clever Jane',
      handle: '@cleverjane',
      commission: '10% - 15%',
      niche: 'Lifestyle',
      audienceGroup: 'Young Adults, Fashion & Lifestyle',
      message:
          'Hi there! We are launching a brand new segment of products inspired by fitness and sports enthusiasts. We really like the content you make in this genre and we are hoping to...',
      followers: '180k',
      likes: '3k',
      posts: '800+',
      rating: '4.7',
      reach: '180k',
      engagement: '3.5k',
      subscribers: '80k',
      reels: '150k',
      statusChip: 'Request Pending',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignTokens.bgAppFoundation,
      appBar: AppBar(
        backgroundColor: DesignTokens.bgAppFoundation,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            size: 18,
            color: DesignTokens.textWhite,
          ),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Creator Partnership Requests',
          style: DesignTokens.oneLinerSemibold,
        ),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.symmetric(
          horizontal: DesignTokens.s16,
          vertical: DesignTokens.s12,
        ),
        itemCount: _requests.length,
        separatorBuilder: (_, __) => const SizedBox(height: DesignTokens.s8),
        itemBuilder: (context, index) => _RequestCard(
          request: _requests[index],
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  _PartnershipDetailScreen(request: _requests[index]),
            ),
          ),
        ),
      ),
    );
  }
}

class _RequestCard extends StatelessWidget {
  const _RequestCard({required this.request, required this.onTap});

  final _PartnershipRequest request;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(DesignTokens.s12),
        decoration: DesignTokens.cardDecoration(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Creator header
            Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: const Color(0xFF2C2C2E),
                  backgroundImage: request.assetAvatar != null
                      ? AssetImage(request.assetAvatar!)
                      : null,
                  child: request.assetAvatar == null
                      ? Text(
                          request.creatorName[0],
                          style: DesignTokens.mediumSemibold.copyWith(
                            color: DesignTokens.primaryGreen,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: DesignTokens.s8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        request.creatorName,
                        style: DesignTokens.smallRegular.copyWith(
                          fontWeight: FontWeight.w700,
                          color: DesignTokens.textWhite,
                        ),
                      ),
                      Text(
                        request.handle,
                        style: DesignTokens.smallRegular.copyWith(
                          color: DesignTokens.textMuted,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: DesignTokens.s8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFB8E6FE),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Requested Commission: ${request.commission}',
                          style: const TextStyle(
                            fontFamily: DesignTokens.fontFamily,
                            fontSize: 10,
                            color: Color(0xFF0D1B2A),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: DesignTokens.s8),
            const Divider(
              color: DesignTokens.borderDefault,
              height: 1,
              thickness: 1,
            ),
            const SizedBox(height: DesignTokens.s8),
            // Niche & followers tags
            Row(
              children: [
                _Tag(
                  label: request.niche,
                  color: const Color(0xFF1A3A1A),
                  textColor: DesignTokens.primaryGreen,
                ),
                const SizedBox(width: DesignTokens.s6),
                _Tag(
                  label: '${request.followers} Followers',
                  color: const Color(0xFF1A2A3A),
                  textColor: const Color(0xFF4DA6FF),
                ),
              ],
            ),
            const SizedBox(height: DesignTokens.s8),
            // Audience
            Text(
              'Audience Group: ${request.audienceGroup}',
              style: DesignTokens.smallRegular.copyWith(
                color: DesignTokens.textMuted,
                fontSize: 11,
              ),
            ),
            const SizedBox(height: DesignTokens.s6),
            // Message
            Text(
              'Message:',
              style: DesignTokens.smallRegular.copyWith(
                color: DesignTokens.textMuted,
                fontSize: 11,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              request.message,
              style: DesignTokens.smallRegular.copyWith(
                color: const Color(0xFFD4D4D8),
                fontSize: 12,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: DesignTokens.s12),
            // Buttons
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 36,
                    child: OutlinedButton(
                      onPressed: () {},
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFF3A3A3C)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: Text(
                        'Decline',
                        style: DesignTokens.smallRegular.copyWith(
                          color: DesignTokens.textWhite,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: DesignTokens.s8),
                Expanded(
                  child: SizedBox(
                    height: 36,
                    child: ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: DesignTokens.primaryGreen,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: Text(
                        'Accept',
                        style: DesignTokens.smallRegular.copyWith(
                          color: Colors.black,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PartnershipDetailScreen extends StatelessWidget {
  const _PartnershipDetailScreen({required this.request});

  final _PartnershipRequest request;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignTokens.bgAppFoundation,
      appBar: AppBar(
        backgroundColor: DesignTokens.bgAppFoundation,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            size: 18,
            color: DesignTokens.textWhite,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Partnership Request Detail',
          style: DesignTokens.oneLinerSemibold,
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: DesignTokens.s16),
            child: Image.asset(
              'assets/images/vendordashboard/icon_vector_share.png',
              width: 22,
              height: 22,
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
          horizontal: DesignTokens.s16,
          vertical: DesignTokens.s12,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Creator header
            Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: const Color(0xFF2C2C2E),
                  backgroundImage: request.assetAvatar != null
                      ? AssetImage(request.assetAvatar!)
                      : null,
                  child: request.assetAvatar == null
                      ? Text(
                          request.creatorName[0],
                          style: DesignTokens.titleLarge.copyWith(
                            color: DesignTokens.primaryGreen,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: DesignTokens.s12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        request.creatorName,
                        style: DesignTokens.mediumSemibold,
                      ),
                      Text(
                        request.handle,
                        style: DesignTokens.smallRegular.copyWith(
                          color: DesignTokens.textMuted,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: DesignTokens.s8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFB8E6FE),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          request.statusChip,
                          style: const TextStyle(
                            fontFamily: DesignTokens.fontFamily,
                            fontSize: 11,
                            color: Color(0xFF0D1B2A),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: DesignTokens.s16),
            // Niche
            _DetailRow(label: 'Niche', value: request.niche),
            const SizedBox(height: DesignTokens.s8),
            _DetailRow(label: 'Audience Group', value: request.audienceGroup),
            const SizedBox(height: DesignTokens.s12),
            // Message
            Text(
              'Message',
              style: DesignTokens.smallRegular.copyWith(
                color: DesignTokens.textMuted,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              request.message,
              style: DesignTokens.smallRegular.copyWith(
                color: const Color(0xFFD4D4D8),
              ),
            ),
            const SizedBox(height: DesignTokens.s16),
            // Creator Profile Metrics
            Text(
              'Creator Profile Metrics',
              style: DesignTokens.smallRegular.copyWith(
                fontWeight: FontWeight.w700,
                color: DesignTokens.textWhite,
              ),
            ),
            const SizedBox(height: DesignTokens.s12),
            GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: DesignTokens.s8,
              mainAxisSpacing: DesignTokens.s8,
              childAspectRatio: 1.0,
              children: [
                _MetricTile(
                  assetIcon: 'assets/images/vendordashboard/followers.png',
                  value: request.followers,
                  label: 'Followers',
                ),
                _MetricTile(
                  assetIcon: 'assets/images/vendordashboard/icon_reels.png',
                  value: request.reels,
                  label: 'Reels',
                ),
                _MetricTile(
                  assetIcon: 'assets/images/vendordashboard/icon_thumb_up.png',
                  value: request.likes,
                  label: 'Likes',
                ),
                _MetricTile(
                  assetIcon: 'assets/images/vendordashboard/icon_star.png',
                  value: request.rating,
                  label: 'Stars',
                ),
                _MetricTile(
                  assetIcon: 'assets/icons/instagram.svg',
                  value: request.reach,
                  label: 'Followers',
                ),
                _MetricTile(
                  assetIcon: 'assets/icons/tiktok.svg',
                  value: request.engagement,
                  label: 'Followers',
                ),
                _MetricTile(
                  assetIcon: 'assets/icons/youtube.svg',
                  value: request.subscribers,
                  label: 'Subscribers',
                ),
                _MetricTile(
                  assetIcon: 'assets/icons/facebook.svg',
                  value: request.followers,
                  label: 'Likes',
                ),
              ],
            ),
            const SizedBox(height: DesignTokens.s16),
            // Sample Content
            Text(
              'Sample Content',
              style: DesignTokens.smallRegular.copyWith(
                fontWeight: FontWeight.w700,
                color: DesignTokens.textWhite,
              ),
            ),
            const SizedBox(height: DesignTokens.s8),
            SizedBox(
              height: 100,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: 3,
                separatorBuilder: (_, __) =>
                    const SizedBox(width: DesignTokens.s8),
                itemBuilder: (_, i) {
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(
                      DesignTokens.inputRadius,
                    ),
                    child: Container(
                      width: 100,
                      height: 100,
                      color: DesignTokens.bgAppBodyLight,
                      child: const Icon(
                        Icons.image_outlined,
                        color: DesignTokens.textMuted,
                        size: 32,
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: DesignTokens.s16),
            // Courier Offer
            Container(
              padding: const EdgeInsets.all(DesignTokens.s12),
              decoration: DesignTokens.cardDecoration(),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1A1A),
                      borderRadius: BorderRadius.circular(
                        DesignTokens.inputRadius,
                      ),
                    ),
                    padding: const EdgeInsets.all(8),
                    child: Image.asset(
                      'assets/images/vendordashboard/icon_courier_offer.png',
                    ),
                  ),
                  const SizedBox(width: DesignTokens.s12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Courier Offer',
                          style: DesignTokens.smallRegular.copyWith(
                            fontWeight: FontWeight.w700,
                            color: DesignTokens.textWhite,
                          ),
                        ),
                        Text(
                          'Free product sample included in partnership',
                          style: DesignTokens.smallRegular.copyWith(
                            color: DesignTokens.textMuted,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: DesignTokens.s24),
            // Accept button
            SizedBox(
              width: double.infinity,
              height: DesignTokens.buttonHeight,
              child: ElevatedButton(
                onPressed: () => _showConfirmation(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: DesignTokens.primaryGreen,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: Text(
                  'Accept Request',
                  style: DesignTokens.smallRegular.copyWith(
                    color: Colors.black,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(height: DesignTokens.s8),
            // Decline button
            SizedBox(
              width: double.infinity,
              height: DesignTokens.buttonHeight,
              child: OutlinedButton(
                onPressed: () => _showConfirmation(context, false),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF3A3A3C)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: Text(
                  'Decline Request',
                  style: DesignTokens.smallRegular.copyWith(
                    color: DesignTokens.textWhite,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(height: DesignTokens.s16),
          ],
        ),
      ),
    );
  }

  void _showConfirmation(BuildContext context, bool isAccept) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1C1C1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(DesignTokens.s16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: DesignTokens.borderDefault,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: DesignTokens.s16),
              Icon(
                isAccept ? Icons.check_circle_outline : Icons.cancel_outlined,
                color: isAccept
                    ? DesignTokens.primaryGreen
                    : DesignTokens.colorError,
                size: 48,
              ),
              const SizedBox(height: DesignTokens.s12),
              Text(
                isAccept
                    ? 'Accept Partnership Request?'
                    : 'Decline Partnership Request?',
                style: DesignTokens.mediumSemibold,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: DesignTokens.s8),
              Text(
                isAccept
                    ? 'You are about to accept ${request.creatorName}\'s partnership request.'
                    : 'You are about to decline ${request.creatorName}\'s partnership request.',
                style: DesignTokens.smallRegular.copyWith(
                  color: DesignTokens.textMuted,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: DesignTokens.s20),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: DesignTokens.buttonHeight,
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFF3A3A3C)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: Text(
                          'Cancel',
                          style: DesignTokens.smallRegular.copyWith(
                            color: DesignTokens.textWhite,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: DesignTokens.s8),
                  Expanded(
                    child: SizedBox(
                      height: DesignTokens.buttonHeight,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isAccept
                              ? DesignTokens.primaryGreen
                              : DesignTokens.colorError,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: Text(
                          isAccept ? 'Accept' : 'Decline',
                          style: DesignTokens.smallRegular.copyWith(
                            color: Colors.black,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: DesignTokens.s8),
            ],
          ),
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({
    required this.label,
    required this.color,
    required this.textColor,
  });

  final String label;
  final Color color;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: DesignTokens.s6,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: DesignTokens.fontFamily,
          fontSize: 10,
          color: textColor,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        style: const TextStyle(
          fontFamily: DesignTokens.fontFamily,
          fontSize: 12,
        ),
        children: [
          TextSpan(
            text: '$label: ',
            style: const TextStyle(
              color: Color(0xFFFFFFFF),
              fontWeight: FontWeight.w600,
            ),
          ),
          TextSpan(
            text: value,
            style: const TextStyle(
              color: Color(0xFFD4D4D8),
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.assetIcon,
    required this.value,
    required this.label,
  });

  final String assetIcon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(DesignTokens.s12),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(DesignTokens.inputRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          assetIcon.endsWith('.svg')
              ? SvgPicture.asset(assetIcon, width: 28, height: 28)
              : Image.asset(assetIcon, width: 28, height: 28),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: DesignTokens.smallRegular.copyWith(
                  fontWeight: FontWeight.w700,
                  color: DesignTokens.textWhite,
                  fontSize: 15,
                ),
              ),
              Text(
                label,
                style: DesignTokens.smallRegular.copyWith(
                  color: DesignTokens.textMuted,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PartnershipRequest {
  const _PartnershipRequest({
    required this.id,
    required this.creatorName,
    required this.handle,
    required this.commission,
    this.assetAvatar,
    required this.niche,
    required this.audienceGroup,
    required this.message,
    required this.followers,
    required this.likes,
    required this.posts,
    required this.rating,
    required this.reach,
    required this.engagement,
    required this.subscribers,
    required this.reels,
    required this.statusChip,
  });

  final String id;
  final String creatorName;
  final String handle;
  final String commission;
  final String? assetAvatar;
  final String niche;
  final String audienceGroup;
  final String message;
  final String followers;
  final String likes;
  final String posts;
  final String rating;
  final String reach;
  final String engagement;
  final String subscribers;
  final String reels;
  final String statusChip;
}
