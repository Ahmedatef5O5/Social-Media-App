import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:image_picker/image_picker.dart' show XFile;
import 'package:social_media_app/core/design/tokens/typography.dart';
import 'package:social_media_app/core/mentions/mentions.dart';
import 'package:social_media_app/core/themes/background_theme_widget.dart';
import 'package:social_media_app/core/widgets/custom_loading_indicator.dart';
import 'package:social_media_app/features/home/cubits/home_cubit/home_cubit.dart';
import 'package:social_media_app/core/router/app_routes.dart';
import 'package:social_media_app/features/gifs/models/gif_result_model.dart';
import 'package:social_media_app/features/gifs/widgets/gif_picker_sheet.dart';
import 'package:social_media_app/features/social_graph/views/audience_picker_view.dart';
import 'package:social_media_app/features/social_graph/widgets/privacy_selector_sheet.dart';
import '../../../core/helpers/modern_circle_progress.dart';
import '../../../core/media_editor/media_editor_service.dart';
import '../../../core/supabase/supabase_provider.dart';
import '../../../core/toast/app_toast.dart';
import '../../../core/utilities/file_size_formatter.dart';
import '../../ai_assistant/entities/ai_request_context.dart';
import '../../group_chats/models/group_model.dart';
import '../../social_graph/models/content_privacy.dart';
import '../../group_chats/services/group_chat_services.dart';
import '../cubits/posts_cubit/posts_cubit.dart';
import '../models/post_theme_model.dart';
import '../widgets/create_post_gif_preview.dart';
import '../widgets/themed_post_canvas.dart';
import 'post_themes_view.dart';
import '../widgets/add_post_options_bottom_sheet.dart';
import '../widgets/create_post_file_preview.dart';
import '../widgets/create_post_header_section.dart';
import '../widgets/create_post_image_preview.dart';
import '../widgets/create_post_input_field.dart';
import '../widgets/create_post_user_info.dart';
import '../widgets/create_post_video_preview.dart';
import 'package:social_media_app/core/localization/l10n_extension.dart';

class CreatePostView extends StatefulWidget {
  final String? initialText;
  final GroupModel? targetGroup;
  const CreatePostView({super.key, this.initialText, this.targetGroup});

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

  late PostsCubit _postsCubit;

