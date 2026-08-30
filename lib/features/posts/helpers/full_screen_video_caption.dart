import 'package:flutter/material.dart';
import '../../../core/helpers/chat_helper.dart';

class FullScreenVideoCaption extends StatefulWidget {
  final String text;
  const FullScreenVideoCaption({super.key, required this.text});

  @override
  State<FullScreenVideoCaption> createState() => _FullScreenVideoCaptionState();
}

class _FullScreenVideoCaptionState extends State<FullScreenVideoCaption> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final direction = ChatHelper.getTextDirection(widget.text);
    final bool isRtl = direction == TextDirection.rtl;

    return GestureDetector(
      onTap: () {
        setState(() {
          _isExpanded = !_isExpanded;
        });
      },
      child: Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Directionality(
          textDirection: direction,
          child: SizedBox(
            width: double.infinity,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.text,
                  maxLines: _isExpanded ? null : 2,
                  overflow:
                      _isExpanded
                          ? TextOverflow.visible
                          : TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13.5,
                    shadows: [Shadow(blurRadius: 6, color: Colors.black87)],
                  ),
                ),
                if (!_isExpanded && widget.text.length > 60)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      isRtl ? 'قراءة المزيد...' : 'Read more...',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
