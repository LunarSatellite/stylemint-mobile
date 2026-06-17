enum CreatorApplicationStatus {
  pending('Pending'),
  underReview('Under Review'),
  approved('Approved'),
  rejected('Rejected');

  const CreatorApplicationStatus(this.label);

  final String label;
}

class CreatorApplication {
  const CreatorApplication({
    required this.id,
    required this.status,
    this.rejectionReason,
    required this.submittedAt,
    required this.updatedAt,
  });

  final String id;
  final CreatorApplicationStatus status;
  final String? rejectionReason;
  final DateTime submittedAt;
  final DateTime updatedAt;

  CreatorApplication copyWith({
    String? id,
    CreatorApplicationStatus? status,
    String? rejectionReason,
    DateTime? submittedAt,
    DateTime? updatedAt,
  }) {
    return CreatorApplication(
      id: id ?? this.id,
      status: status ?? this.status,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      submittedAt: submittedAt ?? this.submittedAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is CreatorApplication &&
      other.id == id &&
      other.status == status &&
      other.rejectionReason == rejectionReason &&
      other.submittedAt == submittedAt &&
      other.updatedAt == updatedAt;

  @override
  int get hashCode => Object.hash(id, status, rejectionReason, submittedAt, updatedAt);
}

class Platform {
  const Platform({
    required this.id,
    required this.name,
    required this.handle,
    required this.followerCount,
    this.connected = false,
  });

  final String id;
  final String name;
  final String handle;
  final int followerCount;
  final bool connected;

  Platform copyWith({
    String? id,
    String? name,
    String? handle,
    int? followerCount,
    bool? connected,
  }) {
    return Platform(
      id: id ?? this.id,
      name: name ?? this.name,
      handle: handle ?? this.handle,
      followerCount: followerCount ?? this.followerCount,
      connected: connected ?? this.connected,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is Platform &&
      other.id == id &&
      other.name == name &&
      other.handle == handle &&
      other.followerCount == followerCount &&
      other.connected == connected;

  @override
  int get hashCode => Object.hash(id, name, handle, followerCount, connected);
}

/// A selectable creator content category from `GET /v1/public/creator-categories`.
/// Its [id] is what the apply payload sends in `contentCategoryIds`.
class CreatorContentCategory {
  const CreatorContentCategory({
    required this.id,
    required this.name,
    this.requiresOtherDescription = false,
  });

  final String id;
  final String name;

  /// When true (the "Other" bucket) the backend requires an
  /// `otherCategoryDescription` alongside this id.
  final bool requiresOtherDescription;
}

class CreatorApplicationForm {
  const CreatorApplicationForm({
    required this.fullName,
    required this.handle,
    required this.platforms,
    required this.contentCategoryIds,
    required this.audienceBand,
    required this.bio,
    this.portfolioUrl,
    this.identityDocUrl,
  });

  final String fullName;
  final String handle;
  final List<Platform> platforms;

  /// GUIDs of selected content categories (from `GET /v1/public/interests`).
  /// The backend requires at least one (`ContentCategoryIds` NotEmpty).
  final List<String> contentCategoryIds;

  /// Required audience-size band — the backend `AudienceSizeBand` integer enum
  /// (1..5, ascending by follower count).
  final int audienceBand;
  final String bio;
  final String? portfolioUrl;
  final String? identityDocUrl;

  CreatorApplicationForm copyWith({
    String? fullName,
    String? handle,
    List<Platform>? platforms,
    List<String>? contentCategoryIds,
    int? audienceBand,
    String? bio,
    String? portfolioUrl,
    String? identityDocUrl,
  }) {
    return CreatorApplicationForm(
      fullName: fullName ?? this.fullName,
      handle: handle ?? this.handle,
      platforms: platforms ?? this.platforms,
      contentCategoryIds: contentCategoryIds ?? this.contentCategoryIds,
      audienceBand: audienceBand ?? this.audienceBand,
      bio: bio ?? this.bio,
      portfolioUrl: portfolioUrl ?? this.portfolioUrl,
      identityDocUrl: identityDocUrl ?? this.identityDocUrl,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is CreatorApplicationForm &&
      other.fullName == fullName &&
      other.handle == handle &&
      _listEquals(other.platforms, platforms) &&
      _listEquals(other.contentCategoryIds, contentCategoryIds) &&
      other.audienceBand == audienceBand &&
      other.bio == bio &&
      other.portfolioUrl == portfolioUrl &&
      other.identityDocUrl == identityDocUrl;

  @override
  int get hashCode => Object.hash(fullName, handle, platforms.length,
      contentCategoryIds.length, audienceBand, bio, portfolioUrl, identityDocUrl);

  static bool _listEquals<T>(List<T> a, List<T> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
