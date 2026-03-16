import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/widgets/custom_elevated_button.dart';
import '../../auth/logic/auth_cubit/auth_cubit.dart';

class SettingsView extends StatelessWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          Gap(440),
          BlocConsumer<AuthCubit, AuthState>(
            listener: (context, state) {
              if (state is AuthSignedOut) {
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
                  onPressed: null,
                  isLoading: true,
                );
              }
              return CustomElevatedButton(
                maximumSize: Size(150, 50),
                minimumSize: Size(150, 50),
                txtBtn: 'log out',
                onPressed: () {
                  context.read<AuthCubit>().signOut();
                },
              );
            },
          ),
        ],
      ),
    );
  }
}
