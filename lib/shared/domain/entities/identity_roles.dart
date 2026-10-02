/// The backend's `RoleType` values, in one place.
///
/// These ids travel on the wire (`role_profiles.role`, `POST /v1/roles`) and
/// were previously written as bare literals in three screens — the role
/// picker, the profile role switcher and now the courier gate — each with its
/// own comment explaining what 2 and 3 meant. Adding a fourth role made that
/// untenable: a set of magic numbers that must agree across features, with
/// nothing to make them.
///
/// Keep in step with `StyleMint.Modules.Identity.Enums.RoleType`.
abstract final class IdentityRoles {
  /// Shopper. Needs no application — requested and activated inline.
  static const int customer = 1;

  /// Content creator. Activatable once the creator profile is approved.
  static const int creator = 2;

  /// Seller. Activatable once the vendor application is approved.
  static const int vendor = 3;

  /// Delivery partner. Activatable once the courier profile has cleared its
  /// checks, which Identity asks the Delivery module about rather than
  /// storing — so this role mirrors the courier profile and never overrides
  /// it. The courier profile alone decides whether a parcel may be carried.
  static const int courier = 4;
}
