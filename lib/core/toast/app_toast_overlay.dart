import 'dart:async';
import 'package:flutter/material.dart';
import 'app_toast.dart';
import 'app_toast_request.dart';
import 'app_toast_type.dart';

class AppToastOverlay extends StatefulWidget {
  const AppToastOverlay({super.key});

  @override
  State<AppToastOverlay> createState() => _AppToastOverlayState();
}

class _AppToastOverlayState extends State<AppToastOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _slide;
  late final Animation<double> _fade;

  AppToastRequest? _current;
  Timer? _hideTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.4),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);

    AppToast.requestNotifier.addListener(_onNewRequest);
  }

  Future<void> _onNewRequest() async {
    final request = AppToast.requestNotifier.value;
    if (request == null) return;

    _hideTimer?.cancel();
    if (_current != null) await _controller.reverse();
    if (!mounted) return;

    setState(() => _current = request);
    await _controller.forward(from: 0);

    _hideTimer = Timer(request.duration, _dismiss);
  }

  Future<void> _dismiss() async {
    _hideTimer?.cancel();
    if (!mounted || _current == null) return;
    await _controller.reverse();
    if (mounted) setState(() => _current = null);
  }

  @override
  void dispose() {
    AppToast.requestNotifier.removeListener(_onNewRequest);
    _hideTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_current == null) return const SizedBox.shrink();

    return Positioned(
      left: 16,
      right: 16,
      bottom: 24,
      child: SafeArea(
        top: false,
        child: SlideTransition(
          position: _slide,
          child: FadeTransition(
            opacity: _fade,
            child: Dismissible(
              key: ValueKey(_current!.id),
              direction: DismissDirection.down,
              onDismissed: (_) => _dismiss(),
              child: _ToastCard(request: _current!, onDismiss: _dismiss),
            ),
          ),
        ),
      ),
    );
  }
}

class _ToastCard extends StatelessWidget {
  const _ToastCard({required this.request, required this.onDismiss});

  final AppToastRequest request;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final type = request.type;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1C1C1E) : theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
          border: Border.all(
            color: type.color.withValues(alpha: isDark ? 0.2 : 0.15),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: (request.iconColor ?? request.type.color).withValues(
                  alpha: 0.18,
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                request.icon ?? request.type.icon,
                color: request.iconColor ?? request.type.color,
                size: 19,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                request.message,
                style: TextStyle(
                  color:
                      theme.textTheme.bodyLarge?.color ??
                      (isDark ? Colors.white : Colors.black87),
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  height: 1.3,
                ),
              ),
            ),
            const SizedBox(width: 8),
            if (request.actionLabel != null)
              GestureDetector(
                onTap: () {
                  request.onAction?.call();
                  onDismiss();
                },
                child: Text(
                  request.actionLabel!,
                  style: TextStyle(
                    color: type.color,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              )
            else
              GestureDetector(
                onTap: onDismiss,
                child: Icon(
                  Icons.close_rounded,
                  size: 16,
                  color:
                      theme.textTheme.bodyMedium?.color?.withValues(
                        alpha: 0.6,
                      ) ??
                      (isDark ? Colors.white54 : Colors.black54),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
