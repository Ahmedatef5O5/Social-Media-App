import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:social_media_app/core/utilities/app_validators.dart';

class PasswordStrengthBar extends StatelessWidget {
  final String password;
  const PasswordStrengthBar({super.key, required this.password});

  @override
  Widget build(BuildContext context) {
    final strength = AppValidators.calculatePasswordStrength(password);
    Color color = Colors.red;
    String label = 'Weak';
    if (strength > 0.25) {
      color = Colors.orange;
      label = "Fair";
    }
    if (strength > 0.5) {
      color = Colors.blue;
      label = "Good";
    }
    if (strength > 0.75) {
      color = Colors.green;
      label = "Strong";
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Row(
          children: [
            ...List.generate(4, (index) {
              bool isActive = strength >= (index + 1) * 0.25;
              return Expanded(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: EdgeInsets.symmetric(horizontal: index == 0 ? 0 : 2),
                  height: 4,
                  decoration: BoxDecoration(
                    color:
                        isActive ? color : Colors.grey.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              );
            }),
          ],
        ),
        const Gap(4),
        Text(
          password.isEmpty ? "" : label,
          textAlign: TextAlign.right,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}
