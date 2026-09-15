import 'package:flutter/material.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

// ============================================================================
// LEGACY COLOUR NAMES
//
// These `k*` constants used to be a separate violet/Tailwind-gray palette that
// drifted from Figma. The names are kept so older shared widgets keep
// compiling, but every value now aliases [DesignTokens] — the single source of
// truth. New code should use DesignTokens directly.
// ============================================================================

// ── Brand ────────────────────────────────────────────────────────────────────
const Color kPrimaryColor = DesignTokens.primaryGreen;
const Color kOnPrimaryColor = DesignTokens.buttonPrimaryText;
const Color kPrimaryLight = DesignTokens.primaryGreenLight;
const Color kPrimaryDark = DesignTokens.primaryGreenDark;
const Color kSecondaryColor = DesignTokens.secondaryYellow;
const Color kAccentColor = DesignTokens.secondaryYellow;

// ── Neutrals (dark-first) ────────────────────────────────────────────────────
const Color kScaffoldBg = DesignTokens.bgAppFoundation;
const Color kScaffoldBgDark = DesignTokens.bgAppFoundation;
const Color kSurfaceColor = DesignTokens.bgAppBody;
const Color kSurfaceColorDark = DesignTokens.bgAppBody;

// ── Text ─────────────────────────────────────────────────────────────────────
const Color kTextColor = DesignTokens.textWhite;
const Color kTextSecondary = DesignTokens.textMuted;
const Color kHintTextColor = DesignTokens.inputFieldPlaceholder;
const Color kTextInverse = DesignTokens.textDark;

// ── Borders / dividers ───────────────────────────────────────────────────────
const Color kBorderColor = DesignTokens.inputFieldBorder;
const Color kDividerColor = DesignTokens.bgAppBodyLight;

// ── Status ───────────────────────────────────────────────────────────────────
const Color kSuccessColor = DesignTokens.colorSuccess;
const Color kWarningColor = DesignTokens.colorWarning;
const Color kErrorColor = DesignTokens.colorError;
const Color kInfoColor = DesignTokens.colorInfo;

// ── Grey scale (zinc, matching DesignTokens' neutrals) ───────────────────────
const Color kGrey50 = Color(0xFFFAFAFA);
const Color kGrey100 = DesignTokens.lightSurfaceContainer;
const Color kGrey200 = DesignTokens.lightSurfaceContainerHigh;
const Color kGrey300 = DesignTokens.textLight;
const Color kGrey400 = DesignTokens.textMuted;
const Color kGrey500 = DesignTokens.dotSeparator;
const Color kGrey600 = DesignTokens.sectionOnBase;
const Color kGrey700 = DesignTokens.borderDefault;
const Color kGrey800 = DesignTokens.bgAppBodyLight;
const Color kGrey900 = DesignTokens.bgAppBody;

// ── Shimmer (tuned for the dark foundation) ──────────────────────────────────
const Color kShimmerBase = DesignTokens.bgAppBody;
const Color kShimmerHighlight = DesignTokens.bgAppBodyLight;
