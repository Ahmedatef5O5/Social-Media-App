import '../../auth/data/models/user_data.dart';

class EditProfileRouteArgs {
  final UserData user;
  final bool autofocusTagline;

  const EditProfileRouteArgs({
    required this.user,
    this.autofocusTagline = false,
  });
}
