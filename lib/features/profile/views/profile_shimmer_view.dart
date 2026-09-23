import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:gap/gap.dart';
import 'package:social_media_app/core/themes/app_colors.dart';
import '../utils/profile_header_back_btn_container.dart';

class ProfileShimmerLoading extends StatelessWidget {
  final bool isCurrentUser;

  const ProfileShimmerLoading({super.key, required this.isCurrentUser});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final double bgHeight = size.width / 1.7;
    final double avatarSize = size.width * 0.26;

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
                      height: bgHeight,
                      width: double.infinity,
                      color: Colors.white,
                    ),
                    Positioned(
                      left: 20,
                      bottom: -avatarSize / 2,
                      child: _shimmerCircle(avatarSize),
                    ),
                    Positioned(
                      right: 20,
                      top: bgHeight + avatarSize / 2 - 48,
                      child: Row(
                        children: [
                          _shimmerCircle(40),
                          const Gap(8),
                          _shimmerCircle(40),
                        ],
                      ),
                    ),
                  ],
                ),
                Gap(avatarSize / 2 + 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 150,
                              height: 24,
                              color: Colors.white,
                            ),
                            const Gap(8),
                            Container(
                              width: 100,
                              height: 14,
                              color: Colors.white,
                            ),
                          ],
                        ),
                      ),
                      if (isCurrentUser) _shimmerRect(96, 40),
                    ],
                  ),
                ),
                const Gap(16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children:
                        isCurrentUser
                            ? [
                              Expanded(
                                child: _shimmerRect(double.infinity, 46),
                              ),
                              const Gap(8),
                              _shimmerRect(46, 46),
                            ]
                            : [
                              Expanded(
                                child: _shimmerRect(double.infinity, 46),
                              ),
                              const Gap(8),
                              _shimmerRect(104, 46),
                              const Gap(8),
                              _shimmerRect(46, 46),
                            ],
                  ),
                ),
                const Gap(20),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.grey4.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(
                      4,
                      (index) => Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 28,
                            height: 18,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          const Gap(6),
                          Container(
                            width: 44,
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
                if (!isCurrentUser) ...[
                  const Gap(12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Container(
                      width: double.infinity,
                      height: 112,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ],
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
          Positioned(
            top: MediaQuery.of(context).padding.top - 40,
            child: const ProfileHeaderBackBtnContainer(
              padding: EdgeInsets.zero,
            ),
          ),
      ],
    );
  }

  Widget _shimmerRect(double width, double height) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }

  Widget _shimmerCircle(double diameter) {
    return Container(
      width: diameter,
      height: diameter,
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
      ),
    );
  }
}
