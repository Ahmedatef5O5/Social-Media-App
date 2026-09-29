import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gap/gap.dart';
import '../../../core/widgets/custom_text_form_field.dart';
import '../utils/grapheme_length_input_formatter.dart';
import '../utils/profile_ui_tokens.dart';

class TaglineFormField extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isHidden;
  final ValueChanged<bool> onHiddenChanged;
  final int maxLength;

  const TaglineFormField({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.isHidden,
    required this.onHiddenChanged,
    this.maxLength = 20,
  });

  @override
  State<TaglineFormField> createState() => _TaglineFormFieldState();
}

class _TaglineFormFieldState extends State<TaglineFormField> {
  late int _count = GraphemeLengthInputFormatter.countCharacters(
    widget.controller.text,
  );

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onChanged);
  }

  void _onChanged() {
    final next = GraphemeLengthInputFormatter.countCharacters(
      widget.controller.text,
    );
    if (next != _count) setState(() => _count = next);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onChanged);
    super.dispose();
  }

  void _toggleHidden() {
    HapticFeedback.selectionClick();
    widget.onHiddenChanged(!widget.isHidden);
  }

  @override
  Widget build(BuildContext context) {
    final isAtLimit = _count >= widget.maxLength;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        CustomTextFormField(
          controller: widget.controller,
          focusNode: widget.focusNode,
          labelText: 'Status',
          hintText: 'A short quote, mood or emoji statement',
          prefixIcon: const Icon(Icons.cloud_outlined),
          inputFormatters: [GraphemeLengthInputFormatter(widget.maxLength)],
          suffixIcon: _HiddenToggleButton(
            isHidden: widget.isHidden,
            onTap: _toggleHidden,
          ),
        ),
        const Gap(4),
        Padding(
          padding: const EdgeInsets.only(right: 4),
          child: Text(
            '$_count/${widget.maxLength}',
            style: TextStyle(
              fontSize: 12,
              fontWeight: isAtLimit ? FontWeight.w600 : FontWeight.w400,
              color:
                  isAtLimit
                      ? Theme.of(context).colorScheme.error
                      : Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),

        AnimatedSwitcher(
          duration: const Duration(milliseconds: 280),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          transitionBuilder: (child, animation) {
            return FadeTransition(
              opacity: animation,
              child: SizeTransition(
                sizeFactor: animation,
                axisAlignment: -1,
                child: child,
              ),
            );
          },
          child:
              widget.isHidden
                  ? const Padding(
                    key: ValueKey('tagline-hidden-notice'),
                    padding: EdgeInsets.only(top: 10),
                    child: _HiddenStatusNotice(),
                  )
                  : const SizedBox.shrink(
                    key: ValueKey('tagline-hidden-notice-empty'),
                  ),
        ),
      ],
    );
  }
}

class _HiddenToggleButton extends StatelessWidget {
  const _HiddenToggleButton({required this.isHidden, required this.onTap});

  final bool isHidden;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = ProfileUiTokens.of(context);

    return IconButton(
      onPressed: onTap,
      tooltip: isHidden ? 'Show on profile' : 'Hide from profile',
      icon: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        transitionBuilder:
            (child, animation) =>
                ScaleTransition(scale: animation, child: child),
        child: Icon(
          isHidden ? Icons.visibility_off_rounded : Icons.visibility_rounded,
          key: ValueKey(isHidden),
          color: isHidden ? tokens.primary : tokens.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _HiddenStatusNotice extends StatelessWidget {
  const _HiddenStatusNotice();

  @override
  Widget build(BuildContext context) {
    final tokens = ProfileUiTokens.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: tokens.primaryTonal,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: tokens.primary.withValues(alpha: tokens.isDark ? 0.30 : 0.18),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.visibility_off_outlined, size: 18, color: tokens.primary),
          const Gap(8),
          Expanded(
            child: Text(
              'Your status will be hidden from your profile until you '
              'switch this back on.',
              style: TextStyle(
                fontSize: 12.5,
                height: 1.35,
                fontWeight: FontWeight.w500,
                color: tokens.onSurface.withValues(alpha: 0.82),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
