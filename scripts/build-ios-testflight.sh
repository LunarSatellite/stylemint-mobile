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
#     # Epoch seconds, not a YYYYMMDDHHMM stamp. CFBundleVersion components must
# fit in 2^32 (4294967296) or App Store Connect rejects the upload, and a
# 12-digit datestamp like 202609220755 does not. Epoch is ~1.79e9 today,
# well under, and still climbs on every build.
BUILD_NUMBER="${BUILD_NUMBER:-$(date +%s)}"

KEY_PATH="$HOME/.appstoreconnect/private_keys/AuthKey_${ASC_KEY_ID:-none}.p8"

if [ -n "${ASC_KEY_ID:-}" ] && [ -n "${ASC_ISSUER_ID:-}" ] && [ -f "$KEY_PATH" ]; then
  # ---- API-key path -------------------------------------------------------
  # `flutter build ipa` has no passthrough for extra xcodebuild arguments, so
  # the App Store Connect key cannot be handed to it. Without the key, Xcode
  # falls back to whatever Apple ID is signed into it — which on this machine
  # was a free personal team, and personal teams support neither the
  # associated-domains/NFC entitlements this app declares nor TestFlight.
  #
  # So: let Flutter generate the Xcode configuration, then drive xcodebuild
  # directly with the key. Xcode then creates and downloads the distribution
  # certificate and provisioning profile itself, against the paid team the key
  # belongs to, with no interactive sign-in and no 2FA.
  say "Building IPA via xcodebuild with the App Store Connect key (build $BUILD_NUMBER)"

  flutter build ipa --release --build-number="$BUILD_NUMBER" --config-only

  AUTH=(
    -allowProvisioningUpdates
    -authenticationKeyID "$ASC_KEY_ID"
    -authenticationKeyIssuerID "$ASC_ISSUER_ID"
    -authenticationKeyPath "$KEY_PATH"
  )
  ARCHIVE="$PWD/build/ios/archive/Runner.xcarchive"
  rm -rf "$ARCHIVE" build/ios/ipa

  ( cd ios && xcodebuild       -workspace Runner.xcworkspace       -scheme Runner       -configuration Release       -archivePath "$ARCHIVE"       archive "${AUTH[@]}" ) || die "xcodebuild archive failed - see above"

  ( cd ios && xcodebuild       -exportArchive       -archivePath "$ARCHIVE"       -exportOptionsPlist ExportOptions.plist       -exportPath "$PWD/../build/ios/ipa"       "${AUTH[@]}" ) || die "xcodebuild export failed - see above"
else
  # ---- no key: Flutter drives it, using whatever Xcode is signed into ------
  say "Building IPA (build number $BUILD_NUMBER)"
  say "No ASC_KEY_ID/ASC_ISSUER_ID set - signing with the Apple ID in Xcode"
  flutter build ipa     --release     --build-number="$BUILD_NUMBER"     --export-options-plist=ios/ExportOptions.plist
fi

# Deliberately not `IPA=$(...) || die`: the exit status of an assignment is
# the pipeline's, and the pipeline ends in `head`, which succeeds even when
# the glob matched nothing. The emptiness check is the one that works.
IPA=$(ls build/ios/ipa/*.ipa 2>/dev/null | head -1 || true)
[ -n "$IPA" ] || die "no .ipa produced - check the archive log above"

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
