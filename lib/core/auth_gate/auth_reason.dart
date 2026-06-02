/// Why auth is being requested — drives the inline prompt copy so the sheet is
/// contextual ("Sign in to add to cart" vs a generic message).
enum AuthReason {
  like,
  comment,
  share,
  follow,
  save,
  addToCart,
  checkout,
  tip,
  general;

  String get prompt => switch (this) {
        AuthReason.like => 'Sign in to like',
        AuthReason.comment => 'Sign in to comment',
        AuthReason.share => 'Sign in to share',
        AuthReason.follow => 'Sign in to follow',
        AuthReason.save => 'Sign in to save',
        AuthReason.addToCart => 'Sign in to add to cart',
        AuthReason.checkout => 'Sign in to check out',
        AuthReason.tip => 'Sign in to send a tip',
        AuthReason.general => 'Sign in to continue',
      };
}
