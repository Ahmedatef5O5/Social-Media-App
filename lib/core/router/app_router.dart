import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:social_media_app/core/router/app_routes.dart';
import 'package:social_media_app/core/themes/app_colors.dart';
import 'package:social_media_app/core/widgets/custom_bottom_nav_bar.dart';
import 'package:social_media_app/features/auth/views/auth_view.dart';
import 'package:social_media_app/features/home/cubit/home_cubit.dart';
import 'package:social_media_app/features/home/views/create_post_view.dart';
import 'package:social_media_app/features/profile/views/edit_profile_view.dart';

class AppRouter {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.authRoute:
        return CupertinoPageRoute(
          builder: (_) => const AuthView(),
          settings: settings,
        );

      case AppRoutes.homeRoute:
        return CupertinoPageRoute(
          builder:
              (_) => BlocProvider(
                create: (context) => HomeCubit()..getHomeData(),
                child: const CustomBottomNavBar(),
              ),
          settings: settings,
        );

      case AppRoutes.createPostRoute:
        return CupertinoPageRoute(
          builder:
              (_) => BlocProvider.value(
                value: settings.arguments as HomeCubit,
                child: const CreatePostView(),
              ),
          settings: settings,
        );
      case AppRoutes.editProfileViewRoute:
        return CupertinoPageRoute(
          builder: (_) => const EditProfileView(),
          settings: settings,
        );

      default:
        return CupertinoPageRoute(
          builder:
              (_) => Scaffold(
                body: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        'No route found ${settings.name}',
                        style: TextStyle(
                          color: AppColors.black,
                          fontSize: 22,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          settings: settings,
        );
    }
  }
}
