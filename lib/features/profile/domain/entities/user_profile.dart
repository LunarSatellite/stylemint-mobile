class UserProfile {
  const UserProfile({
    required this.id,
    required this.displayName,
    required this.email,
    required this.phone,
    required this.avatarUrl,
    required this.bio,
    required this.website,
    required this.gender,
    required this.dateOfBirth,
    required this.language,
    required this.dateJoined,
  });

  final String id;
  final String displayName;
  final String email;
  final String phone;
  final String avatarUrl;
  final String bio;
  final String website;
  final String? gender;
  final DateTime? dateOfBirth;
  final String language;
  final DateTime dateJoined;

  UserProfile copyWith({
    String? id,
    String? displayName,
    String? email,
    String? phone,
    String? avatarUrl,
    String? bio,
    String? website,
    String? gender,
    DateTime? dateOfBirth,
    String? language,
    DateTime? dateJoined,
  }) {
    return UserProfile(
      id: id ?? this.id,
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      bio: bio ?? this.bio,
      website: website ?? this.website,
      gender: gender ?? this.gender,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      language: language ?? this.language,
      dateJoined: dateJoined ?? this.dateJoined,
    );
  }
}
