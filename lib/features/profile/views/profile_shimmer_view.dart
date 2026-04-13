import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:gap/gap.dart';
import 'package:social_media_app/core/themes/app_colors.dart';

class ProfileShimmerLoading extends StatelessWidget {
  final bool isCurrentUser;

  const ProfileShimmerLoading({super.key, required this.isCurrentUser});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Stack(
      children: [
        Shimmer.fromColors(
          baseColor: isDark ? Colors.grey[800]! : Colors.grey[300]!,
          highlightColor: isDark ? Colors.grey[700]! : Colors.grey[100]!,
          child: SingleChildScrollView(
            physics: const NeverScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      height: (size.width / 1.7),
                      width: double.infinity,
                      color: Colors.white,
                    ),
                    Positioned(
                      left: 20,
                      bottom: -40,
                      child: Container(
                        width: size.width * 0.26,
                        height: size.width * 0.26,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    if (!isCurrentUser)
                      Positioned(
                        right: 20,
                        top: (size.width / 1.7) + 10,
                        child: Column(
                          children: [
                            Container(
                              width: 166,
                              height: 42,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(25),
                              ),
                            ),
                            const Gap(8),
                            Container(
                              width: 166,
                              height: 42,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(25),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const Gap(50),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(width: 150, height: 24, color: Colors.white),
                      const Gap(8),
                      Container(width: 100, height: 14, color: Colors.white),
                    ],
                  ),
                ),
                const Gap(25),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    width: double.infinity,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ),
                const Gap(20),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  height: 75,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.grey4.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(
                      3,
                      (index) => Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 40,
                            height: 16,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          const Gap(6),
                          Container(
                            width: 60,
                            height: 10,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.6),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const Gap(20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Container(width: 80, height: 20, color: Colors.white),
                    Container(width: 80, height: 20, color: Colors.white),
                  ],
                ),
                const Gap(10),
                const Divider(),
                const Gap(15),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const Gap(12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 120,
                                height: 14,
                                color: Colors.white,
                              ),
                              const Gap(6),
                              Container(
                                width: 80,
                                height: 10,
                                color: Colors.white,
                              ),
                            ],
                          ),
                        ],
                      ),
                      const Gap(15),
                      Container(
                        width: double.infinity,
                        height: 12,
                        color: Colors.white,
                      ),
                      const Gap(8),
                      Container(
                        width: size.width * 0.7,
                        height: 12,
                        color: Colors.white,
                      ),
                      const Gap(15),
                      Container(
                        width: double.infinity,
                        height: 200,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      const Gap(15),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 24,
                                height: 24,
                                color: Colors.white,
                              ),
                              const Gap(20),
                              Container(
                                width: 24,
                                height: 24,
                                color: Colors.white,
                              ),
                              const Gap(20),
                              Container(
                                width: 24,
                                height: 24,
                                color: Colors.white,
                              ),
                            ],
                          ),
                          Container(width: 24, height: 24, color: Colors.white),
                        ],
                      ),
                    ],
                  ),
                ),
                const Gap(20),
              ],
            ),
          ),
        ),

        if (!isCurrentUser)
          Align(
            alignment: Alignment.topLeft,
            child: Padding(
              padding: const EdgeInsets.only(top: 12.0),
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => Navigator.of(context).pop(),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.3),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.arrow_back_ios_new,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
