// ============================================================================
// DESIGN TOKENS — Single source of truth for the Style Mint design system.
//
// Values are sourced DIRECTLY from Figma variables (Dev Mode MCP), not PDFs.
//   File:    Style Mint Mobile App
//   FileKey: iLXoCdfCr47LSIUX74j1nc
//   Pulled:  Auth section variables (node 9684:13311)
//
// To refresh: re-run get_variable_defs on a representative node and reconcile.
// Token names mirror the Figma variable names where practical so design→code
// stays traceable. Backward-compat aliases (h1/h2/h3/body/small) are kept at
// the bottom of each section so existing screens keep compiling.
// ============================================================================

import 'package:flutter/material.dart';

class DesignTokens {
  DesignTokens._(); // all members static

  // ==========================================================================
  // COLORS  (Figma variable name → value)
  // ==========================================================================

  // --- Brand ---------------------------------------------------------------
  /// Button/Primary/Solid/Default/Fill, Text/Primary, Radio checked icon
  static const Color primaryGreen = Color(0xFF2ECC71);
  static const Color primaryGreenDark = Color(0xFF092A17); // status bg (PDF)
  static const Color primaryGreenLight = Color(0xFF0F4325); // chip fill (PDF)

  /// Fill/Secondary/Default — accent yellow
  static const Color secondaryYellow = Color(0xFFF1C40F);

  // --- Backgrounds / Fills -------------------------------------------------
  static const Color bgAppFoundation = Color(0xFF09090B); // Fill/App Foundation, Gray/950
  static const Color bgAppBody = Color(0xFF18181B); // Text/Dark, Radio fill
  static const Color bgAppBodyLight = Color(0xFF27272A); // Fill/App Body Light

  // --- Text ----------------------------------------------------------------
  static const Color textWhite = Color(0xFFFFFFFF); // Text/White
  static const Color textLight = Color(0xFFD4D4D8); // Text/Light, Gray/300
  static const Color textMuted = Color(0xFF9F9FA9); // Text/Muted
  static const Color textDark = Color(0xFF18181B); // Text/Dark
  static const Color textContentSecondary = Color(0xFF737373); // text-content-secondary

  // --- Icons ---------------------------------------------------------------
  static const Color iconWhite = Color(0xFFFFFFFF); // Icon/White
  static const Color iconDark = Color(0xFF27272A); // Icon/Dark
  static const Color iconLight = Color(0xFF9F9FA9); // Icon/Light

  // --- Semantic status -----------------------------------------------------
  static const Color colorSuccess = Color(0xFF2ECC71);
  static const Color colorError = Color(0xFFFF6467); // (PDF)
  static const Color colorWarning = Color(0xFFF1C40F); // Fill/Secondary
  static const Color colorInfo = Color(0xFF00A6F4); // (PDF)
  static const Color warning300 = Color(0xFFFFDF20); // Warning/300
  static const Color warning500 = Color(0xFFF0B100); // Warning/500
  static const Color baseBlack = Color(0xFF000000); // Base/Black

  // --- Borders & dividers --------------------------------------------------
  static const Color borderDefault = Color(0xFF3F3F46); // Border/Default, Section/Base
  static const Color dotSeparator = Color(0xFF71717B);
  static const Color sectionOnBase = Color(0xFF52525C); // Section/On Base
  static const Color homeIndicator = Color(0xFF52525C); // Home Indicator

  // --- Input field (Figma: Input Field/*) ----------------------------------
  static const Color inputFieldFill = Color(0xFF27272A); // Input Field/Fill/Default
  static const Color inputFieldBorder = Color(0xFF52525C); // Input Field/Border/Default
  static const Color inputFieldLabel = Color(0xFFFFFFFF); // Input Field/Text/Label
  static const Color inputFieldData = Color(0xFFFFFFFF); // Input Field/Text/Data
  static const Color inputFieldPlaceholder = Color(0xFF9F9FA9); // Text/Placeholder
  static const Color inputFieldAddOnText = Color(0xFFD4D4D8); // Text/Add On
  static const Color inputFieldAddOnBorder = Color(0xFF52525C); // Border/Add On
  static const Color inputFieldDropdownIcon = Color(0xFF9F9FA9); // Icon/Dropdown

