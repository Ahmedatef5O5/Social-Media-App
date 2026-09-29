import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:image_picker/image_picker.dart';
import 'package:social_media_app/core/constants/app_images.dart';
import 'package:social_media_app/core/themes/background_theme_widget.dart';
import 'package:social_media_app/features/auth/data/models/user_data.dart';
import 'package:social_media_app/features/profile/cubits/edit_profile_cubit/edit_profile_cubit.dart';
import 'package:social_media_app/features/profile/models/social_platform_info.dart';
import 'package:social_media_app/features/profile/widgets/edit_profile_action_btn.dart';
import 'package:social_media_app/features/profile/widgets/edit_profile_form.dart';
import 'package:social_media_app/features/profile/widgets/edit_profile_sliver_app_bar.dart';
import 'package:social_media_app/features/profile/widgets/edit_social_links_section.dart';
import 'package:social_media_app/features/profile/widgets/image_picker_bottom_sheet.dart';
import '../../../core/toast/app_toast.dart';
import '../../../core/widgets/custom_confirmation_dialog.dart';
import '../../posts/cubits/posts_cubit/posts_cubit.dart';
import '../../stories/cubits/stories_cubit/stories_cubit.dart';

class EditProfileView extends StatefulWidget {
  final UserData? userData;
  final bool autofocusTagline;

  const EditProfileView({
    super.key,
    this.userData,
    this.autofocusTagline = false,
  });
  @override
  State<EditProfileView> createState() => _EditProfileViewState();
}

class _EditProfileViewState extends State<EditProfileView> {
  late TextEditingController _nameController;
  late TextEditingController _userNameController;
  late TextEditingController _titleController;
  late TextEditingController _bioController;
  late TextEditingController _taglineController;
  late FocusNode _taglineFocusNode;
  late bool _isTaglineHidden;
  late Map<String, TextEditingController> _socialLinkControllers;
  late ScrollController _scrollController;
  Animation<double>? _routeAnimation;
  bool _didRequestTaglineFocus = false;
  File? selectedProfileImage;
  File? selectedBackgroundImage;
  bool profileImageRemoved = false;
  bool backgroundImageRemoved = false;

  String? get _effectiveAvatarUrl =>
      profileImageRemoved ? null : widget.userData?.imageUrl;
  String? get _effectiveCoverUrl =>
      backgroundImageRemoved ? null : widget.userData?.backgroundImageUrl;

  Future<void> _handleImageSelection(bool isProfile, ImageSource source) async {
    final File? image = await context.read<EditProfileCubit>().pickImage(
      source,
    );
    if (!mounted) return;

    if (image != null) {
      setState(() {
        if (isProfile) {
          selectedProfileImage = image;
          profileImageRemoved = false;
        } else {
          selectedBackgroundImage = image;
          backgroundImageRemoved = false;
        }
      });
    }
  }

  void _handleImageRemoval(bool isProfile) {
    setState(() {
      if (isProfile) {
        selectedProfileImage = null;
        profileImageRemoved = true;
      } else {
        selectedBackgroundImage = null;
        backgroundImageRemoved = true;
      }
    });
  }

