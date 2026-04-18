import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/themes/app_colors.dart';
import '../../home/cubits/home_cubit/home_cubit.dart';
import '../widgets/story_color_picker.dart';
import '../widgets/story_submit_bar.dart';
import '../widgets/story_text_editor.dart';

class CreateTextStoryView extends StatefulWidget {
  const CreateTextStoryView({super.key});

  @override
  State<CreateTextStoryView> createState() => _CreateTextStoryViewState();
}

class _CreateTextStoryViewState extends State<CreateTextStoryView> {
  final TextEditingController _controller = TextEditingController();
  bool _hasText = false;

  late List<Color> _colors;
  late Color _selectedColor;

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

  void _share(BuildContext context) {
    if (!_hasText) return;

    context.read<HomeCubit>().addTextStory(
      text: _controller.text.trim(),
      bgColor: _selectedColor,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<HomeCubit, HomeState>(
      listener: (context, state) {
        if (state is AddStorySuccess) {
          Navigator.of(context).pop();

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Story Added Successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }

        if (state is AddStoryError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message), backgroundColor: Colors.red),
          );
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
