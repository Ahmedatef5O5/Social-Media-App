import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:social_media_app/core/themes/app_colors.dart';
import 'package:social_media_app/core/themes/background_theme_widget.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/widgets/custom_elevated_button.dart';
import '../../auth/cubit/auth_cubit/auth_cubit.dart';

class SettingsView extends StatelessWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    return BackgroundThemeWidget(
      child: Scaffold(
        backgroundColor: AppColors.transparent,
        appBar: AppBar(backgroundColor: AppColors.transparent, elevation: 0),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Gap(140),
              Text('Settings View'),
              const Gap(340),
              BlocConsumer<AuthCubit, AuthState>(
                listener: (context, state) {
                  if (state is AuthSignedOut) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Log out Successfully',
                          style: Theme.of(context).textTheme.titleSmall!
                              .copyWith(color: AppColors.white),
                        ),
                        backgroundColor: Colors.redAccent,
                        behavior: SnackBarBehavior.floating,
                        duration: const Duration(seconds: 1),
                      ),
                    );
                    Navigator.of(
                      context,
                      rootNavigator: true,
                    ).pushNamedAndRemoveUntil(
                      AppRoutes.authRoute,
                      (route) => false,
                    );
                  } else if (state is AuthFailure) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text(state.errMsg)));
                  }
                },
                buildWhen:
                    (previous, current) =>
                        current is AuthSignedOut ||
                        current is AuthFailure ||
                        current is AuthLoading,
                builder: (context, state) {
                  if (state is AuthLoading) {
                    return CustomElevatedButton(
                      maximumSize: Size(150, 50),
                      minimumSize: Size(150, 50),

                      txtBtn: 'log out',
                      txtBtnStyle: Theme.of(
                        context,
                      ).textTheme.titleMedium!.copyWith(color: AppColors.white),
                      onPressed: null,
                      isLoading: true,
                    );
                  }
                  return CustomElevatedButton(
                    maximumSize: Size(150, 50),
                    minimumSize: Size(150, 50),
                    txtBtn: 'log out',
                    txtBtnStyle: Theme.of(
                      context,
                    ).textTheme.titleMedium!.copyWith(color: AppColors.white),
                    onPressed: () {
                      context.read<AuthCubit>().signOut();
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
