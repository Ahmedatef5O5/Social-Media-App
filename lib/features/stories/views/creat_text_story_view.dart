import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:social_media_app/core/mentions/mentions.dart';
import 'package:social_media_app/features/auth/data/models/user_data.dart';
import 'package:social_media_app/features/social_graph/views/audience_picker_view.dart';
import 'package:social_media_app/features/social_graph/widgets/privacy_chip.dart';
import '../../../core/themes/app_colors.dart';
import '../../../core/toast/app_toast.dart';
import '../../settings/repository/settings_repository.dart';
import '../../social_graph/helpers/privacy_picker_helper.dart';
import '../../social_graph/models/content_privacy.dart';
import '../cubit/stories_cubit/stories_cubit.dart';
import '../widgets/story_text_editor.dart';

class CreateTextStoryView extends StatefulWidget {
  final UserData currentUser;

  const CreateTextStoryView({super.key, required this.currentUser});

  @override
  State<CreateTextStoryView> createState() => _CreateTextStoryViewState();
}

class _CreateTextStoryViewState extends State<CreateTextStoryView> {
  final MentionTextEditingController _controller =
      MentionTextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _hasText = false;

  late List<Color> _colors;
  late Color _selectedColor;
  late ContentPrivacy _selectedPrivacy =
      SettingsRepository.instance.defaultStoryPrivacy;
  Set<String> _selectedViewerIds = {};

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      setState(() {
        _hasText = _controller.text.trim().isNotEmpty;
      });
    });

    _colors = [
      Colors.grey,
      Colors.green,
      Colors.purple,
      Colors.red,
      Colors.black,
      Colors.orange,
      Colors.pink,
    ];
    _selectedColor = _colors.first;
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _pickPrivacy() async {
    final result = await pickContentPrivacy(
      context,
      currentPrivacy: _selectedPrivacy,
      currentViewerIds: _selectedViewerIds,
    );
    if (result == null) return;
    setState(() {
      _selectedPrivacy = result.privacy;
      _selectedViewerIds = result.allowedViewerIds;
    });
  }

  void _share(BuildContext context) async {
    if (!_hasText) return;

    if (_selectedPrivacy == ContentPrivacy.private &&
        _selectedViewerIds.isEmpty) {
      final selected = await Navigator.of(
        context,
        rootNavigator: true,
      ).push<Set<String>>(
        MaterialPageRoute(builder: (_) => const AudiencePickerView()),
      );
      if (selected == null || selected.isEmpty) return;
      setState(() => _selectedViewerIds = selected);
    }
    if (!context.mounted) return;

    context.read<StoriesCubit>().addTextStory(
      text: _controller.text.trim(),
      bgColor: _selectedColor,
      user: widget.currentUser,
      privacy: _selectedPrivacy,
      allowedViewerIds: _selectedViewerIds.toList(),
      mentions: _controller.validMentions,
    );
  }

  void _showColorPickerDialog() {
    FocusScope.of(context).unfocus();
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.transparent,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
              child: Scaffold(
                backgroundColor: Colors.black.withValues(alpha: 0.4),
                body: GestureDetector(
                  onTap: () => Navigator.of(dialogContext).pop(),
                  behavior: HitTestBehavior.opaque,
                  child: Center(
                    child: GestureDetector(
                      onTap: () {},
                      child: Container(
                        width: MediaQuery.of(context).size.width * 0.85,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 36,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.85),
                          borderRadius: BorderRadius.circular(32),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.1),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.5),
                              blurRadius: 30,
                              spreadRadius: 10,
                            ),
                          ],
                        ),
                        child: Wrap(
                          spacing: 24,
                          runSpacing: 24,
                          alignment: WrapAlignment.center,
                          children:
                              _colors.map((color) {
                                final isSelected = color == _selectedColor;
                                return GestureDetector(
                                  onTap: () {
                                    setDialogState(() {});
                                    setState(() => _selectedColor = color);
                                    Future.delayed(
                                      const Duration(milliseconds: 200),
                                      () {
                                        if (dialogContext.mounted) {
                                          Navigator.of(dialogContext).pop();
                                        }
                                      },
                                    );
                                  },
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 300),
                                    curve: Curves.easeOutBack,
                                    width: isSelected ? 60 : 48,
                                    height: isSelected ? 60 : 48,
                                    decoration: BoxDecoration(
                                      color: color,
                                      shape: BoxShape.circle,
                                      border:
                                          isSelected
                                              ? Border.all(
                                                color: Colors.white,
                                                width: 3.5,
                                              )
                                              : Border.all(
                                                color: Colors.white24,
                                                width: 1.5,
                                              ),
                                      boxShadow:
                                          isSelected
                                              ? [
                                                BoxShadow(
                                                  color: color.withValues(
                                                    alpha: 0.8,
                                                  ),
                                                  blurRadius: 16,
                                                  spreadRadius: 2,
                                                ),
                                              ]
                                              : [
                                                BoxShadow(
                                                  color: Colors.black
                                                      .withValues(alpha: 0.4),
                                                  blurRadius: 6,
                                                  offset: const Offset(0, 3),
                                                ),
                                              ],
                                    ),
                                    child:
                                        isSelected
                                            ? const Icon(
                                              Icons.check_rounded,
                                              color: Colors.white,
                                              size: 30,
                                              shadows: [
                                                Shadow(
                                                  color: Colors.black54,
                                                  blurRadius: 6,
                                                ),
                                              ],
                                            )
                                            : null,
                                  ),
                                );
                              }).toList(),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<StoriesCubit, StoriesState>(
      listener: (context, state) {
        if (state is AddStorySuccess) {
          Navigator.of(context).pop();
          AppToast.success('Story Added Successfully');
        }

        if (state is AddStoryError && !state.isConnectivityError) {
          AppToast.error(state.message);
        }
      },
      builder: (context, state) {
        return GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: Scaffold(
            resizeToAvoidBottomInset: false,
            backgroundColor: _selectedColor,
            appBar: AppBar(
              toolbarHeight: 70,
              leading: IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close, color: AppColors.white),
              ),
              backgroundColor: Colors.transparent,
              elevation: 0,
              actions: [
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: PrivacyChip(
                    privacy: _selectedPrivacy,
                    onTap: _pickPrivacy,
                  ),
                ),
              ],
            ),
            body: SafeArea(
              child: Column(
                children: [
                  Expanded(
                    child: StoryTextEditor(
                      controller: _controller,
                      focusNode: _focusNode,
                      hasText: _hasText,
                    ),
                  ),

                  Padding(
                    padding: EdgeInsets.only(
                      left: 20,
                      right: 20,
                      bottom:
                          MediaQuery.of(context).viewInsets.bottom > 0
                              ? 16
                              : 24,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Color Picker Button
                        GestureDetector(
                          onTap: _showColorPickerDialog,
                          child: Container(
                            width: 45,
                            height: 45,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white,
                                width: 2.1,
                              ),
                              boxShadow: const [
                                BoxShadow(color: Colors.black26, blurRadius: 4),
                              ],
                              gradient: const SweepGradient(
                                colors: [
                                  Colors.red,
                                  Colors.orange,
                                  Colors.green,
                                  Colors.purple,
                                  Colors.pink,
                                  Colors.red,
                                ],
                              ),
                            ),
                          ),
                        ),

                        // Share Button
                        ElevatedButton(
                          onPressed:
                              _hasText && state is! AddStoryLoading
                                  ? () => _share(context)
                                  : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).primaryColor,
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: Colors.black38,
                            disabledForegroundColor: Colors.white54,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 28,
                              vertical: 14,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(28),
                            ),
                          ),
                          child:
                              state is AddStoryLoading
                                  ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      color: Colors.white,
                                    ),
                                  )
                                  : const Text(
                                    'Share',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