  // --- Radio list item (Figma: Radio/List Item/*) --------------------------
  static const Color radioFill = Color(0xFF18181B); // Radio/List Item/Fill
  static const Color radioTitle = Color(0xFFFFFFFF); // Text/Title
  static const Color radioDescription = Color(0xFF9F9FA9); // Text/Description
  static const Color radioIconChecked = Color(0xFF2ECC71); // Icon/Checked
  static const Color radioIconDefault = Color(0xFF71717B); // Icon/Default

  // --- Radio card (Figma: Radio/Card/* — glassmorphic interest chip) --------
  static const Color radioCardFill = Color(0x0FFFFFFF); // white @ ~6%
  static const Color radioCardBorder = Color(0x38FFFFFF); // white @ ~22%
  static const Color radioCardTitle = Color(0xFFFFFFFF); // Radio/Card/Title

  // --- Info / Alert ("How it works" box) -----------------------------------
  static const Color infoFillDark = Color(0xFF052F4A); // Fill/Info/Dark
  static const Color infoIconLight = Color(0xFFB8E6FE); // Icon/Info/Light
  static const Color infoTextLight = Color(0xFFB8E6FE); // Text/Info/Light
  static const Color warningFillDark = Color(0xFF3A2F03); // Fill/Warning/Dark
  static const Color warningTextLight = Color(0xFFFDF6D8); // Text/Warning/Light

  // --- Buttons -------------------------------------------------------------
  static const Color buttonPrimaryFill = Color(0xFF2ECC71); // Button/Primary/Solid/Default/Fill
  static const Color buttonPrimaryText = Color(0xFF06190E); // Button/Primary/Text & Icon
  static const Color buttonGrayFill = Color(0xFF3F3F46); // Button/Gray/Solid/Default/Fill
  static const Color buttonGrayText = Color(0xFFFFFFFF); // Button/Gray/Text

  // --- Chip & tag (PDF-sourced, no Figma var contradiction) ----------------
  static const Color chipsSelectedBorder = Color(0xFF26A65C);
  static const Color chipsSelectedFill = Color(0xFF0F4325);
  static const Color chipsDefaultBorder = Color(0xFF52525C);
  static const Color chipsDefaultText = Color(0xFFD4D4D8);
  static const Color tagInfoFill = Color(0xFFB8E6FE); // Icon/Text Info Light
  static const Color tagInfoText = Color(0xFF024A70);

  // --- Timeline / order-tracking status (PDF) ------------------------------
  static const Color statusCompletedBg = Color(0xFF092A17);
  static const Color statusCompletedIcon = Color(0xFF2ECC71);
  static const Color statusOngoingBg = Color(0xFF052F4A); // == Fill/Info/Dark
  static const Color statusOngoingIcon = Color(0xFF00A6F4);
  static const Color statusOngoingRipple1 = Color(0xFF00BCFF);
  static const Color statusOngoingRipple2 = Color(0xFF024A70);
  static const Color statusRemainingBg = Color(0xFF27272A);
  static const Color statusRemainingIcon = Color(0xFF9F9FA9);

  // ==========================================================================
  // TYPOGRAPHY  (Figma type styles — Poppins)
  // ==========================================================================

  static const String fontFamily = 'Poppins';

