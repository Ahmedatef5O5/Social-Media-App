import 'package:flutter/material.dart';
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
    this.suffixIcon,
    this.prefixIcon,
    this.labelText,
  });
  final String? hintText, labelText, headerText;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final bool isPassword;
  final TextInputType? keyboardType;

  final Widget? suffixIcon;
  final Widget? prefixIcon;

  @override
  State<CustomTextFormField> createState() => _CustomTextFormFieldState();
}

class _CustomTextFormFieldState extends State<CustomTextFormField> {
  late bool _obscureText;

  @override
  void initState() {
    super.initState();
    _obscureText = widget.isPassword;
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
          controller: widget.controller,
          validator: widget.validator,
          obscureText: _obscureText,
          keyboardType: widget.keyboardType,
          decoration: InputDecoration(
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            // filled: true,
            // fillColor: Colors.grey.shade300,
            floatingLabelBehavior: FloatingLabelBehavior.always,
            labelText: widget.labelText,
            labelStyle: Theme.of(context).textTheme.titleSmall!.copyWith(
              color: AppColors.black87,
              fontSize: 15,
              fontWeight: FontWeight.w400,
            ),
            hintText: widget.hintText,
            hintStyle: Theme.of(context).textTheme.titleSmall!.copyWith(
              color: AppColors.black26,
              fontSize: 15,
              fontWeight: FontWeight.w300,
            ),
            prefixIcon: widget.prefixIcon,

            suffixIcon:
                widget.isPassword
                    ? IconButton(
                      icon: Icon(
                        _obscureText ? Icons.visibility_off : Icons.visibility,
                        color: AppColors.black26,
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
