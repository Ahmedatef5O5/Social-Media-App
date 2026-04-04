import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/widgets/custom_elevated_button.dart';
import '../cubits/edit_profile_cubit/edit_profile_cubit.dart';

class EditProfileActionButton extends StatelessWidget {
  final VoidCallback onPressed;
  const EditProfileActionButton({super.key, required this.onPressed});
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<EditProfileCubit, EditProfileState>(
      builder: (context, state) {
        return CustomElevatedButton(
          maximumSize: Size(240, 50),
          minimumSize: Size(240, 50),
          txtBtn: 'Save Changes',
          txtBtnStyle: Theme.of(
            context,
          ).textTheme.titleMedium!.copyWith(color: Colors.white),
          isLoading: state is EditProfileLoading,
          onPressed: state is EditProfileLoading ? null : onPressed,
        );
      },
    );
  }
}
