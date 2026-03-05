import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:social_media_app/core/themes/background_theme_widget.dart';
import 'package:social_media_app/core/widgets/custom_elevated_button.dart';
import '../../../core/router/app_routes.dart';
import '../../auth/logic/auth_cubit/auth_cubit.dart';

class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => AuthCubit(),
      child: BlocListener<AuthCubit, AuthState>(
        listener: (context, state) {
          if (state is AuthSignedOut) {
            Navigator.of(
              context,
              rootNavigator: true,
            ).pushNamedAndRemoveUntil(AppRoutes.authRoute, (route) => false);
          } else if (state is AuthFailure) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.errMsg)));
          }
        },
        child: PopScope(
          canPop: false,
          child: Scaffold(
            body: BackgroundThemeWidget(
              child: Center(
                child: Builder(
                  builder: (context) {
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Gap(30),
                        Text('Home View'),
                        Gap(140),
                        CustomElevatedButton(
                          maximumSize: Size(150, 50),
                          minimumSize: Size(150, 50),
                          txtBtn: 'log out',
                          onPressed: () {
                            context.read<AuthCubit>().signOut();
                          },
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
