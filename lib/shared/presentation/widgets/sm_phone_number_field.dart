import 'package:country_picker/country_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// Phone number input with country picker — matches Figma
/// "Normal Input Field" (`9688:24331`): static label above, #27272A fill,
/// #52525C border (green when focused), 8px radius, and an add-on group of
/// [flag] [dial code] | [number].
class SmPhoneNumberField extends StatefulWidget {
  final TextEditingController controller;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;
  final ValueChanged<Country>? onCountryChanged;
  final String? labelText;
  final String hintText;
  final bool enabled;
  final bool readOnly;
  final Country? initialCountry;

  const SmPhoneNumberField({
    Key? key,
    required this.controller,
    this.validator,
    this.onChanged,
    this.onCountryChanged,
    this.labelText = 'Phone Number',
    this.hintText = 'XXXXXXXXXX',
    this.enabled = true,
    this.readOnly = false,
    this.initialCountry,
  }) : super(key: key);

  @override
  State<SmPhoneNumberField> createState() => SmPhoneNumberFieldState();
}

class SmPhoneNumberFieldState extends State<SmPhoneNumberField> {
  late Country _selectedCountry;
  final FocusNode _focusNode = FocusNode();
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _selectedCountry = widget.initialCountry ?? CountryParser.parseCountryCode('NP');
    _focusNode.addListener(() {
      if (mounted) setState(() => _focused = _focusNode.hasFocus);
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _showCountryPicker() {
    if (!widget.enabled || widget.readOnly) return;

    showCountryPicker(
      context: context,
      showPhoneCode: true,
      onSelect: (Country country) {
        setState(() => _selectedCountry = country);
        widget.onCountryChanged?.call(country);
      },
      countryListTheme: CountryListThemeData(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(40),
          topRight: Radius.circular(40),
        ),
        backgroundColor: DesignTokens.bgAppFoundation,
        textStyle: DesignTokens.mediumRegular
            .copyWith(color: DesignTokens.textWhite),
        searchTextStyle: DesignTokens.mediumRegular
            .copyWith(color: DesignTokens.textWhite),
        inputDecoration: InputDecoration(
          labelText: 'Search country',
          labelStyle: DesignTokens.mediumRegular
              .copyWith(color: DesignTokens.textLight),
          prefixIcon: const Icon(Icons.search, color: DesignTokens.iconLight),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(DesignTokens.inputRadius),
            borderSide: const BorderSide(color: DesignTokens.inputFieldBorder),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(DesignTokens.inputRadius),
            borderSide: const BorderSide(color: DesignTokens.inputFieldBorder),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(DesignTokens.inputRadius),
            borderSide: const BorderSide(
              color: DesignTokens.primaryGreen,
              width: 2,
            ),
          ),
          fillColor: DesignTokens.bgAppBodyLight,
          filled: true,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: DesignTokens.s16,
            vertical: DesignTokens.s12,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.labelText != null) ...[
          Text(
            widget.labelText!,
            style: DesignTokens.mediumRegular
                .copyWith(color: DesignTokens.inputFieldLabel),
          ),
          const SizedBox(height: DesignTokens.s4),
        ],
        TextField(
          controller: widget.controller,
          focusNode: _focusNode,
          enabled: widget.enabled && !widget.readOnly,
          readOnly: widget.readOnly,
          keyboardType: TextInputType.phone,
          onChanged: widget.onChanged,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(10),
          ],
          style: const TextStyle(
            fontFamily: DesignTokens.fontFamily,
            fontSize: 14,
            height: 1.5,
            color: DesignTokens.inputFieldData,
          ),
          cursorColor: DesignTokens.primaryGreen,
          decoration: InputDecoration(
            prefixIcon: GestureDetector(
              onTap: _showCountryPicker,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: DesignTokens.s8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _selectedCountry.flagEmoji,
                      style: const TextStyle(fontSize: 20),
                    ),
                    const SizedBox(width: DesignTokens.s4),
                    const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: DesignTokens.iconSmall,
                      color: DesignTokens.inputFieldDropdownIcon,
                    ),
                    const SizedBox(width: DesignTokens.s4),
                    Text(
                      _selectedCountry.phoneCode,
                      style: DesignTokens.mediumRegular
                          .copyWith(color: DesignTokens.inputFieldAddOnText),
                    ),
                    Container(
                      width: 1,
                      height: 20,
                      margin: const EdgeInsets.symmetric(horizontal: DesignTokens.s8),
                      color: DesignTokens.inputFieldAddOnBorder,
                    ),
                  ],
                ),
              ),
            ),
            hintText: widget.hintText,
            hintStyle: const TextStyle(
              fontFamily: DesignTokens.fontFamily,
              fontSize: 14,
              height: 1.5,
              color: DesignTokens.inputFieldPlaceholder,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(DesignTokens.inputRadius),
              borderSide: const BorderSide(color: DesignTokens.inputFieldBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(DesignTokens.inputRadius),
              borderSide: const BorderSide(color: DesignTokens.inputFieldBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(DesignTokens.inputRadius),
              borderSide: const BorderSide(
                color: DesignTokens.primaryGreen,
                width: 1.5,
              ),
            ),
            // Spec: 14px vertical padding → ~48px field height.
            contentPadding: const EdgeInsets.symmetric(
              horizontal: DesignTokens.s12,
              vertical: 14,
            ),
            fillColor: DesignTokens.inputFieldFill,
            filled: true,
            isDense: true,
          ),
        ),
      ],
    );
  }

  /// Full phone number including country code (e.g. +977XXXXXXXXXX).
  String getFullPhoneNumber() =>
      '+${_selectedCountry.phoneCode}${widget.controller.text}';

  Country getSelectedCountry() => _selectedCountry;
}
