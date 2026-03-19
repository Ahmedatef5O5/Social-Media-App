import 'package:flutter/cupertino.dart';
import 'package:gap/gap.dart';
import '../../../core/themes/app_colors.dart';
import '../../auth/data/models/user_data.dart';

class ProfileDetailsWidgetTab extends StatelessWidget {
  final UserData user;
  const ProfileDetailsWidgetTab({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return ListView(
      primary: false,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(20),
      children: [
        _buildInfoRow(CupertinoIcons.mail, 'Email', user.email),
        const Gap(15),
        _buildInfoRow(CupertinoIcons.person_fill, 'Name', user.name),
        const Gap(15),
        _buildInfoRow(CupertinoIcons.person_circle, 'username', user.userName),
        const Gap(15),
        _buildInfoRow(CupertinoIcons.info, 'title', user.title),
        const Gap(15),
        _buildInfoRow(CupertinoIcons.info, 'Bio', user.bio),
        const Gap(15),
        _buildInfoRow(CupertinoIcons.calendar, 'Joined', 'March 2026'),
        const Gap(50),
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String title, String? value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.primaryColor),
        const Gap(12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(color: AppColors.grey, fontSize: 12),
              ),
              Text(
                (value == null || value.isEmpty)
                    ? 'No $title provided yet.'
                    : value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