  /// Section Title - Large — 24 / 600 / 1.3
  static const TextStyle titleLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 24,
    fontWeight: FontWeight.w600,
    height: 1.3,
    color: textWhite,
  );

  /// Section Title - Medium — 22 / 600 / 1.3
  static const TextStyle titleMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 22,
    fontWeight: FontWeight.w600,
    height: 1.3,
    color: textWhite,
  );

  /// Section Inner Title — 18 / 600 / 1.3
  static const TextStyle sectionInnerTitle = TextStyle(
    fontFamily: fontFamily,
    fontSize: 18,
    fontWeight: FontWeight.w600,
    height: 1.3,
    color: textWhite,
  );

  /// One Liner - SemiBold — 16 / 600 / 1.0  (e.g. method-card title, button label)
  static const TextStyle oneLinerSemibold = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.0,
    color: textWhite,
  );

  /// One Liner - Regular — 16 / 400 / 1.0
  static const TextStyle oneLinerRegular = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.0,
    color: textWhite,
  );

  /// Body — 16 / 400 / 1.5  (subtitles, paragraphs)
  static const TextStyle bodyText = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.5,
    color: textLight,
  );

  /// Medium - Semibold — 14 / 600 / 1.3
  static const TextStyle mediumSemibold = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 1.3,
    color: textWhite,
  );

  /// Medium - Regular — 14 / 400 / 1.5
  static const TextStyle mediumRegular = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.5,
    color: textLight,
  );

  /// Small - Regular — 12 / 400 / 1.3
  static const TextStyle smallRegular = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.3,
    color: textMuted,
  );

  /// Small-Regular Description — 12 / 400 / 1.5  (method-card description)
  static const TextStyle smallDescription = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.5,
    color: textMuted,
  );

  // --- Backward-compat aliases (map old names to correct Figma styles) -----
  static const TextStyle h1 = titleLarge; // was 20px → corrected to 24px
  static const TextStyle h2 = titleMedium; // was 18px → corrected to 22px
  static const TextStyle h3 = sectionInnerTitle; // 18px
  static const TextStyle body = bodyText; // was 14px → corrected to 16px
  static const TextStyle small = smallRegular; // 12px
  static const TextStyle tiny = TextStyle(
    fontFamily: fontFamily,
    fontSize: 11,
    fontWeight: FontWeight.w400,
    height: 1.2,
    color: textMuted,
  );

  // Legacy numeric aliases (kept; some widgets reference these)
  static const double h1Size = 24;
  static const FontWeight h1Weight = FontWeight.w600;
  static const double h1LineHeight = 1.3;
  static const double h2Size = 22;
  static const FontWeight h2Weight = FontWeight.w600;
  static const double h2LineHeight = 1.3;
  static const double h3Size = 18;
  static const FontWeight h3Weight = FontWeight.w600;
  static const double h3LineHeight = 1.3;
  static const double bodySize = 16;
  static const FontWeight bodyWeight = FontWeight.w400;
  static const double bodyLineHeight = 1.5;
  static const double smallSize = 12;
  static const FontWeight smallWeight = FontWeight.w400;
  static const double smallLineHeight = 1.3;
  static const double tinySize = 11;
  static const FontWeight tinyWeight = FontWeight.w400;
  static const double tinyLineHeight = 1.2;

  // ==========================================================================
  // SPACING & LAYOUT  (Figma: S4=4, S8=8, S12=12)
  // ==========================================================================

  static const double s4 = 4;
  static const double s6 = 6;
  static const double s8 = 8;
  static const double s12 = 12;
  static const double s16 = 16;
  static const double s20 = 20;
  static const double s24 = 24;
  static const double s28 = 28;
  static const double s32 = 32;
  static const double s36 = 36;
  static const double s40 = 40;
  static const double s48 = 48;

  static const double appHorizontalPadding = s16;
  static const double appVerticalPadding = s24;

  // Component sizing (Figma: Border-Radius=999, Card-Radius=16)
  static const double cardRadius = 16;
  static const double buttonRadius = 999; // fully rounded
  static const double chipRadius = 32;
  static const double inputRadius = 8; // Figma input fields use 8px corners

  // Icon sizes
  static const double iconSmall = 16;
  static const double iconMedium = 24;
  static const double iconLarge = 32;
  static const double iconXLarge = 48;

  // Avatars
  static const double avatarSmall = 32;
  static const double avatarMedium = 40;
  static const double avatarLarge = 56;

  // Fixed component heights (from Figma frames)
  static const double buttonHeight = 48;
  static const double inputHeight = 48;

  // ==========================================================================
  // COMPONENT STYLES
  // ==========================================================================

  static ButtonStyle primaryButtonStyle({double? width, double? height}) {
    return ElevatedButton.styleFrom(
      backgroundColor: buttonPrimaryFill,
      foregroundColor: buttonPrimaryText,
      padding: const EdgeInsets.symmetric(horizontal: s32, vertical: s16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(buttonRadius),
      ),
      minimumSize: Size(width ?? 0, height ?? buttonHeight),
    );
  }

  static ButtonStyle outlinedButtonStyle() {
    return OutlinedButton.styleFrom(
      foregroundColor: textWhite,
      side: const BorderSide(color: borderDefault, width: 1),
      padding: const EdgeInsets.symmetric(horizontal: s16, vertical: s12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(buttonRadius),
      ),
      minimumSize: const Size(0, buttonHeight),
    );
  }

  static ButtonStyle textButtonStyle() {
    return TextButton.styleFrom(
      foregroundColor: primaryGreen,
      padding: const EdgeInsets.symmetric(horizontal: s16, vertical: s12),
    );
  }

  /// Input decoration matching Figma Input Field tokens (8px corners, #27272A
  /// fill, #52525C border default, #2ECC71 focused).
  static InputDecoration inputDecoration({
    String? labelText,
    String? hintText,
    Widget? prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: labelText,
      hintText: hintText,
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: inputFieldFill,
      contentPadding: const EdgeInsets.symmetric(horizontal: s12, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(inputRadius),
        borderSide: const BorderSide(color: inputFieldBorder, width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(inputRadius),
        borderSide: const BorderSide(color: inputFieldBorder, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(inputRadius),
        borderSide: const BorderSide(color: primaryGreen, width: 1.5),
      ),
      labelStyle: const TextStyle(
        color: inputFieldLabel,
        fontFamily: fontFamily,
        fontSize: 14,
      ),
      hintStyle: const TextStyle(
        color: inputFieldPlaceholder,
        fontFamily: fontFamily,
        fontSize: 14,
      ),
    );
  }

  static BoxDecoration cardDecoration({
    Color? backgroundColor,
    Color? borderColor,
    bool hasShadow = true,
  }) {
    return BoxDecoration(
      color: backgroundColor ?? bgAppBody,
      borderRadius: BorderRadius.circular(cardRadius),
      border:
          borderColor != null ? Border.all(color: borderColor, width: 1) : null,
      boxShadow: hasShadow
          ? [
              BoxShadow(
                color: const Color.fromARGB(255, 16, 16, 16).withOpacity(0.06),
                offset: const Offset(0, 4),
                blurRadius: 12,
                spreadRadius: 0,
              ),
            ]
          : null,
    );
  }

  static BoxDecoration chipDecorationSelected() {
    return BoxDecoration(
      color: chipsSelectedFill,
      borderRadius: BorderRadius.circular(chipRadius),
      border: Border.all(color: chipsSelectedBorder, width: 1),
    );
  }

  static BoxDecoration chipDecorationDefault() {
    return BoxDecoration(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(chipRadius),
      border: Border.all(color: chipsDefaultBorder, width: 1),
    );
  }

  static BoxDecoration tagDecoration({Color? backgroundColor, Color? borderColor}) {
    return BoxDecoration(
      color: backgroundColor ?? tagInfoFill,
      borderRadius: BorderRadius.circular(9999),
      border:
          borderColor != null ? Border.all(color: borderColor, width: 1) : null,
    );
  }
}
