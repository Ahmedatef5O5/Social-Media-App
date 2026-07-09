import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/story_reaction_cubit/story_reaction_cubit.dart';

const List<String> kStoryReactions = ['❤️', '😂', '😮', '😢', '👏', '🔥'];

class StoryReactionOverlay {
  static OverlayEntry create({
    required BuildContext context,
    required GlobalKey anchorKey,
    required GlobalKey<StoryReactionBubbleState> bubbleKey,
    required void Function(String emoji) onSelect,
    required VoidCallback onDismiss,
    String? selectedEmoji,
  }) {
    final renderBox =
        anchorKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) throw StateError('anchorKey has no render object');

    final overlayBox =
        Overlay.of(context).context.findRenderObject() as RenderBox;
    final offset = renderBox.localToGlobal(Offset.zero, ancestor: overlayBox);
    final anchorRect = offset & renderBox.size;

    const bubbleWidth = 46.0;
    final screenWidth = overlayBox.size.width;
    final screenHeight = overlayBox.size.height;

    const gap = 8.0;
    const bubbleHeight = 250.0;

    final left = anchorRect.center.dx - bubbleWidth / 2;

    final top = anchorRect.top - bubbleHeight - gap;

    return OverlayEntry(
      builder:
          (_) => Stack(
            children: [
              Positioned.fill(
                child: Listener(
                  onPointerDown: (_) => onDismiss(),
                  behavior: HitTestBehavior.opaque,
                  child: const SizedBox.expand(),
                ),
              ),
              Positioned(
                left: left.clamp(12.0, screenWidth - bubbleWidth - 12.0),
                top: top.clamp(
                  MediaQuery.paddingOf(context).top + 8,
                  screenHeight - bubbleHeight - 8,
                ),
                child: _StoryReactionBubble(
                  key: bubbleKey,
                  onSelect: onSelect,
                  selectedEmoji: selectedEmoji,
                ),
              ),
            ],
          ),
    );
  }
}

class _StoryReactionBubble extends StatefulWidget {
  final void Function(String) onSelect;
  final String? selectedEmoji;
  const _StoryReactionBubble({
    required key,
    required this.onSelect,
    this.selectedEmoji,
  });

  @override
  State<_StoryReactionBubble> createState() => StoryReactionBubbleState();
}

class StoryReactionBubbleState extends State<_StoryReactionBubble>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;
  late final Animation<double> _fade;
  int? _hovered;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _scale = CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut);
    _fade = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.0, 0.35, curve: Curves.easeOut),
    );
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> reverseAnimation() async {
    await _ctrl.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return FadeTransition(
      opacity: _fade,
      child: ScaleTransition(
        scale: _scale,
        alignment: Alignment.bottomCenter,
        child: PhysicalModel(
          color: Colors.transparent,
          elevation: 0,
          borderRadius: BorderRadius.circular(24),
          clipBehavior: Clip.none,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.78),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.15),
                width: 0.6,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.45),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(kStoryReactions.length, (i) {
                final emoji = kStoryReactions[i];
                final isSelected = widget.selectedEmoji == emoji;
                final isHov = _hovered == i;

                return MouseRegion(
                  onEnter: (_) => setState(() => _hovered = i),
                  onExit: (_) => setState(() => _hovered = null),
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.mediumImpact();
                      widget.onSelect(emoji);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 160),
                      curve: Curves.easeOut,
                      margin: const EdgeInsets.symmetric(vertical: 2),
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color:
                            isSelected
                                ? scheme.primary.withValues(alpha: 0.22)
                                : Colors.transparent,
                      ),
                      transform:
                          isSelected
                              ? (Matrix4.identity()..scale(1.3))
                              : isHov
                              ? (Matrix4.identity()
                                ..translate(-6.0, 0.0)
                                ..scale(1.15))
                              : Matrix4.identity(),
                      transformAlignment: Alignment.center,
                      child: Text(
                        emoji,
                        style: const TextStyle(
                          fontSize: 22,
                          decoration: TextDecoration.none,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

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
                        style: const TextStyle(
                          fontSize: 20,
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
