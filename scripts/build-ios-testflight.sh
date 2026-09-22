#!/usr/bin/env bash
# ============================================================
# Build the iOS app and upload it to TestFlight. Run on a Mac.
# ------------------------------------------------------------
# `flutter build ipa` is not a subcommand on Windows — Flutter only registers
# iOS builds on macOS — so the archive has to happen on Apple hardware, either
# here or on the GitHub Actions runner (.github/workflows/ios-testflight.yml).
#
# Usage, from the repo root on the Mac:
#     bash scripts/build-ios-testflight.sh                 # build only
#     bash scripts/build-ios-testflight.sh --upload        # build, then upload
#     bash scripts/build-ios-testflight.sh --skip-checks   # no analyze/tests
#
# Environment:
#     ASC_KEY_ID       App Store Connect API key id, e.g. 8LHAVL3GC4
#     ASC_ISSUER_ID    the issuer UUID shown above the key list
#     ASC_TEAM_ID      the 10-character Team ID the key belongs to. Overrides
#                      DEVELOPMENT_TEAM in the Xcode project, where a stale
#                      personal-team id otherwise wins.
#     SM_BUILD_NUMBER  override the generated build number
#
# The .p8 must sit at ~/.appstoreconnect/private_keys/AuthKey_$ASC_KEY_ID.p8
#
# Without --upload it stops at the .ipa and prints the path, for Transporter.
# ============================================================
set -euo pipefail

UPLOAD=false
SKIP_CHECKS=false
for arg in "$@"; do
  case "$arg" in
    --upload)      UPLOAD=true ;;
    --skip-checks) SKIP_CHECKS=true ;;
    *) echo "unknown argument: $arg" >&2; exit 2 ;;
  esac
done

say() { printf '\n\033[1;34m[ios]\033[0m %s\n' "$1"; }
die() { printf '\n\033[1;31m[ios] ERROR:\033[0m %s\n' "$1" >&2; exit 1; }

# ── 0. sanity ───────────────────────────────────────────────
[ "$(uname -s)" = "Darwin" ] || die "this must run on macOS; there is no iOS toolchain elsewhere"
[ -f pubspec.yaml ] || die "run this from the repo root"
command -v flutter    >/dev/null || die "flutter is not on PATH"
command -v xcodebuild >/dev/null || die "Xcode command line tools missing: xcode-select --install"
xcodebuild -version >/dev/null 2>&1 || die "xcodebuild refused to run — open Xcode once and accept the licence"

say "Toolchain"
# Captured, not piped into `head`. Flutter writes its version-freshness notice
# to stdout asynchronously, so `flutter --version | head -1` lets head exit
# first, closes the pipe under the writer, and Flutter dies with
# "FileSystemException: Broken pipe". `sed -n 1p` reads to EOF instead.
flutter --version 2>/dev/null | sed -n '1p' || true
xcodebuild -version 2>/dev/null | sed -n '1p' || true

# ── 1. dependencies ─────────────────────────────────────────
say "Resolving Dart dependencies"
flutter pub get

# freezed / json_serializable output is gitignored, so a fresh clone has none
# of it and the build fails on missing .freezed.dart parts.
say "Generating code (gitignored, so required)"
dart run build_runner build

say "Installing CocoaPods"
# `pod install` treats Podfile.lock as a hard constraint on transitive pods.
# When the Dart side moves without the lock following, a plugin's podspec asks
# for a newer pod than the lock pins and resolution dies. `--repo-update` does
# not rescue that — it refreshes the spec repos but still honours the lock.
# Removing the lock is the only thing that re-resolves.
if ! ( cd ios && pod install ); then
  say "Lock is stale — re-resolving pods from the plugin podspecs"
  ( cd ios && pod repo update && rm -f Podfile.lock && pod install ) \
    || die "pod install still failing — read the resolution error above"
  say "ios/Podfile.lock was regenerated — commit it"
fi

# ── 2. checks ───────────────────────────────────────────────
if [ "$SKIP_CHECKS" = true ]; then
  say "Skipping analyzer and tests (--skip-checks)"
else
  say "Analyzer"
  # `--no-fatal-infos --no-fatal-warnings` is load-bearing: `flutter analyze`
  # exits 1 on ANY finding, and this repo carries ~4,700 info-level lints.
  # Only error-severity findings should stop a build reaching testers.
  flutter analyze lib/ --no-fatal-infos --no-fatal-warnings \
    || die "analyzer ERRORS (not lints) — fix before shipping to testers"

  say "Tests"
  flutter test || die "tests failed — fix before shipping to testers"
fi

# ── 3. build ────────────────────────────────────────────────
# Epoch seconds, not a YYYYMMDDHHMM stamp: CFBundleVersion components must fit
# in 2^32 and a 12-digit datestamp does not. Epoch is ~1.79e9 and still climbs.
BUILD_NUM="${SM_BUILD_NUMBER:-$(date +%s)}"
ARCHIVE="$PWD/build/ios/archive/Runner.xcarchive"
IPA_DIR="$PWD/build/ios/ipa"
KEY_PATH="$HOME/.appstoreconnect/private_keys/AuthKey_${ASC_KEY_ID:-none}.p8"

