import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

class DiscoverView extends StatelessWidget {
  const DiscoverView({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          Gap(20),
          const Text(
            'Welcome to the Discover Page',
            style: TextStyle(fontSize: 24),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              // Add your discover logic here
            },
            child: const Text('Discover'),
          ),
        ],
      ),
    );
  }
}
