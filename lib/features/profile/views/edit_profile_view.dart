import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:social_media_app/core/constants/app_images.dart';
import 'package:social_media_app/core/themes/app_colors.dart';
import 'package:social_media_app/core/themes/background_theme_widget.dart';
import 'package:social_media_app/core/widgets/custom_elevated_button.dart';
import 'package:social_media_app/core/widgets/custom_text_form_field.dart';

class EditProfileView extends StatelessWidget {
  const EditProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return SafeArea(
      bottom: false,
      child: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Scaffold(
          extendBodyBehindAppBar: true,
          appBar: AppBar(
            backgroundColor: AppColors.transparent,
            leading: Icon(Icons.arrow_back_ios_new, color: AppColors.black54),
            title: Text(
              'Edit Profile',
              style: Theme.of(context).textTheme.titleMedium!.copyWith(
                fontWeight: FontWeight.w400,
                color: AppColors.black54,
                fontSize: 20,
              ),
            ),
            centerTitle: true,
          ),
          body: BackgroundThemeWidget(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 2,
                ),
                child: Column(
                  children: [
                    SizedBox(
                      height: size.height * 0.26,
                      child: Stack(
                        children: [
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              Container(
                                height: size.height * 0.22,
                                width: size.width,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.vertical(
                                    top: Radius.circular(20),
                                    bottom: Radius.circular(20),
                                  ),
                                  image: DecorationImage(
                                    image: CachedNetworkImageProvider(
                                      AppImages.defaultBackgroundImg,
                                    ),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),

                              Container(
                                height: size.height * 0.22,
                                width: size.width,
                                decoration: BoxDecoration(
                                  color: AppColors.black26,
                                  borderRadius: BorderRadius.vertical(
                                    top: Radius.circular(20),
                                    bottom: Radius.circular(20),
                                  ),
                                ),
                                child: InkWell(
                                  onTap: () {},
                                  child: Icon(
                                    Icons.edit,
                                    color: AppColors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Align(
                            alignment: Alignment.bottomRight * 0.85,
                            child: SizedBox(
                              height: 70,
                              width: 70,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  DecoratedBox(
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: AppColors.primaryColor,
                                        width: 3,
                                      ),
                                      shape: BoxShape.circle,
                                    ),
                                    child: CircleAvatar(
                                      radius: 50,
                                      backgroundImage:
                                          CachedNetworkImageProvider(
                                            AppImages.defaultUserImg,
                                          ),
                                    ),
                                  ),
                                  CircleAvatar(
                                    radius: 50,
                                    backgroundColor: AppColors.black38,
                                    child: InkWell(
                                      onTap: () {},
                                      child: Icon(
                                        Icons.edit,
                                        color: AppColors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Gap(12),
                    CustomTextFormField(
                      labelText: 'Name',
                      hintText: 'Enter New Name',
                    ),
                    Gap(16),
                    CustomTextFormField(
                      labelText: 'UserName',
                      hintText: 'Enter New UserName',
                    ),
                    Gap(16),
                    CustomTextFormField(
                      labelText: 'Title',
                      hintText: 'Enter New Title',
                    ),
                    Gap(16),
                    CustomTextFormField(
                      labelText: 'Bio',
                      hintText: 'Enter New Bio',
                    ),
                    Gap(20),
                    CustomElevatedButton(
                      maximumSize: Size(240, 50),
                      minimumSize: Size(240, 50),
                      txtBtn: 'Save Changes',
                      onPressed: () {},
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
