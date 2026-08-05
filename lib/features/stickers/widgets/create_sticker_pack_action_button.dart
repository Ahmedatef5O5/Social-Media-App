import 'package:flutter/material.dart';

class CreateStickerPackActionButton extends StatelessWidget {
  final bool isUploading;
  final double progress;
  final bool canSubmit;
  final VoidCallback onSubmit;

  const CreateStickerPackActionButton({
    super.key,
    required this.isUploading,
    this.progress = 0.0,
    required this.canSubmit,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Material(
          color:
              (canSubmit || isUploading)
                  ? theme.primaryColor.withValues(alpha: 0.15)
                  : theme.colorScheme.surfaceContainerHighest,
          child: InkWell(
            onTap: (!isUploading && canSubmit) ? onSubmit : null,
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Stack(
                  alignment: Alignment.centerLeft,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeOut,
                      width:
                          isUploading
                              ? constraints.maxWidth * progress.clamp(0.04, 1.0)
                              : 0,
                      height: 56,
                      color: theme.primaryColor,
                    ),
                    Center(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        child:
                            isUploading
                                ? Text(
                                  '${(progress * 100).clamp(0, 100).toStringAsFixed(0)}%',
                                  key: const ValueKey('progress'),
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: theme.colorScheme.onSurface
                                        .withValues(alpha: 0.85),
                                    shadows: [
                                      Shadow(
                                        color: Colors.black26,
                                        blurRadius: 2,
                                      ),
                                    ],
                                  ),
                                )
                                : Text(
                                  'Create Pack',
                                  key: const ValueKey('idle'),
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color:
                                        canSubmit
                                            ? theme.primaryColor
                                            : theme.disabledColor,
                                  ),
                                ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
