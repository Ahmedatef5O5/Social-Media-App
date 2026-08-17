import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:image_picker/image_picker.dart';
import 'package:social_media_app/core/themes/app_colors.dart';
import 'package:social_media_app/core/themes/background_theme_widget.dart';
import 'package:social_media_app/features/auth/data/models/user_data.dart';
import 'package:social_media_app/features/profile/cubits/edit_profile_cubit/edit_profile_cubit.dart';
import 'package:social_media_app/features/profile/models/social_platform_info.dart';
import 'package:social_media_app/features/profile/widgets/edit_profile_action_btn.dart';
import 'package:social_media_app/features/profile/widgets/edit_profile_form.dart';
import 'package:social_media_app/features/profile/widgets/edit_profile_images_section.dart';
import 'package:social_media_app/features/profile/widgets/edit_social_links_section.dart';
import 'package:social_media_app/features/profile/widgets/image_picker_bottom_sheet.dart';
import '../../../core/toast/app_toast.dart';

class EditProfileView extends StatefulWidget {
  const EditProfileView({super.key, this.userData});
  final UserData? userData;

  @override
  State<EditProfileView> createState() => _EditProfileViewState();
}

class _EditProfileViewState extends State<EditProfileView> {
  late TextEditingController _nameController;
  late TextEditingController _userNameController;
  late TextEditingController _titleController;
  late TextEditingController _bioController;
  late Map<String, TextEditingController> _socialLinkControllers;
  //
  File? selectedProfileImage;
  File? selectedBackgroundImage;

  Future<void> _handleImageSelection(bool isProfile, ImageSource source) async {
    final File? image = await context.read<EditProfileCubit>().pickImage(
      source,
    );
    if (image != null) {
      setState(() {
        if (isProfile) {
          selectedProfileImage = image;
        } else {
          selectedBackgroundImage = image;
        }
      });
    }
  }

  void showImagePickerOptions(context, bool isProfile) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (context) => ImagePickerBottomSheet(
            title: isProfile ? 'Edit Profile Picture' : 'Edit Cover Photo',
            onImageSelected: (source) {
              Navigator.pop(context);
              _handleImageSelection(isProfile, source);
            },
          ),
    );
  }

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.userData?.name);
    _userNameController = TextEditingController(
      text: widget.userData?.userName,
    );
    _titleController = TextEditingController(text: widget.userData?.title);
    _bioController = TextEditingController(text: widget.userData?.bio);

    final existingSocialLinks = widget.userData?.socialLinks ?? const {};
    _socialLinkControllers = {
      for (final platform in SocialPlatformInfo.all)
        platform.key: TextEditingController(
          text: existingSocialLinks[platform.key],
        ),
    };
  }

  @override
  void dispose() {
    super.dispose();
    _nameController.dispose();
    _userNameController.dispose();
    _titleController.dispose();
    _bioController.dispose();
    for (final controller in _socialLinkControllers.values) {
      controller.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<EditProfileCubit, EditProfileState>(
      listener: (context, state) {
        if (state is EditProfileSuccess) {
          if (!context.mounted) return;
          Navigator.of(context).pop();

          AppToast.success('Profile Updated Successfully');
        } else if (state is EditProfileError) {
          AppToast.error(state.errMsg);
        }
      },
      child: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Scaffold(
          extendBodyBehindAppBar: true,
          appBar: AppBar(
            elevation: 0,
            scrolledUnderElevation: 0,
            backgroundColor: AppColors.transparent,
            leading: InkWell(
              onTap: () => Navigator.of(context).pop(),
              child: Icon(
                Icons.arrow_back_ios_new,
                color: Theme.of(context).primaryColor,
              ),
            ),
            title: Text(
              'Edit Profile',
              style: Theme.of(context).textTheme.titleMedium!.copyWith(
                fontWeight: FontWeight.w400,
                fontSize: 20,
              ),
            ),
            centerTitle: true,
          ),
          body: BackgroundThemeWidget(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 2,
                ),

                child: Column(
                  children: [
                    EditProfileImagesSection(
                      userData: widget.userData,
                      selectedProfileImage: selectedProfileImage,
                      selectedBackgroundImage: selectedBackgroundImage,
                      onEditProfile:
                          () => showImagePickerOptions(context, true),
                      onEditBackground:
                          () => showImagePickerOptions(context, false),
                    ),
                    Gap(12),
                    EditProfileForm(
                      nameController: _nameController,
                      userNameController: _userNameController,
                      titleController: _titleController,
                      bioController: _bioController,
                    ),
                    Gap(24),
                    const Divider(),
                    Gap(16),
                    EditSocialLinksSection(controllers: _socialLinkControllers),
                    Gap(8),
                    EditProfileActionButton(onPressed: () => _onSavePressed()),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _onSavePressed() {
    final socialLinks = <String, String>{
      for (final entry in _socialLinkControllers.entries)
        if (entry.value.text.trim().isNotEmpty)
          entry.key: entry.value.text.trim(),
    };

    context.read<EditProfileCubit>().updateProfile(
      oldUser: widget.userData!,
      name: _nameController.text,
      userName: _userNameController.text,
      title: _titleController.text,
      bio: _bioController.text,
      profileImage: selectedProfileImage,
      backgroundImage: selectedBackgroundImage,
      socialLinks: socialLinks,
    );
  }
}
