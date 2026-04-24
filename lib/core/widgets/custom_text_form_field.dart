import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gap/gap.dart';
import '../themes/app_colors.dart';

class CustomTextFormField extends StatefulWidget {
  const CustomTextFormField({
    super.key,
    this.hintText,
    this.headerText,
    this.controller,
    this.validator,
    this.isPassword = false,
    this.keyboardType,
    this.inputFormatters,
    this.suffixIcon,
    this.prefixIcon,
    this.labelText,
    this.focusNode,
  });
  final String? hintText, labelText, headerText;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final bool isPassword;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final Widget? suffixIcon;
  final Widget? prefixIcon;
  final FocusNode? focusNode;

  @override
  State<CustomTextFormField> createState() => _CustomTextFormFieldState();
}

class _CustomTextFormFieldState extends State<CustomTextFormField> {
  late bool _obscureText;
  late FocusNode _effectiveFocusNode;

  @override
  void initState() {
    super.initState();
    _obscureText = widget.isPassword;
    _effectiveFocusNode = widget.focusNode ?? FocusNode();
    _effectiveFocusNode.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    setState(() {});
  }

  @override
  void dispose() {
    _effectiveFocusNode.removeListener(_onFocusChange);
    if (widget.focusNode == null) {
      _effectiveFocusNode.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final borderStyle = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: AppColors.blueGrey3, width: 0.18),
    );
    return Column(
      children: [
        if (widget.headerText != null) ...[
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              widget.headerText!,
              style: Theme.of(
                context,
              ).textTheme.headlineSmall!.copyWith(fontSize: 16),
            ),
          ),
          Gap(12),
        ],
        TextFormField(
          focusNode: _effectiveFocusNode,
          controller: widget.controller,
          validator: widget.validator,
          obscureText: _obscureText,
          keyboardType: widget.keyboardType,
          inputFormatters: widget.inputFormatters,
          cursorColor: Theme.of(context).primaryColor,
          cursorHeight: 18.5,
          decoration: InputDecoration(
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            labelText: widget.labelText,
            floatingLabelBehavior: FloatingLabelBehavior.always,
            floatingLabelStyle: Theme.of(
              context,
            ).textTheme.titleSmall!.copyWith(
              color:
                  _effectiveFocusNode.hasFocus
                      ? Theme.of(context).primaryColor
                      : null,
              // : AppColors.black87,
              fontSize: 15,
              fontWeight: FontWeight.w400,
            ),

            hintText: widget.hintText,
            hintStyle: Theme.of(context).textTheme.titleSmall!.copyWith(
              fontSize: 15,
              fontWeight: FontWeight.w300,
            ),
            prefixIcon:
                widget.isPassword && widget.prefixIcon != null
                    ? Icon(
                      _obscureText
                          ? Icons.lock_rounded
                          : Icons.lock_open_rounded,
                      color:
                          widget.prefixIcon is Icon
                              ? (widget.prefixIcon as Icon).color
                              : null,
                      size:
                          widget.prefixIcon is Icon
                              ? (widget.prefixIcon as Icon).size
                              : null,
                    )
                    : widget.prefixIcon,
            prefixIconColor:
                _effectiveFocusNode.hasFocus
                    ? Theme.of(context).primaryColor.withValues(alpha: 0.6)
                    : Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.5),
            suffixIcon:
                widget.isPassword
                    ? IconButton(
                      icon: Icon(
                        _obscureText ? Icons.visibility_off : Icons.visibility,
                        color:
                            _effectiveFocusNode.hasFocus || !_obscureText
                                ? Theme.of(
                                  context,
                                ).primaryColor.withValues(alpha: 0.6)
                                : Theme.of(
                                  context,
                                ).colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                      onPressed: () {
                        setState(() {
                          _obscureText = !_obscureText;
                        });
                      },
                    )
                    : null,
            border: borderStyle,
            enabledBorder: borderStyle,
            focusedBorder: borderStyle.copyWith(
              borderSide: BorderSide(
                color: Theme.of(context).primaryColor,
                width: 2,
              ),
            ),
            errorBorder: borderStyle,
            errorStyle: Theme.of(context).textTheme.titleSmall!.copyWith(
              color: Colors.red,
              fontSize: 15,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
      ],
    );
  }
}
