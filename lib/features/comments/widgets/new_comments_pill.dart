import 'package:flutter/material.dart';
import '../../../core/constants/app_images.dart';
import '../../../core/widgets/custom_badge.dart';

class NewCommentsPill extends StatefulWidget {
  final int count;
  final VoidCallback onTap;

  const NewCommentsPill({super.key, required this.count, required this.onTap});

  @override
  State<NewCommentsPill> createState() => _NewCommentsPillState();
}

class _NewCommentsPillState extends State<NewCommentsPill> {
  int _displayCount = 0;

  @override
  void initState() {
    super.initState();
    _displayCount = widget.count;
  }

  @override
  void didUpdateWidget(covariant NewCommentsPill oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.count > 0) {
      _displayCount = widget.count;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isVisible = widget.count > 0;
    final primaryColor = Theme.of(context).primaryColor;

    return IgnorePointer(
      ignoring: !isVisible,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: isVisible ? 1 : 0,

        child: AnimatedSlide(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          offset: isVisible ? Offset.zero : const Offset(0, 0.8),
          child: Theme(
            data: Theme.of(
              context,
            ).copyWith(primaryColor: const Color(0xFFE53935)),
            child: CustomBadge(
              count: _displayCount,
              top: -8,
              right: -8,
              size: 18,
              border: Border.all(
                color: Theme.of(context).scaffoldBackgroundColor,
                width: 1.8,
              ),
              child: Material(
                color: primaryColor.withValues(alpha: 0.85),
                elevation: 6,
                shape: const CircleBorder(),
                shadowColor: primaryColor.withValues(alpha: 0.4),
                child: InkWell(
                  onTap: widget.onTap,
                  customBorder: const CircleBorder(),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Image.asset(
                      AppImages.newCommentIcon,
                      width: 20,
                      height: 20,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
