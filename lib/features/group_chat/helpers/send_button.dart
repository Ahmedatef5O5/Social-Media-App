import 'package:flutter/material.dart';

class SendButton extends StatelessWidget {
  final Color primary;
  final VoidCallback onTap;

  const SendButton({
    super.key,
    required this.primary,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: primary,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.send_rounded, color: Colors.white),
        ),
      );
}