if [ -n "${ASC_KEY_ID:-}" ] && [ -n "${ASC_ISSUER_ID:-}" ] && [ -f "$KEY_PATH" ]; then
  say "Building with the App Store Connect key (build $BUILD_NUM)"

  # `--config-only` belongs to `flutter build ios`, NOT `flutter build ipa` —
  # checked against the SDK source. Its own help says it exists for a "CI/CD
  # process that create an archive", which is exactly this. `flutter build ipa`
  # has no passthrough for extra xcodebuild arguments, so the key cannot be
  # handed to it and xcodebuild must be driven directly.
  flutter build ios --release --build-number="$BUILD_NUM" --config-only

  AUTH=(
    -allowProvisioningUpdates
    -authenticationKeyID "$ASC_KEY_ID"
    -authenticationKeyIssuerID "$ASC_ISSUER_ID"
    -authenticationKeyPath "$KEY_PATH"
  )

  # DEVELOPMENT_TEAM is the only override, and it is deliberate: the project
  # hardcodes YBSBPFR23X, a free personal team, and Xcode answered 'No Account
  # for Team "YBSBPFR23X"'. Personal teams support neither this app's
  # associated-domains/NFC entitlements nor TestFlight. ASC_TEAM_ID points it
  # at the paid team the API key belongs to.
  #
  # CODE_SIGN_IDENTITY is deliberately NOT overridden. An earlier version
  # forced "Apple Distribution", reasoning that an App Store archive needs a
  # distribution identity. Xcode rejected that outright:
  #
  #   Runner has conflicting provisioning settings. Runner is automatically
  #   signed for development, but a conflicting code signing identity Apple
  #   Distribution has been manually specified.
  #
  # Under automatic signing the archive is signed for DEVELOPMENT; the
  # distribution re-signing happens at export, from the method in the export
  # options. And a build setting passed on the xcodebuild command line applies
  # to every target in the workspace, so it also demanded a distribution
  # certificate from all ~50 Pods targets, which are never signed individually.
  # The project's own "iPhone Developer" pin is correct; leave it alone.
  OVERRIDES=()
  if [ -n "${ASC_TEAM_ID:-}" ]; then
    OVERRIDES+=(DEVELOPMENT_TEAM="$ASC_TEAM_ID")
  else
    say "ASC_TEAM_ID is not set — using DEVELOPMENT_TEAM from the Xcode project"
  fi

  rm -rf "$ARCHIVE" "$IPA_DIR"

  # `${OVERRIDES[@]+...}` guards the empty-array case: macOS ships bash 3.2,
  # where "${arr[@]}" on an empty array under `set -u` is an unbound variable.
  ( cd ios && xcodebuild \
      -workspace Runner.xcworkspace \
      -scheme Runner \
      -configuration Release \
      -archivePath "$ARCHIVE" \
      archive "${AUTH[@]}" ${OVERRIDES[@]+"${OVERRIDES[@]}"} ) \
    || die "xcodebuild archive failed — see the errors above"

  # The export step takes no build-setting overrides, so its team can only come
  # from the plist. A copy is used rather than editing the committed file, so
  # the checked-in default cannot silently disagree with the key in use.
  EXPORT_PLIST="$PWD/ios/ExportOptions.plist"
  if [ -n "${ASC_TEAM_ID:-}" ]; then
    EXPORT_PLIST="$(mktemp -t ExportOptions)"
    cp ios/ExportOptions.plist "$EXPORT_PLIST"
    /usr/libexec/PlistBuddy -c "Set :teamID $ASC_TEAM_ID" "$EXPORT_PLIST" \
      || die "could not set teamID in the export options"
    say "Exporting for team $ASC_TEAM_ID"
  fi

  xcodebuild \
      -exportArchive \
      -archivePath "$ARCHIVE" \
      -exportOptionsPlist "$EXPORT_PLIST" \
      -exportPath "$IPA_DIR" \
      "${AUTH[@]}" \
    || die "xcodebuild export failed — see the errors above"
else
  say "Building with the Apple ID signed into Xcode (build $BUILD_NUM)"
  say "No ASC_KEY_ID / ASC_ISSUER_ID / key file — signing may fall back to a personal team"
  flutter build ipa \
    --release \
    --build-number="$BUILD_NUM" \
    --export-options-plist=ios/ExportOptions.plist
fi

# Deliberately not `IPA=$(...) || die`: an assignment inherits the pipeline's
# status, the pipeline ends in `head`, and head succeeds on empty input.
IPA=$(ls "$IPA_DIR"/*.ipa 2>/dev/null | head -1 || true)
[ -n "$IPA" ] || die "no .ipa produced — check the archive log above"

say "Built $IPA"

# ── 4. upload ───────────────────────────────────────────────
if [ "$UPLOAD" = false ]; then
  printf '\nNot uploading (no --upload). Drag this into Transporter:\n    %s\n\n' "$IPA"
  exit 0
fi

[ -n "${ASC_KEY_ID:-}" ]    || die "ASC_KEY_ID is not set"
[ -n "${ASC_ISSUER_ID:-}" ] || die "ASC_ISSUER_ID is not set"
[ -f "$KEY_PATH" ]          || die "API key not found at $KEY_PATH"

# Validate first: altool reports a missing usage string, a bad entitlement or a
# duplicate build number here, readably, instead of the upload appearing to
# succeed and processing failing silently twenty minutes later.
say "Validating with App Store Connect"
xcrun altool --validate-app --type ios --file "$IPA" \
  --apiKey "$ASC_KEY_ID" --apiIssuer "$ASC_ISSUER_ID" \
  || die "validation failed — not uploading"

say "Uploading to TestFlight"
xcrun altool --upload-app --type ios --file "$IPA" \
  --apiKey "$ASC_KEY_ID" --apiIssuer "$ASC_ISSUER_ID" \
  || die "upload failed"

printf '\nUploaded. Apple processes the build before it reaches testers, usually\n5-15 minutes. Watch App Store Connect -> TestFlight.\n\n'
