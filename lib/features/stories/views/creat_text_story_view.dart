import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:social_media_app/features/auth/data/models/user_data.dart';
import 'package:social_media_app/features/social_graph/views/audience_picker_view.dart';
import 'package:social_media_app/features/social_graph/widgets/privacy_chip.dart';
import '../../../core/themes/app_colors.dart';
import '../../../core/toast/app_toast.dart';
import '../../settings/repository/settings_repository.dart';
import '../../social_graph/helpers/privacy_picker_helper.dart';
import '../../social_graph/models/content_privacy.dart';
import '../cubit/stories_cubit/stories_cubit.dart';
import '../widgets/story_color_picker.dart';
import '../widgets/story_submit_bar.dart';
import '../widgets/story_text_editor.dart';

class CreateTextStoryView extends StatefulWidget {
  final UserData currentUser;

  const CreateTextStoryView({super.key, required this.currentUser});

  @override
  State<CreateTextStoryView> createState() => _CreateTextStoryViewState();
}

class _CreateTextStoryViewState extends State<CreateTextStoryView> {
  final TextEditingController _controller = TextEditingController();
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
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    _colors = [
      Theme.of(context).primaryColor,
      Colors.purple,
      Colors.red,
      Colors.black,
      Colors.grey,
      Colors.orange,
      Colors.green,
    ];

    _selectedColor = _colors.first;
  }

  @override
  void dispose() {
    _controller.dispose();
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
        MaterialPageRoute(builder: (_) => AudiencePickerView()),
      );
      if (selected == null || selected.isEmpty) return null;
      setState(() => _selectedViewerIds = selected);
    }
    if (!context.mounted) return;
    context.read<StoriesCubit>().addTextStory(
      text: _controller.text.trim(),
      bgColor: _selectedColor,
      user: widget.currentUser,
      privacy: _selectedPrivacy,
      allowedViewerIds: _selectedViewerIds.toList(),
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
                PrivacyChip(privacy: _selectedPrivacy, onTap: _pickPrivacy),
                const SizedBox(width: 8),
                StorySubmitBar(
                  hasText: _hasText,
                  loading: state is AddStoryLoading,
                  onPressed: () => _share(context),
                ),
              ],
            ),
            body: Column(
              children: [
                Expanded(
                  child: StoryTextEditor(
                    controller: _controller,
                    hasText: _hasText,
                  ),
                ),
                StoryColorPicker(
                  colors: _colors,
                  selected: _selectedColor,
                  onSelect: (c) => setState(() => _selectedColor = c),
                ),
                const SizedBox(height: 14),
              ],
            ),
          ),
        );
      },
    );
  }
}
