import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import '../../../core/widgets/custom_text_form_field.dart';
import 'tagline_form_field.dart';

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
          labelText: 'Name',
          hintText: 'Enter New Name',
          prefixIcon: Icon(Icons.person_outline_rounded),
        ),
        Gap(16),
        CustomTextFormField(
          controller: userNameController,
          labelText: 'UserName',
          hintText: 'Enter New UserName',
          prefixIcon: Icon(CupertinoIcons.person_alt_circle),
        ),
        Gap(16),
        CustomTextFormField(
          controller: titleController,
          labelText: 'Title',
          hintText: 'Enter New Title',
          prefixIcon: const Icon(Icons.badge_outlined),
        ),
        Gap(16),
        CustomTextFormField(
          controller: bioController,
          labelText: 'Bio',
          hintText: 'Enter New Bio',
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
