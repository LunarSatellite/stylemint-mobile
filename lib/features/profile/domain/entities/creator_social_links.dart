/// Creator-owned public social handles used by the Edit Profile form.
/// They are deliberately separate from account fields because a single
/// account can have multiple role profiles.
class CreatorSocialLinks {
  const CreatorSocialLinks({this.instagramHandle, this.tiktokHandle});

  final String? instagramHandle;
  final String? tiktokHandle;
}
