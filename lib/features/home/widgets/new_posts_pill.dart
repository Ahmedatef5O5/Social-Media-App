import 'package:flutter/material.dart';

class NewPostsPill extends StatelessWidget {
  final int count;
  final VoidCallback onTap;

  const NewPostsPill({super.key, required this.count, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final bool isVisible = count > 0;

    return IgnorePointer(
      ignoring: !isVisible,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: isVisible ? 1 : 0,
        child: AnimatedSlide(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
          offset: isVisible ? Offset.zero : const Offset(0, -0.6),
          child: Material(
            color: Theme.of(context).primaryColor,
            elevation: 4,
            borderRadius: BorderRadius.circular(30),
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(30),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.arrow_upward_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '$count New ${count == 1 ? 'Post' : 'Posts'}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
