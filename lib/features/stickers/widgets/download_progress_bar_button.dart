import 'package:flutter/material.dart';

enum DownloadButtonStatus { idle, downloading, downloaded }

class DownloadProgressBarButton extends StatelessWidget {
  final DownloadButtonStatus status;
  final double progress;
  final VoidCallback onDownload;
  final VoidCallback onRemove;
  final double height;

  const DownloadProgressBarButton({
    super.key,
    required this.status,
    required this.progress,
    required this.onDownload,
    required this.onRemove,
    this.height = 36,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textColor = theme.colorScheme.onSurface.withValues(alpha: 0.85);
    if (status == DownloadButtonStatus.downloaded) {
      return SizedBox(
        width: double.infinity,
        height: height,
        child: FilledButton.tonal(
          onPressed: onRemove,
          style: FilledButton.styleFrom(
            backgroundColor: theme.colorScheme.errorContainer.withValues(
              alpha: 0.6,
            ),
            foregroundColor: theme.colorScheme.onErrorContainer,
            padding: EdgeInsets.zero,
          ),
          child: const Text(
            'Remove',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ),
      );
    }

    final isDownloading = status == DownloadButtonStatus.downloading;

    return SizedBox(
      width: double.infinity,
      height: height,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(height / 2),
        child: Material(
          color: theme.colorScheme.surfaceContainerHighest.withValues(
            alpha: 0.8,
          ),

          child: InkWell(
            onTap: isDownloading ? null : onDownload,
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Stack(
                  alignment: Alignment.centerLeft,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeOut,
                      width:
                          isDownloading
                              ? constraints.maxWidth * progress.clamp(0.04, 1.0)
                              : 0,
                      height: height,
                      color: theme.primaryColor,
                    ),

                    Center(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        child:
                            isDownloading
                                ? Text(
                                  '${(progress * 100).clamp(0, 100).toStringAsFixed(0)}%',
                                  key: const ValueKey('pct'),
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: textColor,
                                    shadows: [
                                      Shadow(
                                        color: Colors.black26,
                                        blurRadius: 2,
                                      ),
                                    ],
                                  ),
                                )
                                : Text(
                                  'Download',
                                  key: const ValueKey('idle'),
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: theme.primaryColor,
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
