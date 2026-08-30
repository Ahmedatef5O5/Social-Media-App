import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/design/tokens/typography.dart';
import '../cubits/story_reaction_cubit/story_reaction_cubit.dart';
import '../widgets/story_reaction_picker.dart';

class StoryReactionButton extends StatefulWidget {
  final VoidCallback? onOpen;
  final VoidCallback? onClose;

  const StoryReactionButton({super.key, this.onOpen, this.onClose});

  @override
  State<StoryReactionButton> createState() => _StoryReactionButtonState();
}

class _StoryReactionButtonState extends State<StoryReactionButton> {
  final _anchorKey = GlobalKey();
  final GlobalKey<StoryReactionBubbleState> _bubbleKey = GlobalKey();
  OverlayEntry? _overlayEntry;
  bool _isOpen = false;

  void _openPicker(StoryReactionCubit cubit, String? current) {
    if (_isOpen) return;
    HapticFeedback.selectionClick();

    widget.onOpen?.call();
    setState(() => _isOpen = true);

    _overlayEntry = StoryReactionOverlay.create(
      context: context,
      anchorKey: _anchorKey,
      bubbleKey: _bubbleKey,
      selectedEmoji: current,
      onSelect: (emoji) {
        cubit.toggleReaction(emoji);
        _closePicker();
      },
      onDismiss: _closePicker,
    );
    Overlay.of(context, rootOverlay: true).insert(_overlayEntry!);
  }

  Future<void> _closePicker() async {
    if (!_isOpen) return;

    setState(() => _isOpen = false);
    widget.onClose?.call();

    if (_bubbleKey.currentState != null) {
      await _bubbleKey.currentState!.reverseAnimation();
    }

    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  @override
  void dispose() {
    _overlayEntry?.remove();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<StoryReactionCubit>();

    return BlocBuilder<StoryReactionCubit, StoryReactionState>(
      builder: (context, state) {
        final active = state.myReaction;

        return GestureDetector(
          key: _anchorKey,
          onTap: () {
            if (_isOpen) {
              _closePicker();
              return;
            }

            if (active != null) {
              HapticFeedback.lightImpact();
              cubit.toggleReaction(active);
            } else {
              _openPicker(cubit, active);
            }
          },
          onLongPress: () {
            if (!_isOpen) _openPicker(cubit, active);
          },
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            transitionBuilder:
                (child, anim) => ScaleTransition(scale: anim, child: child),
            child: Container(
              key: ValueKey('$_isOpen${active ?? 'default'}'),
              width: 48,
              height: 48,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color:
                    active != null
                        ? Theme.of(context).primaryColor.withValues(alpha: 0.22)
                        : Colors.white.withValues(alpha: _isOpen ? 0.25 : 0.15),
                border: Border.all(
                  color:
                      active != null
                          ? Theme.of(context).primaryColor
                          : Colors.white.withValues(alpha: 0.4),
                  width: 1.4,
                ),
              ),
              child:
                  active != null
                      ? Text(
                        active,
                        style: TextStyle(
                          fontSize: 20,
                          inherit: false,
                          fontFamilyFallback: AppTypography.emojiFontFallback,
                          decoration: TextDecoration.none,
                        ),
                      )
                      : Icon(
                        _isOpen
                            ? Icons.close_rounded
                            : Icons.add_reaction_outlined,
                        color: Colors.white,
                        size: _isOpen ? 24 : 22,
                      ),
            ),
          ),
        );
      },
    );
  }
}
