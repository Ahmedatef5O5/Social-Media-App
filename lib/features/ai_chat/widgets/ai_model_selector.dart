import 'dart:ui';
import 'package:flutter/material.dart';
import '../models/ai_model_option.dart';

/// Compact glass "pill" that shows the active model and opens a bottom
/// sheet to switch between them. Sits above the composer text field.
class AiModelSelector extends StatelessWidget {
  final AiModelOption selected;
  final ValueChanged<AiModelOption> onChanged;

  const AiModelSelector({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  static Future<void> openPicker(
    BuildContext context, {
    required AiModelOption selected,
    required ValueChanged<AiModelOption> onChanged,
  }) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder:
          (_) => _AiModelPickerSheet(selected: selected, onChanged: onChanged),
    );
  }

  void _openPicker(BuildContext context) {
    openPicker(context, selected: selected, onChanged: onChanged);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _openPicker(context),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(100),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(100),
              border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(selected.icon, size: 15, color: selected.accentColor),
                const SizedBox(width: 6),
                Text(
                  selected.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 12.5,
                    letterSpacing: -0.1,
                  ),
                ),
                const SizedBox(width: 2),
                const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 16,
                  color: Colors.white70,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AiModelPickerSheet extends StatelessWidget {
  final AiModelOption selected;
  final ValueChanged<AiModelOption> onChanged;

  const _AiModelPickerSheet({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
          decoration: BoxDecoration(
            color: const Color(0xFF15161C).withValues(alpha: 0.92),
            border: Border(
              top: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const Text(
                  'Choose a model',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 12),
                ...AiModelCatalog.all.map(
                  (model) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _ModelTile(
                      model: model,
                      isSelected: model.provider == selected.provider,
                      onTap: () {
                        onChanged(model);
                        Navigator.pop(context);
                      },
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

class _ModelTile extends StatelessWidget {
  final AiModelOption model;
  final bool isSelected;
  final VoidCallback onTap;

  const _ModelTile({
    required this.model,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color:
              isSelected
                  ? model.accentColor.withValues(alpha: 0.14)
                  : Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color:
                isSelected
                    ? model.accentColor.withValues(alpha: 0.5)
                    : Colors.white.withValues(alpha: 0.08),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: model.accentColor.withValues(alpha: 0.18),
              ),
              child: Icon(model.icon, color: model.accentColor, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    model.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 14.5,
                      letterSpacing: -0.1,
                    ),
                  ),
                  Text(
                    model.tagline,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle_rounded,
                color: model.accentColor,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }
}
