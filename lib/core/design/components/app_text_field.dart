import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:social_media_app/core/design/theme/theme_extensions.dart';
import 'package:social_media_app/core/design/tokens/dimensions.dart';
import 'package:social_media_app/core/design/tokens/radii.dart';
import 'package:social_media_app/core/design/tokens/spacing.dart';
import 'package:social_media_app/core/helpers/emoji_text_input_formatter.dart';

class AppTextField extends StatefulWidget {
  final String? hintText;
  final String? labelText;
  final String? headerText;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final bool isPassword;
  final bool isSearch;
  final bool isBorderless;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final FocusNode? focusNode;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onEditingComplete;
  final int maxLines;
  final int? minLines;
  final bool readOnly;
  final VoidCallback? onTap;

  const AppTextField({
    super.key,
    this.hintText,
    this.labelText,
    this.headerText,
    this.controller,
    this.validator,
    this.isPassword = false,
    this.isSearch = false,
    this.isBorderless = false,
    this.keyboardType,
    this.inputFormatters,
    this.prefixIcon,
    this.suffixIcon,
    this.focusNode,
    this.onChanged,
    this.onEditingComplete,
    this.maxLines = 1,
    this.minLines,
    this.readOnly = false,
    this.onTap,
  });

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  late bool _obscureText;
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _obscureText = widget.isPassword;
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(_onFocusChange);
  }

  void _onFocusChange() => setState(() {});

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    if (widget.focusNode == null) _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final isSearch = widget.isSearch;
    final isBorderless = widget.isBorderless;

    final InputBorder border =
        isBorderless
            ? InputBorder.none
            : OutlineInputBorder(
              borderRadius: isSearch ? AppRadii.radiusFull : AppRadii.radiusMd,
              borderSide: BorderSide(
                color: isSearch ? Colors.transparent : palette.outline,
                width: AppDimensions.borderWidthDefault,
              ),
            );

    final InputBorder focusedBorder =
        isBorderless
            ? InputBorder.none
            : OutlineInputBorder(
              borderRadius: isSearch ? AppRadii.radiusFull : AppRadii.radiusMd,
              borderSide: BorderSide(
                color: palette.primary,
                width: AppDimensions.borderWidthFocused,
              ),
            );

    Widget? defaultPrefix = widget.prefixIcon;
    if (isSearch && defaultPrefix == null) {
      defaultPrefix = Icon(
        Icons.search_rounded,
        size: AppDimensions.iconMedium,
        color: palette.onSurfaceVariant,
      );
    }

    Widget? defaultSuffix = widget.suffixIcon;
    if (widget.isPassword) {
      defaultSuffix = IconButton(
        icon: Icon(
          _obscureText
              ? Icons.visibility_off_outlined
              : Icons.visibility_outlined,
          color: palette.onSurfaceVariant,
          size: AppDimensions.iconMedium,
        ),
        onPressed: () => setState(() => _obscureText = !_obscureText),
      );
    }

    Color? fillColor;
    if (isBorderless) {
      fillColor = Colors.transparent;
    } else if (isSearch) {
      fillColor = palette.surfaceVariant;
    } else {
      fillColor = palette.surface;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.headerText != null) ...[
          Text(
            widget.headerText!,
            style: (context.typography.titleSmall ?? const TextStyle())
                .copyWith(
                  fontWeight: FontWeight.w600,
                  color: palette.onSurface,
                ),
          ),
          const SizedBox(height: AppSpacing.space4),
        ],
        TextFormField(
          focusNode: _focusNode,
          controller: widget.controller,
          validator: widget.validator,
          obscureText: _obscureText,
          keyboardType: widget.keyboardType,
          inputFormatters: [
            if (widget.inputFormatters != null) ...widget.inputFormatters!,
            EmojiTextInputFormatter(),
          ],
          onChanged: widget.onChanged,
          onEditingComplete: widget.onEditingComplete,
          maxLines: widget.maxLines,
          minLines: widget.minLines,
          readOnly: widget.readOnly,
          onTap: widget.onTap,
          cursorColor: palette.primary,
          style: (context.typography.bodyLarge ?? const TextStyle()).copyWith(
            color: palette.onSurface,
          ),
          decoration: InputDecoration(
            isDense: true,
            hintText: widget.hintText,
            hintStyle: (context.typography.bodyMedium ?? const TextStyle())
                .copyWith(
                  color: palette.onSurfaceVariant.withValues(alpha: 0.6),
                  fontWeight: FontWeight.w400,
                ),

            labelText: widget.labelText,
            fillColor: fillColor,
            filled: !isBorderless,
            contentPadding: EdgeInsets.symmetric(
              horizontal: isBorderless ? AppSpacing.space2 : AppSpacing.space6,
              vertical: isSearch ? AppSpacing.space4 : AppSpacing.space5,
            ),
            prefixIcon: defaultPrefix,
            suffixIcon: defaultSuffix,
            border: border,
            enabledBorder: border,
            focusedBorder: focusedBorder,
            errorBorder: isBorderless ? InputBorder.none : null,
          ),
        ),
      ],
    );
  }
}
