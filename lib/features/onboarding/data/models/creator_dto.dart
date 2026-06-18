class CreatorDto {
  const CreatorDto({
    required this.id,
    required this.name,
    required this.handle,
    required this.category,
    required this.description,
    required this.rating,
    required this.followers,
    this.avatarUrl,
  });

  final String id;
  final String name;
  final String handle;
  final String category;
  final String description;
  final double rating;
  final int followers;
  final String? avatarUrl;

  factory CreatorDto.fromJson(Map<String, dynamic> json) => CreatorDto(
        id: json['id'] as String,
        name: json['name'] as String,
        handle: json['handle'] as String,
        category: json['category'] as String,
        description: json['description'] as String,
        rating: (json['rating'] as num).toDouble(),
        followers: json['followers'] as int,
        avatarUrl: json['avatarUrl'] as String?,
      );

  String get formattedRating => rating.toStringAsFixed(1);

  String get formattedFollowers {
    if (followers >= 1000000) return '${(followers / 1000000).toStringAsFixed(1)}M';
    if (followers >= 1000) return '${(followers / 1000).toStringAsFixed(1)}k';
    return followers.toString();
  }
}
