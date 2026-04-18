import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:social_media_app/core/widgets/custom_elevated_button.dart';
import '../../../core/themes/app_colors.dart';
import '../../../core/widgets/custom_loading_indicator.dart';
import '../cubits/home_cubit/home_cubit.dart';

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
    _selectedColor = _colors[0];
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onShareTextStory(BuildContext context) {
    if (_hasText) {
      context.read<HomeCubit>().addTextStory(
        text: _controller.text.trim(),
        bgColor: _selectedColor,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<HomeCubit, HomeState>(
      listener: (context, state) {
        if (state is AddStorySuccess) {
          if (context.mounted) {
            Navigator.of(context).pop();
          }
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Story Added Successfully',
                style: Theme.of(
                  context,
                ).textTheme.titleSmall!.copyWith(color: Colors.white),
              ),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 1),
            ),
          );
        }
        if (state is AddStoryError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 1),
            ),
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
                icon: Icon(Icons.close, size: 24, color: AppColors.white),
              ),
              actionsPadding: EdgeInsets.only(right: 10),
              actions: [
                TextButton(
                  onPressed:
                      state is AddStoryLoading
                          ? null
                          : () => _onShareTextStory(context),
                  child:
                      state is AddStoryLoading
                          ? const CustomLoadingIndicator(
                            radius: 10,
                            color: AppColors.white,
                          )
                          : Text(
                            'Done',
                            style: Theme.of(
                              context,
                            ).textTheme.labelLarge!.copyWith(
                              color:
                                  _hasText
                                      ? AppColors.white
                                      : AppColors.grey2.withValues(alpha: 0.6),
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                ),
              ],
              backgroundColor: AppColors.transparent,
              elevation: 0,
              scrolledUnderElevation: 0,
            ),
            body: Center(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.vertical,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const Gap(25),
                          TextField(
                            controller: _controller,
                            textAlign: TextAlign.center,
                            style: Theme.of(
                              context,
                            ).textTheme.headlineMedium!.copyWith(
                              color: AppColors.white,
                              fontWeight: FontWeight.w400,
                              fontSize: 32,
                            ),

                            maxLines: null,
                            maxLength: 180,
                            decoration: InputDecoration(
                              hintText: 'Write your thought with others',
                              hintStyle: Theme.of(
                                context,
                              ).textTheme.headlineMedium!.copyWith(
                                color: AppColors.white70,
                                fontWeight: FontWeight.w400,
                                fontSize: 32,
                              ),
                              counterText: _hasText ? null : '',
                              counterStyle: TextStyle(
                                color:
                                    _controller.text.length >= 140
                                        ? Colors.red
                                        : AppColors.grey2.withValues(
                                          alpha: 0.6,
                                        ),
                                fontWeight:
                                    _controller.text.length >= 140
                                        ? FontWeight.bold
                                        : null,
                              ),
                              border: InputBorder.none,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Spacer(),
                  SizedBox(
                    height: 50,
                    child: ListView.separated(
                      padding: EdgeInsets.only(left: 28),
                      scrollDirection: Axis.horizontal,
                      itemCount: _colors.length,
                      separatorBuilder: (context, index) => const Gap(12),
                      itemBuilder:
                          (context, index) => InkWell(
                            splashColor: AppColors.transparent,
                            onTap: () {
                              setState(() {
                                _selectedColor = _colors[index];
                              });
                            },
                            child: AnimatedContainer(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: _colors[index],
                                shape: BoxShape.circle,
                                border:
                                    _selectedColor == _colors[index]
                                        ? Border.all(
                                          color: AppColors.white,
                                          width: 3,
                                        )
                                        : null,
                              ),
                              duration: const Duration(milliseconds: 300),
                            ),
                          ),
                    ),
                  ),
                  const Gap(14),
                  CustomElevatedButton(
                    maximumSize: Size(290, 50),
                    minimumSize: Size(290, 50),
                    txtBtn: 'Share Your Story',
                    txtBtnStyle: Theme.of(
                      context,
                    ).textTheme.labelLarge!.copyWith(
                      color:
                          _hasText
                              ? Theme.of(context).primaryColor
                              : AppColors.black12.withValues(alpha: 0.25),

                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),

                    bgColor: AppColors.white,
                    isLoading: state is AddStoryLoading,
                    onPressed: () => _onShareTextStory(context),
                  ),
                  const Gap(50),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
