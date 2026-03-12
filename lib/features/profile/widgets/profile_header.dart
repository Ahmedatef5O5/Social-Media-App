import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:gap/gap.dart';
import '../../../core/constants/app_images.dart';
import '../../../core/themes/app_colors.dart';
import '../../../core/widgets/custom_elevated_button.dart';

class ProfileHeader extends StatelessWidget {
  const ProfileHeader({super.key, required this.size});

  final Size size;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: size.height * 0.36,

          child: Stack(
            children: [
              Container(
                height: size.height * 0.3,
                width: size.width,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.vertical(
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
              Positioned(
                bottom: 0,
                left: size.width * 0.22,
                right: size.width * 0.2,
                child: SizedBox(
                  height: 112,
                  width: 112,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: AppColors.primaryColor,
                        width: 4,
                      ),
                      shape: BoxShape.circle,
                      image: DecorationImage(
                        image: CachedNetworkImageProvider(
                          AppImages.defaultUserImg,
                        ),
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        Gap(16),
        Text('user name'),
        Gap(8),
        Text('Not Provided'),
        Gap(16),
        CustomElevatedButton(
          maximumSize: Size(220, 90),
          minimumSize: Size(120, 50),
          txtBtn: 'EDIT PROFILE',

          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          side: BorderSide(color: AppColors.grey3, width: 1.6),
          elevation: 0,
          bgColor: AppColors.white,
          txtColor: AppColors.black54,
          onPressed: () {},
        ),
      ],
    );
  }
}
