import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:social_media_app/core/themes/background_theme_widget.dart';
import '../widgets/add_post_options_bottom_sheet.dart';
import '../widgets/create_post_header_section.dart';
import '../widgets/create_post_input_field.dart';
import '../widgets/create_post_user_info.dart';

class CreatePostView extends StatefulWidget {
  const CreatePostView({super.key});

  @override
  State<CreatePostView> createState() => _CreatePostViewState();
}

class _CreatePostViewState extends State<CreatePostView> {
  final TextEditingController _textEditingController = TextEditingController();
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _textEditingController.addListener(() {
      setState(() {
        _hasText = _textEditingController.text.trim().isNotEmpty;
      });
    });
  }

  @override
  void dispose() {
    _textEditingController.removeListener(() {});
    _textEditingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        body: Stack(
          children: [
            BackgroundThemeWidget(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Gap(12),
                    CreatePostHeaderSection(hasText: _hasText),
                    Gap(12),
                    CreatePostUserInfo(),
                    Gap(12),
                    CreatePostInputField(
                      textEditingController: _textEditingController,
                      hasText: _hasText,
                    ),
                  ],
                ),
              ),
            ),
            AddPostOptionsBottomSheet(),
          ],
        ),
      ),
    );
  }
}