  void _minimizeSheet() {
    if (_sheetController.isAttached) {
      _sheetController.animateTo(
        0.15,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  List<String>? _groupMemberIds;

  Future<void> _loadGroupMembers() async {
    final group = widget.targetGroup;
    if (group == null) return;
    if (group.members.isNotEmpty) {
      _groupMemberIds = group.members.map((m) => m.userId).toList();
      return;
    }
    try {
      final ids = await context.read<GroupChatServices>().getGroupMemberIds(
        group.id,
      );
      if (mounted) setState(() => _groupMemberIds = ids);
    } catch (e) {
      debugPrint('[CreatePostView] failed to load group members: $e');
      // Fail closed: no suggestions rather than leaking non-members.
      if (mounted) setState(() => _groupMemberIds = const []);
    }
  }

  ContentPrivacy _selectedPrivacy = ContentPrivacy.public;
  Set<String> _selectedViewerIds = {};

  Future<void> _pickPrivacy() async {
    if (widget.targetGroup != null) return; // locked to group members
    final result = await showPrivacySelectorSheet(
      context,
      currentPrivacy: _selectedPrivacy,
      isStory: false,
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

  static const TextStyle _defaultMentionStyle = TextStyle(
    color: Colors.blue,
    fontWeight: FontWeight.w700,
    fontFamilyFallback: AppTypography.fontFallback,
  );

  /// Keeps @mentions readable: theme accent on a themed canvas, default blue
  /// otherwise.
  void _syncMentionStyle(PostBackgroundThemeModel? theme) {
    _textEditingController.mentionStyle =
        theme == null
            ? _defaultMentionStyle
            : _defaultMentionStyle.copyWith(
              color: theme.mentionColor,
              decoration: TextDecoration.underline,
              decorationColor: theme.mentionColor,
            );
  }

  Future<void> _pickTheme() async {
    final postsCubit = context.read<PostsCubit>();
    final picked = await Navigator.of(context).pushNamed<Object?>(
      AppRoutes.postThemesViewRoute,
      arguments: PostThemesViewArgs(
        selectedThemeId: postsCubit.selectedThemeId,
        sampleText: _textEditingController.text,
      ),
    );
    if (!mounted || picked == null) return;
    final PostThemeSelection? selection = switch (picked) {
      PostThemeSelection s => s,
      PostBackgroundThemeModel t => PostThemeSelection(theme: t),
      _ => null,
    };
    if (selection == null) return;
    postsCubit.selectTheme(selection.encode());
    _syncMentionStyle(selection.theme);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusNode.requestFocus();
    });
  }

  void _clearTheme() {
    context.read<PostsCubit>().clearTheme();
    _syncMentionStyle(null);
  }

  Future<void> _pickGif() async {
    final postsCubit = context.read<PostsCubit>();
    final gif = await showModalBottomSheet<GifResult?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const GifPickerSheet(),
    );
    if (gif == null || !mounted) return;
    postsCubit.selectGif(url: gif.postUrl, aspectRatio: gif.aspectRatio);
    _syncMentionStyle(null);
  }

  @override
  void initState() {
    super.initState();
    if (widget.targetGroup != null) {
      _selectedPrivacy = ContentPrivacy.private;
      _groupMemberIds =
          widget.targetGroup!.members.isNotEmpty
              ? widget.targetGroup!.members.map((m) => m.userId).toList()
              : null;
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadGroupMembers());
    }
    if (widget.initialText != null && widget.initialText!.trim().isNotEmpty) {
      _textEditingController.text = widget.initialText!;
      _hasText = true;
    }
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
  void didChangeDependencies() {
    super.didChangeDependencies();
    _postsCubit = context.read<PostsCubit>();
  }

  @override
  void dispose() {
    try {
      _postsCubit.clearMediaSelection();
    } catch (e) {
      debugPrint(
        '[CreatePostView] failed to clear media selection on dispose: $e',
      );
    }

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
          AppToast.info(context.l10n.uploadCanceled);
        }
        if (state is PostCreated) {
          AppToast.success(context.l10n.postPublishedSuccessfully);

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
            postsCubit.selectedDocument != null ||
            postsCubit.selectedGifUrl != null;
        final bool hasMedia =
            postsCubit.selectedImage != null ||
            postsCubit.selectedVideo != null ||
            postsCubit.selectedDocument != null ||
            postsCubit.selectedGifUrl != null;
        final PostThemeSelection? activeThemeSelection =
            PostThemeSelection.parse(postsCubit.selectedThemeId);
        final PostBackgroundThemeModel? activeTheme =
            activeThemeSelection?.theme;
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
                                  groupId: widget.targetGroup?.id,
                                );
                              } else {
                                HapticFeedback.vibrate();

                                AppToast.warning(
                                  context.l10n.writeSomethingOrAttach,
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
                            targetGroup: widget.targetGroup,
                          ),
                          Gap(12),
                          BlocBuilder<PostsCubit, PostsState>(
                            builder: (context, state) {
                              final inputField = CreatePostInputField(
                                textEditingController: _textEditingController,
                                // Fail closed while the roster loads: never suggest non-members.
                                restrictSuggestionsToUserIds:
                                    widget.targetGroup == null
                                        ? null
                                        : (_groupMemberIds ?? const <String>[]),
                                hasText: _hasText,
                                focusNode: _focusNode,
                                theme: activeTheme,
                                hasMediaAttached:
                                    postsCubit.selectedImage != null ||
                                    postsCubit.selectedVideo != null,
                                targetMediaType:
                                    postsCubit.selectedImage != null
                                        ? AiTargetMediaType.image
                                        : postsCubit.selectedVideo != null
                                        ? AiTargetMediaType.video
                                        : AiTargetMediaType.none,
                                imageBytesProvider:
                                    postsCubit.selectedImage == null
                                        ? null
                                        : () =>
                                            File(
                                              postsCubit.selectedImage!.path,
                                            ).readAsBytes(),
                              );
                              if (activeTheme == null ||
                                  activeThemeSelection == null) {
                                return inputField;
                              }
                              final hasMotifs = activeThemeSelection.hasMotifs;
                              final hPad = hasMotifs ? 50.0 : 30.0;
                              return Stack(
                                children: [
                                  ThemedPostCanvas(
                                    theme: activeTheme,
                                    motifs: activeThemeSelection.motifs,
                                    seed: activeThemeSelection.seed,
                                    minHeight: 230,
                                    borderRadius: 20,
                                    bottomReservedHeight: 54,
                                    padding: EdgeInsets.fromLTRB(
                                      hPad,
                                      hasMotifs ? 48 : 34,
                                      hPad,
                                      hasMotifs ? 86 : 68,
                                    ),
                                    child: inputField,
                                  ),
                                  PositionedDirectional(
                                    bottom: 12,
                                    start: 0,
                                    end: 0,
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        _ThemePill(
                                          icon: Icons.palette_rounded,
                                          label: context.l10n.changeTheme,
                                          onTap: _pickTheme,
                                        ),
                                        if (hasMotifs) ...[
                                          const Gap(8),
                                          _ThemePill(
                                            icon: Icons.shuffle_rounded,
                                            tooltip:
                                                context.l10n.themeShuffleMotifs,
                                            onTap:
                                                postsCubit
                                                    .shuffleSelectedThemeSeed,
                                          ),
                                        ],
                                        const Gap(8),
                                        _ThemePill(
                                          icon: Icons.close_rounded,
                                          tooltip: context.l10n.clearTheme,
                                          onTap: _clearTheme,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                          Gap(8),
                          BlocBuilder<PostsCubit, PostsState>(
                            builder: (context, state) {
                              if (postsCubit.selectedImage != null) {
                                return CreatePostImagePreview(
                                  imagePath: postsCubit.selectedImage!.path,
                                  fileSizeBytes:
                                      postsCubit.selectedImageSizeBytes,
                                  onRemove: () {
                                    setState(() {
                                      postsCubit.selectedImage = null;
                                      postsCubit.selectedImageSizeBytes = null;
                                    });
                                  },
                                  onEdit: () async {
                                    final current = postsCubit.selectedImage;
                                    if (current == null) return null;
                                    final edited =
                                        await MediaEditorService.editImage(
                                          context,
                                          File(current.path),
                                          preset: MediaEditorPreset.post,
                                        );
                                    if (edited == null || !mounted) return null;
                                    setState(() {
                                      postsCubit.selectedImage = XFile(
                                        edited.path,
                                      );
                                      postsCubit.selectedImageSizeBytes =
                                          edited.lengthSync();
                                    });
                                    return edited.path;
                                  },
                                );
                              } else if (postsCubit.selectedVideo != null) {
                                return CreatePostVideoPreview(
                                  // New key per file so the player re-initialises
                                  // after a trim.
                                  key: ValueKey(postsCubit.selectedVideo!.path),
                                  videoPath: postsCubit.selectedVideo!.path,
                                  fileSizeBytes:
                                      postsCubit.selectedVideoSizeBytes,
                                  onRemove: () {
                                    setState(() {
                                      postsCubit.selectedVideo = null;
                                      postsCubit.selectedVideoSizeBytes = null;
                                    });
                                  },
                                  onEdit: () async {
                                    final current = postsCubit.selectedVideo;
                                    if (current == null) return;
                                    final trimmed =
                                        await MediaEditorService.trimVideo(
                                          context,
                                          File(current.path),
                                        );
                                    if (trimmed == null || !mounted) return;
                                    setState(() {
                                      postsCubit.selectedVideo = XFile(
                                        trimmed.file.path,
                                      );
                                      postsCubit.selectedVideoSizeBytes =
                                          trimmed.file.lengthSync();
                                    });
                                  },
                                );
                              } else if (postsCubit.selectedDocument != null) {
                                return CreatePostFilePreview(
                                  fileName: postsCubit.selectedDocument!.name,
                                  fileSizeBytes:
                                      postsCubit.selectedDocumentSizeBytes,
                                  onRemove: () {
                                    setState(() {
                                      postsCubit.selectedDocument = null;
                                      postsCubit.selectedDocumentSizeBytes =
                                          null;
                                    });
                                  },
                                );
                              } else if (postsCubit.selectedGifUrl != null) {
                                return CreatePostGifPreview(
                                  gifUrl: postsCubit.selectedGifUrl!,
                                  aspectRatio:
                                      postsCubit.selectedGifAspectRatio ?? 1,
                                  onRemove: postsCubit.clearGif,
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
                  AddPostOptionsBottomSheet(
                    controller: _sheetController,
                    onPickTheme: _pickTheme,
                    onPickGif: _pickGif,
                  ),
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
                                          ? context.l10n.posted
                                          : (state.totalBytes > 0 &&
                                                  state.sentBytes <
                                                      state.totalBytes
                                              ? formatMediaFileSizeRatio(
                                                state.sentBytes,
                                                state.totalBytes,
                                              )
                                              : context.l10n.publishingPost),
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
                                                : FontWeight.w600,
                                      ),
                                    ),
                                  ],
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

/// Small translucent pill floating on the themed canvas.
class _ThemePill extends StatelessWidget {
  final IconData icon;
  final String? label;
  final String? tooltip;
  final VoidCallback onTap;

  const _ThemePill({
    required this.icon,
    required this.onTap,
    this.label,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final pill = Material(
      color: Colors.black.withValues(alpha: 0.38),
      shape: const StadiumBorder(),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: label == null ? 9 : 14,
            vertical: 8,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.white, size: 18),
              if (label != null) ...[
                const Gap(6),
                Text(
                  label!,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
    return tooltip == null ? pill : Tooltip(message: tooltip!, child: pill);
  }
}
