import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:social_media_app/core/themes/background_theme_widget.dart';
import 'package:social_media_app/features/home/cubit/home_cubit.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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
    return BlocConsumer<HomeCubit, HomeState>(
      listener: (context, state) {
        if (state is PostCreated) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Post Published Successfully'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
          Navigator.pop(context);
        } else if (state is PostCreateError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      builder: (context, state) {
        final userFromDb = context.read<HomeCubit>().currentUserData;

        if (userFromDb != null) {
          debugPrint("✅ Data loaded from Database: ${userFromDb.name}");
        } else {
          debugPrint("⚠️ Using Auth Metadata (Backup)");
        }
        final homeCubit = context.read<HomeCubit>();
        final user = homeCubit.currentUserData;
        final authUser = Supabase.instance.client.auth.currentUser;

        final displayName =
            user?.name ?? authUser?.userMetadata?['full_name'] ?? 'User';
        final displayImage =
            user?.imageUrl ?? authUser?.userMetadata?['avatar_url'];
        // final currentUser = Supabase.instance.client.auth.currentUser;
        // debugPrint("User Metadata: ${currentUser?.userMetadata}");
        // if (user == null) {
        //   return CupertinoActivityIndicator(
        //     color: Theme.of(context).primaryColor,
        //   );
        // }
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
                        CreatePostHeaderSection(
                          isLoading: state is PostCreating,
                          hasText: _hasText,
                          onTap: () {
                            homeCubit.createPost(
                              text: _textEditingController.text.trim(),
                            );
                          },
                        ),
                        Gap(12),
                        CreatePostUserInfo(
                          userName: displayName,
                          // currentUser.userMetadata?['full_name'] ?? 'User',
                          userImageUrl: displayImage,
                          // userImageUrl: currentUser.userMetadata?['avatar_url'],
                        ),
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
      },
    );
  }
}
