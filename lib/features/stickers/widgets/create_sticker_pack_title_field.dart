import 'package:flutter/material.dart';
import '../cubits/create_sticker_pack_cubit/create_sticker_pack_cubit.dart';
import 'package:social_media_app/core/localization/l10n_extension.dart';

class CreateStickerPackTitleField extends StatelessWidget {
  final CreateStickerPackCubit cubit;
  final ThemeData theme;

  const CreateStickerPackTitleField({
    super.key,
    required this.cubit,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      onChanged: cubit.setTitle,
      decoration: InputDecoration(
        labelText: context.l10n.packName,
        hintText: context.l10n.nameYourPack,
        hintStyle: TextStyle(
          color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
          fontWeight: FontWeight.w400,
          fontSize: 15,
        ),
        filled: true,
        fillColor: theme.colorScheme.surfaceContainerHighest.withValues(
          alpha: 0.3,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: theme.primaryColor, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 18,
        ),
      ),
    );
  }
}
