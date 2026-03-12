import 'package:flutter/material.dart';
import '../widgets/profile_header.dart';

class ProfileView extends StatelessWidget {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return Center(child: Column(children: [ProfileHeader(size: size)]));
  }
}
