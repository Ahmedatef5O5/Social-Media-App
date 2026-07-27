import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:social_media_app/core/mentions/mentions.dart';
import 'package:social_media_app/core/themes/background_theme_widget.dart';
import 'package:social_media_app/core/widgets/custom_loading_indicator.dart';
import 'package:social_media_app/features/home/cubits/home_cubit/home_cubit.dart';
import 'package:social_media_app/features/social_graph/views/audience_picker_view.dart';
import 'package:social_media_app/features/social_graph/widgets/privacy_selector_sheet.dart';
import '../../../core/helpers/modern_circle_progress.dart';
import '../../../core/supabase/supabase_provider.dart';
import '../../../core/toast/app_toast.dart';
import '../../social_graph/models/content_privacy.dart';
import '../cubit/posts_cubit/posts_cubit.dart';
import '../widgets/add_post_options_bottom_sheet.dart';
import '../widgets/create_post_file_preview.dart';
import '../widgets/create_post_header_section.dart';
import '../widgets/create_post_image_preview.dart';
import '../widgets/create_post_input_field.dart';
import '../widgets/create_post_user_info.dart';
import '../widgets/create_post_video_preview.dart';

class CreatePostView extends StatefulWidget {
  const CreatePostView({super.key});

  @override
  State<CreatePostView> createState() => _CreatePostViewState();
}

class _CreatePostViewState extends State<CreatePostView> {
  final MentionTextEditingController _textEditingController =
      MentionTextEditingController();
  final DraggableScrollableController _sheetController =
      DraggableScrollableController();

  final FocusNode _focusNode = FocusNode();
  bool _hasText = false;

