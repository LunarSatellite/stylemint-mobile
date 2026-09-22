#!/usr/bin/env bash
# ============================================================
# Build the iOS app and upload it to TestFlight. Run on a Mac.
# ------------------------------------------------------------
# The development machine is Windows, where `flutter build ipa` does not
# exist as a subcommand — Flutter only registers iOS builds on macOS. So this
# is the one step that has to happen on Apple hardware, either here or on the
# GitHub Actions macOS runner (.github/workflows/ios-testflight.yml).
#
# Usage, from the repo root on the Mac:
#     bash scripts/build-ios-testflight.sh              # build only
#     bash scripts/build-ios-testflight.sh --upload     # build, then upload
#     BUILD_NUMBER=7 bash scripts/build-ios-testflight.sh --upload
#
# Uploading needs an App Store Connect API key. Export these first — they are
# yours to create and this script never stores them:
#     export ASC_KEY_ID=XXXXXXXXXX
#     export ASC_ISSUER_ID=xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
#     # the .p8 must live at ~/.appstoreconnect/private_keys/AuthKey_$ASC_KEY_ID.p8
#
# Without --upload the script stops at the .ipa and tells you where it is, so
# you can drag it into Transporter instead.
# ============================================================
set -euo pipefail

UPLOAD=false
[ "${1:-}" = "--upload" ] && UPLOAD=true

say() { printf '\n\033[1;34m[ios]\033[0m %s\n' "$1"; }
die() { printf '\n\033[1;31m[ios] ERROR:\033[0m %s\n' "$1"; exit 1; }

# ── 0. sanity ───────────────────────────────────────────────
[ "$(uname -s)" = "Darwin" ] || die "this must run on macOS; there is no iOS toolchain elsewhere"
[ -f pubspec.yaml ] || die "run this from the repo root"
command -v flutter >/dev/null || die "flutter is not on PATH"
command -v xcodebuild >/dev/null || die "Xcode command line tools are missing: xcode-select --install"

# Xcode has to have been opened once to accept its licence, or xcodebuild
# fails with a licence error that looks nothing like a build problem.
xcodebuild -version >/dev/null 2>&1 || die "xcodebuild refused to run — open Xcode once and accept the licence"

say "Toolchain"
flutter --version | head -1
xcodebuild -version | head -1

# ── 1. dependencies ─────────────────────────────────────────
say "Resolving Dart dependencies"
flutter pub get

# The freezed / json_serializable output is gitignored (.gitignore lines 51-52),
# so a fresh clone has none of it and the build fails on missing .freezed.dart
# parts. This is the step people skip.
say "Generating code (freezed / json_serializable — gitignored, so required)"
dart run build_runner build

say "Installing CocoaPods"
( cd ios && pod install )

# ── 2. checks worth failing on before a 10-minute archive ───
say "Analyzer"
flutter analyze lib/ || die "analyzer errors — fix before shipping to testers"

say "Tests"
flutter test || die "tests failed — fix before shipping to testers"

# ── 3. build ────────────────────────────────────────────────
# App Store Connect rejects a build whose number is not higher than every
# build already uploaded for this version. pubspec says 1.0.0+1, so the first
# upload is build 1 and each later one must climb.
BUILD_NUMBER="${BUILD_NUMBER:-$(date +%Y%m%d%H%M)}"
say "Building IPA (build number $BUILD_NUMBER)"
flutter build ipa \
  --release \
  --build-number="$BUILD_NUMBER" \
  --export-options-plist=ios/ExportOptions.plist

# Deliberately not `IPA=$(...) || die`: the exit status of an assignment is
# the pipeline's, and the pipeline ends in `head`, which succeeds even when
# the glob matched nothing. The emptiness check is the one that works.
IPA=$(ls build/ios/ipa/*.ipa 2>/dev/null | head -1)
[ -n "$IPA" ] || die "no .ipa produced — check the archive log above"

say "Built $IPA"

# ── 4. upload ───────────────────────────────────────────────
if [ "$UPLOAD" = false ]; then
  cat <<EOF

Not uploading (no --upload).

  Drag this into Transporter, or re-run with --upload:
      $IPA

EOF
  exit 0
fi

[ -n "${ASC_KEY_ID:-}" ]    || die "ASC_KEY_ID is not set"
[ -n "${ASC_ISSUER_ID:-}" ] || die "ASC_ISSUER_ID is not set"
KEY_PATH="$HOME/.appstoreconnect/private_keys/AuthKey_${ASC_KEY_ID}.p8"
[ -f "$KEY_PATH" ] || die "API key not found at $KEY_PATH"

# Validate first. altool reports a missing usage string, a bad entitlement or
# a duplicate build number here, with a readable message, instead of letting
# the upload succeed and processing fail silently twenty minutes later.
say "Validating with App Store Connect"
xcrun altool --validate-app --type ios --file "$IPA" \
  --apiKey "$ASC_KEY_ID" --apiIssuer "$ASC_ISSUER_ID"

say "Uploading to TestFlight"
xcrun altool --upload-app --type ios --file "$IPA" \
  --apiKey "$ASC_KEY_ID" --apiIssuer "$ASC_ISSUER_ID"

cat <<EOF

Uploaded. Apple still has to process the build before it reaches testers —
usually 5-15 minutes. Watch it at App Store Connect -> TestFlight. If it is
rejected during processing you get an email; the reason is normally an
Info.plist or entitlement problem.

EOF
