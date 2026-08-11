import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../constants/app_images.dart';
import '../../widgets/custom_confirmation_dialog.dart';

class _SharedMediaMenuAction {
  final IconData icon;
  final String label;
  final Color? color;
  final VoidCallback onTap;

  const _SharedMediaMenuAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });
}

Future<void> showSharedMediaActionMenu({
  required BuildContext context,
  required Offset globalPosition,
  required bool isMe,
  required VoidCallback onShowInChat,
  required VoidCallback onConfirmedDelete,
  VoidCallback? onOpen,
  String openLabel = 'Open',
  IconData openIcon = Icons.open_in_full_rounded,
}) {
  HapticFeedback.mediumImpact();

  final overlay = Overlay.of(context, rootOverlay: true);
  final completer = Completer<void>();
  late OverlayEntry entry;

  void close() {
    if (entry.mounted) entry.remove();
    if (!completer.isCompleted) completer.complete();
  }

  void confirmAndDelete() {
    close();
    showDialog(
      context: context,
      builder:
          (dialogContext) => CustomConfirmationDialog(
            title:
                isMe
                    ? 'Delete this message for everyone?'
                    : 'Delete this message for you?',
            img: AppImages.deleteFilesAnimationLot,
            confirmBtnText: 'Delete',
            onConfirm: () {
              Navigator.of(dialogContext, rootNavigator: true).pop();
              onConfirmedDelete();
            },
          ),
    );
  }

  final actions = <_SharedMediaMenuAction>[
    _SharedMediaMenuAction(
      icon: Icons.forum_outlined,
      label: 'Show in chat',
      onTap: () {
        close();
        onShowInChat();
      },
    ),
    if (onOpen != null)
      _SharedMediaMenuAction(
        icon: openIcon,
        label: openLabel,
        onTap: () {
          close();
          onOpen();
        },
      ),
    _SharedMediaMenuAction(
      icon: isMe ? Icons.delete_forever_rounded : Icons.delete_outline_rounded,
      label: isMe ? 'Delete' : 'Delete from me',
      color: isMe ? Theme.of(context).colorScheme.error : null,
      onTap: confirmAndDelete,
    ),
  ];

  entry = OverlayEntry(
    builder:
        (context) => _SharedMediaActionMenuOverlay(
          anchor: globalPosition,
          actions: actions,
          onDismiss: close,
        ),
  );

  overlay.insert(entry);
  return completer.future;
}

class _SharedMediaActionMenuOverlay extends StatefulWidget {
  final Offset anchor;
  final List<_SharedMediaMenuAction> actions;
  final VoidCallback onDismiss;

  const _SharedMediaActionMenuOverlay({
    required this.anchor,
    required this.actions,
    required this.onDismiss,
  });

  @override
  State<_SharedMediaActionMenuOverlay> createState() =>
      _SharedMediaActionMenuOverlayState();
}

class _SharedMediaActionMenuOverlayState
    extends State<_SharedMediaActionMenuOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 220),
  );

  late final Animation<double> _scale = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOutBack,
  );

  late final Animation<double> _opacity = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0, 0.6, curve: Curves.easeOut),
  );

  @override
  void initState() {
    super.initState();
    _controller.forward();
  }

  Future<void> _dismiss() async {
    await _controller.reverse();
    widget.onDismiss();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.of(context).size;
    const menuWidth = 230.0;
    const verticalPadding = 16.0;
    final menuHeight = 48.0 * widget.actions.length + verticalPadding;

    double left = widget.anchor.dx - menuWidth / 2;
    left = left.clamp(12.0, screen.width - menuWidth - 12);

    double top = widget.anchor.dy + 12;
    if (top + menuHeight > screen.height - 24) {
      top = widget.anchor.dy - menuHeight - 12;
    }
    top = top.clamp(24.0, screen.height - menuHeight - 24);

    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            onTap: _dismiss,
            behavior: HitTestBehavior.opaque,
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 1.5, sigmaY: 1.5),
              child: Container(color: Colors.black.withValues(alpha: 0.12)),
            ),
          ),
        ),
        Positioned(
          left: left,
          top: top,
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Opacity(
                opacity: _opacity.value.clamp(0.0, 1.0),
                child: Transform.scale(
                  scale: _scale.value,
                  alignment: Alignment.topCenter,
                  child: child,
                ),
              );
            },
            child: Material(
              color: Colors.transparent,
              child: Container(
                width: menuWidth,
                decoration: BoxDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.25),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final action in widget.actions)
                      InkWell(
                        onTap: action.onTap,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          child: Row(
                            children: [
                              Icon(
                                action.icon,
                                size: 20,
                                color:
                                    action.color ??
                                    Theme.of(context).colorScheme.onSurface,
                              ),
                              const SizedBox(width: 14),
                              Text(
                                action.label,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                  color:
                                      action.color ??
                                      Theme.of(context).colorScheme.onSurface,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