  void showImagePickerOptions(context, bool isProfile) {
    final hasCustomPhoto =
        isProfile
            ? (selectedProfileImage != null || _effectiveAvatarUrl != null)
            : (selectedBackgroundImage != null || _effectiveCoverUrl != null);

    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (context) => ImagePickerBottomSheet(
            title: isProfile ? 'Edit Profile Picture' : 'Edit Cover Photo',
            showRemoveOption: hasCustomPhoto,
            onImageSelected: (source) {
              Navigator.pop(context);
              _handleImageSelection(isProfile, source);
            },
            onRemoveImage: () {
              Navigator.pop(context);
              _handleImageRemoval(isProfile);
            },
          ),
    );
  }

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _nameController = TextEditingController(text: widget.userData?.name);
    _userNameController = TextEditingController(
      text: widget.userData?.userName,
    );
    _titleController = TextEditingController(text: widget.userData?.title);
    _bioController = TextEditingController(text: widget.userData?.bio);
    _taglineController = TextEditingController(text: widget.userData?.tagline);
    _taglineFocusNode = FocusNode();
    _isTaglineHidden = widget.userData?.isTaglineHidden ?? false;

    final existingSocialLinks = widget.userData?.socialLinks ?? const {};
    _socialLinkControllers = {
      for (final platform in SocialPlatformInfo.all)
        platform.key: TextEditingController(
          text: existingSocialLinks[platform.key],
        ),
    };

    if (widget.autofocusTagline) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final animation = ModalRoute.of(context)?.animation;
        if (animation == null || animation.isCompleted) {
          _requestTaglineFocusSafely();
        } else {
          _routeAnimation = animation;
          animation.addStatusListener(_onRouteAnimationStatusChanged);
        }
      });
    }
  }

  void _onRouteAnimationStatusChanged(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      _routeAnimation?.removeStatusListener(_onRouteAnimationStatusChanged);
      _routeAnimation = null;
      _requestTaglineFocusSafely();
    }
  }

  void _requestTaglineFocusSafely() {
    if (!mounted || _didRequestTaglineFocus) return;
    _didRequestTaglineFocus = true;
    _taglineFocusNode.requestFocus();
  }

  @override
  void dispose() {
    _routeAnimation?.removeStatusListener(_onRouteAnimationStatusChanged);
    _routeAnimation = null;
    _scrollController.dispose();
    _nameController.dispose();
    _userNameController.dispose();
    _titleController.dispose();
    _bioController.dispose();
    _taglineController.dispose();
    _taglineFocusNode.dispose();
    for (final controller in _socialLinkControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const double expandedAvatarSize = 90.0;
    const double bottomOverlap = expandedAvatarSize * 0.5;

    return BlocListener<EditProfileCubit, EditProfileState>(
      listenWhen:
          (previous, current) =>
              (previous is! EditProfileSuccess &&
                  current is EditProfileSuccess) ||
              current is EditProfileError,
      listener: (context, state) async {
        if (state is EditProfileSuccess) {
          final updated = state.updatedUser;
          try {
            context.read<PostsCubit>().setCurrentUser(updated);
            context.read<PostsCubit>().updateAuthorInfo(
              authorId: updated.id,
              newName: updated.name,
              newImageUrl: updated.imageUrl,
            );
          } catch (_) {}
          try {
            context.read<StoriesCubit>().updateAuthorInfo(
              authorId: updated.id,
              newName: updated.name,
              newImageUrl: updated.imageUrl,
            );
          } catch (_) {}

          AppToast.success('Profile Updated Successfully');
          await Future.delayed(const Duration(milliseconds: 550));
          if (!context.mounted) return;
          Navigator.of(context).pop(updated);
        } else if (state is EditProfileError) {
          AppToast.error(state.errMsg);
        }
      },
      child: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, result) async {
            if (didPop) return;
            await _handleBackNavigation();
          },
          child: Scaffold(
            body: BackgroundThemeWidget(
              top: false,
              child: CustomScrollView(
                controller: _scrollController,
                slivers: [
                  EditProfileSliverAppBar(
                    coverHeight: 200,
                    coverUrl: _effectiveCoverUrl,
                    selectedCoverFile: selectedBackgroundImage,
                    onEditCover: () => showImagePickerOptions(context, false),
                    avatarUrl: _effectiveAvatarUrl,
                    selectedAvatarFile: selectedProfileImage,
                    onEditAvatar: () => showImagePickerOptions(context, true),
                    onBackPressed: () => _handleBackNavigation(),
                  ),
                  const SliverToBoxAdapter(
                    child: SizedBox(height: bottomOverlap),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.only(
                      left: 24,
                      right: 24,
                      top: 8,
                      bottom: 24,
                    ),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        EditProfileForm(
                          nameController: _nameController,
                          userNameController: _userNameController,
                          titleController: _titleController,
                          bioController: _bioController,
                          taglineController: _taglineController,
                          taglineFocusNode: _taglineFocusNode,
                          isTaglineHidden: _isTaglineHidden,
                          onTaglineHiddenChanged: (value) {
                            setState(() => _isTaglineHidden = value);
                          },
                        ),
                        const Gap(24),
                        const Divider(),
                        const Gap(16),
                        EditSocialLinksSection(
                          controllers: _socialLinkControllers,
                        ),
                        const Gap(20),
                        Center(
                          child: EditProfileActionButton(
                            onPressed: () => _onSavePressed(),
                          ),
                        ),
                        const Gap(24),
                      ]),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  bool get _hasUnsavedChanges {
    if (widget.userData == null) return false;
    final user = widget.userData!;

    if (_nameController.text != (user.name)) return true;
    if (_userNameController.text != (user.userName ?? '')) return true;
    if (_titleController.text != (user.title ?? '')) return true;
    if (_bioController.text != (user.bio ?? '')) return true;
    if (_taglineController.text != (user.tagline ?? '')) return true;
    if (_isTaglineHidden != user.isTaglineHidden) return true;

    if (selectedProfileImage != null || profileImageRemoved) return true;
    if (selectedBackgroundImage != null || backgroundImageRemoved) return true;

    final existingLinks = user.socialLinks;
    for (final platform in SocialPlatformInfo.all) {
      final currentText =
          _socialLinkControllers[platform.key]?.text.trim() ?? '';
      final existingText = existingLinks[platform.key] ?? '';
      if (currentText != existingText) return true;
    }

    return false;
  }

  Future<void> _handleBackNavigation() async {
    final currentState = context.read<EditProfileCubit>().state;
    if (currentState is EditProfileLoading ||
        currentState is EditProfileSuccess) {
      return;
    }
    if (!_hasUnsavedChanges) {
      Navigator.of(context).pop();
      return;
    }

    final shouldDiscard = await showDialog<bool>(
      context: context,
      builder:
          (context) => CustomConfirmationDialog(
            title: 'You have unsaved changes. Do you want to discard them?',
            textAlign: TextAlign.center,
            img: AppImages.alertAnimationLot,
            confirmBtnText: 'Discard',
            cancelBtnText: 'Cancel',
            onConfirm: () {
              Navigator.of(context, rootNavigator: true).pop(true);
            },
          ),
    );

    if (shouldDiscard == true && mounted) {
      Navigator.of(context).pop();
    }
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
      tagline: _taglineController.text,
      isTaglineHidden: _isTaglineHidden,
      profileImage: selectedProfileImage,
      backgroundImage: selectedBackgroundImage,
      removeProfileImage: profileImageRemoved,
      removeBackgroundImage: backgroundImageRemoved,
      socialLinks: socialLinks,
    );
  }
}
