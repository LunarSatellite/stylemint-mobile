/// The custom URL scheme the backend redirects to at the end of an OAuth
/// flow, for both sign-in (`stylemint://auth/oauth/callback`) and social
/// account connect (`stylemint://social-connected`).
///
/// It is the scheme alone, with no `://`, because that is what
/// `ASWebAuthenticationSession` matches on: the session watches every
/// navigation for this scheme, takes the whole URL, hands it back to the
/// caller and closes.
///
/// Shared rather than written out at each call site so the app and the
/// backend's `Identity:OAuthLogin:AppReturnUrl` / `Social:AppReturnUrl`
/// settings cannot drift apart one file at a time. If the backend ever moves
/// to a different scheme, this is the one place to change — and the Android
/// intent filter in `AndroidManifest.xml`, which must keep matching it.
const String oauthCallbackScheme = 'stylemint';
