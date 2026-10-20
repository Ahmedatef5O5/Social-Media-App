import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import '../../../core/widgets/custom_text_form_field.dart';
import 'tagline_form_field.dart';
import 'package:social_media_app/core/localization/l10n_extension.dart';

class EditProfileForm extends StatelessWidget {
  final TextEditingController nameController;
  final TextEditingController userNameController;
  final TextEditingController titleController;
  final TextEditingController bioController;
  final TextEditingController taglineController;
  final FocusNode taglineFocusNode;
  final bool isTaglineHidden;
  final ValueChanged<bool> onTaglineHiddenChanged;

  const EditProfileForm({
    super.key,
    required this.nameController,
    required this.userNameController,
    required this.titleController,
    required this.bioController,
    required this.taglineController,
    required this.taglineFocusNode,
    required this.isTaglineHidden,
    required this.onTaglineHiddenChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CustomTextFormField(
          controller: nameController,
          labelText: context.l10n.name,
          hintText: context.l10n.enterNewName,
          prefixIcon: Icon(Icons.person_outline_rounded),
        ),
        Gap(16),
        CustomTextFormField(
          controller: userNameController,
          labelText: context.l10n.username,
          hintText: context.l10n.enterNewUsername,
          prefixIcon: Icon(CupertinoIcons.person_alt_circle),
        ),
        Gap(16),
        CustomTextFormField(
          controller: titleController,
          labelText: context.l10n.title,
          hintText: context.l10n.enterNewTitle,
          prefixIcon: const Icon(Icons.badge_outlined),
        ),
        Gap(16),
        CustomTextFormField(
          controller: bioController,
          labelText: context.l10n.bio,
          hintText: context.l10n.enterNewBio,
          prefixIcon: const Icon(Icons.info_outline_rounded),
        ),
        Gap(16),
        TaglineFormField(
          controller: taglineController,
          focusNode: taglineFocusNode,
          isHidden: isTaglineHidden,
          onHiddenChanged: onTaglineHiddenChanged,
        ),
      ],
    );
  }
}
