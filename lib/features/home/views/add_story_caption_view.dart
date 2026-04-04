import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/themes/app_colors.dart';
import '../../../core/widgets/custom_loading_indicator.dart';
import '../cubit/home_cubit.dart';

class AddStoryCaptionView extends StatefulWidget {
  final File file;
  final HomeCubit homeCubit;

  const AddStoryCaptionView({
    super.key,
    required this.file,
    required this.homeCubit,
  });

  @override
  State<AddStoryCaptionView> createState() => _AddStoryCaptionViewState();
}

class _AddStoryCaptionViewState extends State<AddStoryCaptionView> {
  final TextEditingController _captionController = TextEditingController();

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: widget.homeCubit,
      child: BlocConsumer<HomeCubit, HomeState>(
        listener: (context, state) {
          if (state is AddStorySuccess) {
            Navigator.of(context).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Story Added Successfully',
                  style: Theme.of(context).textTheme.titleSmall!.copyWith(),
                ),
                backgroundColor: Colors.green,
                behavior: SnackBarBehavior.floating,
                duration: Duration(seconds: 1),
              ),
            );
          }
          if (state is AddStoryError) {
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
          return GestureDetector(
            onTap: () => FocusScope.of(context).unfocus(),
            child: Scaffold(
              backgroundColor: Colors.black,
              appBar: AppBar(
                backgroundColor: Colors.black,
                leading: IconButton(
                  icon: const Icon(Icons.close, color: AppColors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                actions: [
                  Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: TextButton(
                      onPressed:
                          state is AddStoryLoading
                              ? null
                              : () {
                                widget.homeCubit.addStoryWithCaption(
                                  file: widget.file,
                                  user: widget.homeCubit.currentUserData!,
                                  caption:
                                      _captionController.text.trim().isEmpty
                                          ? null
                                          : _captionController.text.trim(),
                                );
                              },
                      child:
                          state is AddStoryLoading
                              ? const CustomLoadingIndicator(
                                radius: 10,
                                color: AppColors.white,
                              )
                              : Text(
                                'Share',
                                style: Theme.of(
                                  context,
                                ).textTheme.headlineMedium!.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).primaryColor.withValues(alpha: 0.95),
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                    ),
                  ),
                ],
              ),
              body: Stack(
                children: [
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(widget.file, fit: BoxFit.contain),
                    ),
                  ),

                  Positioned(
                    bottom: 30,
                    left: 16,
                    right: 16,
                    child: TextField(
                      controller: _captionController,
                      style: const TextStyle(color: AppColors.white),
                      maxLines: 3,
                      minLines: 1,
                      maxLength: 150,
                      decoration: InputDecoration(
                        hintText: 'Add a caption...',
                        hintStyle: const TextStyle(color: Colors.white70),
                        filled: true,
                        fillColor: Colors.black54,
                        counterStyle: const TextStyle(color: Colors.white70),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