  void _minimizeSheet() {
    if (_sheetController.isAttached) {
      _sheetController.animateTo(
        0.15,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  ContentPrivacy _selectedPrivacy = ContentPrivacy.public;
  Set<String> _selectedViewerIds = {};

  Future<void> _pickPrivacy() async {
    final result = await showPrivacySelectorSheet(
      context,
      currentPrivacy: _selectedPrivacy,
    );
    if (result == null) return;

    if (result == ContentPrivacy.private) {
      if (!mounted) return;
      final selected = await Navigator.of(
        context,
        rootNavigator: true,
      ).push<Set<String>>(
        MaterialPageRoute(
          builder:
              (_) => AudiencePickerView(initialSelectedIds: _selectedViewerIds),
        ),
      );
      if (selected == null || selected.isEmpty) return;
      setState(() {
        _selectedPrivacy = ContentPrivacy.private;
        _selectedViewerIds = selected;
      });
    } else {
      setState(() {
        _selectedPrivacy = result;
        _selectedViewerIds = {};
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      if (_focusNode.hasFocus) {
        _minimizeSheet();
      }
    });
    _textEditingController.addListener(() {
      setState(() {
        _hasText = _textEditingController.text.trim().isNotEmpty;
      });
      if (_hasText) {
        _minimizeSheet();
      }
    });
  }

  @override
  void dispose() {
    _textEditingController.dispose();
    _sheetController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<PostsCubit, PostsState>(
      listenWhen: (previous, current) => previous != current,
      listener: (context, state) {
        if (state is MediaPicking || state is PostCreating) {
          if (_sheetController.isAttached) {
            _sheetController.animateTo(
              0.15,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
          }
        }
        if (state is PostUploadCanceled) {
          AppToast.info('Upload canceled');
        }
        if (state is PostCreated) {
          AppToast.success('Post Published Successfully');

          Navigator.pop(context);
        } else if (state is PostCreateError) {
          if (!state.isConnectivityError) {
            AppToast.error(state.message);
          }
        }
        if (state is MediaPickingError) {
          if (_sheetController.isAttached) {
            _sheetController.animateTo(
              0.7,
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeInOut,
            );
          }
        }
      },
      builder: (context, state) {
        final homeCubit = context.read<HomeCubit>();
        final postsCubit = context.read<PostsCubit>();
        final user = homeCubit.currentUserData;
        final authUser = SupabaseProvider.user;
        final bool canPost =
            _textEditingController.text.trim().isNotEmpty ||
            postsCubit.selectedImage != null ||
            postsCubit.selectedVideo != null ||
            postsCubit.selectedDocument != null;
        final bool hasMedia =
            postsCubit.selectedImage != null ||
            postsCubit.selectedVideo != null ||
            postsCubit.selectedDocument != null;
        final displayName =
            user?.name ?? authUser?.userMetadata?['full_name'] ?? 'User';
        final displayImage =
            user?.imageUrl ?? authUser?.userMetadata?['avatar_url'];

        return GestureDetector(
          onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
          child: Scaffold(
            resizeToAvoidBottomInset: false,
            body: Stack(
              children: [
                BackgroundThemeWidget(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.vertical,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Gap(2),
                          CreatePostHeaderSection(
                            isLoading: state is PostCreating,
                            canPost: canPost,
                            onTap: () {
                              if (canPost) {
                                postsCubit.createPost(
                                  text: _textEditingController.text.trim(),
                                  privacy: _selectedPrivacy,
                                  allowedViewerIds: _selectedViewerIds.toList(),
                                  mentions:
                                      _textEditingController.validMentions,
                                );
                              } else {
                                HapticFeedback.vibrate();

                                AppToast.warning(
                                  "Write something or attach a file to share your post.",
                                );
                              }
                            },
                          ),
                          Gap(20),
                          CreatePostUserInfo(
                            userName: displayName,
                            userImageUrl: displayImage,
                            privacy: _selectedPrivacy,
                            onPrivacyTap: _pickPrivacy,
                          ),
                          Gap(12),
                          CreatePostInputField(
                            textEditingController: _textEditingController,
                            hasText: _hasText,
                            focusNode: _focusNode,
                          ),
                          Gap(8),
                          BlocBuilder<PostsCubit, PostsState>(
                            builder: (context, state) {
                              if (postsCubit.selectedImage != null) {
                                return CreatePostImagePreview(
                                  imagePath: postsCubit.selectedImage!.path,
                                  onRemove: () {
                                    setState(() {
                                      postsCubit.selectedImage = null;
                                    });
                                  },
                                );
                              } else if (postsCubit.selectedVideo != null) {
                                return CreatePostVideoPreview(
                                  videoPath: postsCubit.selectedVideo!.path,
                                  onRemove: () {
                                    setState(() {
                                      postsCubit.selectedVideo = null;
                                    });
                                  },
                                );
                              } else if (postsCubit.selectedDocument != null) {
                                return CreatePostFilePreview(
                                  fileName:
                                      postsCubit.selectedDocument!.path
                                          .split('/')
                                          .last,
                                  onRemove: () {
                                    setState(() {
                                      postsCubit.selectedDocument = null;
                                    });
                                  },
                                );
                              } else if (state is MediaPicking &&
                                  state is! PostCreating) {
                                return SizedBox(
                                  height:
                                      MediaQuery.of(context).size.height * 0.25,
                                  child: CustomLoadingIndicator(),
                                );
                              } else {
                                return const SizedBox.shrink();
                              }
                            },
                          ),
                          const Gap(120),
                        ],
                      ),
                    ),
                  ),
                ),
                if (!hasMedia)
                  AddPostOptionsBottomSheet(controller: _sheetController),
                if (state is PostCreating)
                  Container(
                    key: const ValueKey('uploading_overlay'),
                    color: Theme.of(
                      context,
                    ).scaffoldBackgroundColor.withValues(alpha: 0.02),
                    width: double.infinity,
                    height: double.infinity,
                    child: Center(
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 40),
                        child: Stack(
                          alignment: Alignment.topRight,
                          children: [
                            Card(
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(24.0),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    ModernCircularProgress(
                                      progress: state.progress,
                                      size: 110,
                                      showCheckmark: true,
                                      enableHaptic: true,
                                    ),
                                    const Gap(16),
                                    Text(
                                      state.progress >= 1.0
                                          ? 'Posted'
                                          : "Publishing Post...",
                                      textAlign: TextAlign.center,
                                      style: Theme.of(
                                        context,
                                      ).textTheme.titleLarge?.copyWith(
                                        color:
                                            Theme.of(context).brightness ==
                                                    Brightness.light
                                                ? Theme.of(context).primaryColor
                                                    .withValues(alpha: 0.7)
                                                : Theme.of(context).primaryColor
                                                    .withValues(alpha: 0.95),

                                        fontSize: 18,
                                        fontWeight:
                                            state.progress >= 1.0
                                                ? FontWeight.bold
                                                : FontWeight.w400,
                                      ),
                                    ),
                                  ],
                                  // ],
                                ),
                              ),
                            ),
                            Positioned(
                              top: 8,
                              right: 8,
                              child: GestureDetector(
                                onTap: () => postsCubit.cancelUpload(),
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context)
                                        .scaffoldBackgroundColor
                                        .withValues(alpha: 1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.close,
                                    size: 20,
                                    color:
                                        Theme.of(context).brightness ==
                                                Brightness.light
                                            ? Theme.of(context).primaryColor
                                                .withValues(alpha: 0.85)
                                            : Theme.of(context).primaryColor
                                                .withValues(alpha: 0.95),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
