import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:social_media_app/core/helpers/formatted_date.dart';
import 'package:social_media_app/core/widgets/custom_loading_indicator.dart';
import 'package:social_media_app/features/chats/models/chat_user_model.dart';
import 'package:social_media_app/features/chats/widgets/full_screen_media_view.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/utilities/supabase_constants.dart';
import '../../../core/widgets/custom_user_profile_image_section.dart';
import '../../calls/cubit/call_cubit.dart';
import '../../calls/model/call_model.dart';
import '../helper/call_actions.dart';
import '../helper/safe_pop.dart';
import '../services/chat_services.dart';

class ReceiverProfileView extends StatelessWidget {
  final ChatUserModel receiverUser;

  const ReceiverProfileView({super.key, required this.receiverUser});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            Stack(
              children: [
                CustomUserProfileImagesSection(
                  avatarUrl: receiverUser.imageUrl,
                  heroTag: receiverUser.id,
                  isProfileHeader: true,
                ),
                Align(
                  alignment: Alignment.topLeft,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 12.0),
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => safePop(context),
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
            ),

            const Gap(10),

            Text(
              receiverUser.name,
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            if (receiverUser.lastSeen != null)
              Text(
                FormattedDate.getLastSeen(receiverUser.lastSeen!) == 'Online'
                    ? 'Online'
                    : "Last seen: ${FormattedDate.getLastSeen(receiverUser.lastSeen!)}",
                style: const TextStyle(color: Colors.grey),
              ),

            const Gap(25),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildOptionItem(
                  context,
                  Icons.message_outlined,
                  "Message",
                  () => safePop(context),
                ),

                _buildOptionItem(
                  context,
                  Icons.call_outlined,
                  "Call",
                  () async {
                    final call = await CallActions.buildCall(
                      type: CallType.audio,
                      receiverId: receiverUser.id,
                      receiverName: receiverUser.name,
                      receiverAvatar: receiverUser.imageUrl ?? '',
                    );
                    if (call == null || !context.mounted) return;

                    context.read<CallCubit>().makeAudioCall(call);
                  },
                ),

                _buildOptionItem(
                  context,
                  Icons.videocam_outlined,
                  "Video",
                  () async {
                    final call = await CallActions.buildCall(
                      type: CallType.video,
                      receiverId: receiverUser.id,
                      receiverName: receiverUser.name,
                      receiverAvatar: receiverUser.imageUrl ?? '',
                    );
                    if (call == null || !context.mounted) return;

                    context.read<CallCubit>().makeAudioCall(call);
                  },
                ),
                _buildOptionItem(
                  context,
                  Icons.notifications_off_outlined,
                  "Mute",
                  () {},
                ),
              ],
            ),

            const Divider(height: 40, thickness: 8, color: Color(0x00fff5f5)),

            _buildMediaSection(context),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionItem(
    BuildContext context,
    IconData icon,
    String label,
    VoidCallback onTap,
  ) {
    return Column(
      children: [
        IconButton(
          onPressed: onTap,
          icon: Icon(icon, color: Theme.of(context).primaryColor),
          style: IconButton.styleFrom(
            backgroundColor: Theme.of(
              context,
            ).primaryColor.withValues(alpha: 0.1),
            padding: const EdgeInsets.all(12),
          ),
        ),
        const Gap(4),
        Text(
          label,
          style: TextStyle(color: Theme.of(context).primaryColor, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildMediaSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(
            left: 16,
            right: 16,
            top: 10,
            bottom: 4,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Media, links, and docs",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              TextButton(
                onPressed: () {},
                child: Text(
                  "See all",
                  style: Theme.of(context).textTheme.titleSmall!.copyWith(
                    color: Theme.of(
                      context,
                    ).primaryColor.withValues(alpha: 0.85),
                  ),
                ),
              ),
            ],
          ),
        ),
        FutureBuilder<List<Map<String, dynamic>>>(
          future: ChatServices().getChatMedia(receiverUser.id),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox(
                height: 100,
                child: Center(child: CustomLoadingIndicator()),
              );
            }

            final allMedia = snapshot.data ?? [];

            if (allMedia.isEmpty) {
              return SizedBox(
                height: MediaQuery.sizeOf(context).height * 0.3,
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Center(
                    child: Text(
                      "No media shared yet",
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                ),
              );
            }

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GridView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: allMedia.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  crossAxisSpacing: 1,
                  mainAxisSpacing: 6,
                  childAspectRatio: 0.9,
                ),
                itemBuilder: (context, index) {
                  final item = allMedia[index];
                  final type = item[MessagesColumns.messageType];

                  String? mediaUrl =
                      (type == 'image')
                          ? item[MessagesColumns.imageUrl]
                          : (type == 'video')
                          ? item[MessagesColumns.videoUrl]
                          : item[MessagesColumns.voiceUrl];

                  if (mediaUrl == null) return const SizedBox.shrink();
                  return GestureDetector(
                    onTap: () {
                      if (type == 'image') {
                        _openFullScreenImage(context, mediaUrl, 'media-$index');
                      } else if (type == 'video') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) =>
                                    FullScreenMediaView(imageUrl: mediaUrl),
                          ),
                        );
                      } else if (type == 'voice') {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Playing audio..."),
                            duration: Duration(seconds: 1),
                          ),
                        );
                      }
                    },
                    child: Container(
                      width: 110,
                      margin: const EdgeInsets.only(right: 10),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: _buildMediaPreview(type, mediaUrl),
                      ),
                    ),
                  );
                },
              ),
            );
          },
        ),
        const Gap(20),
      ],
    );
  }

  Widget _buildMediaPreview(String type, String? url) {
    if (type == 'image' && url != null) {
      return CachedNetworkImage(
        imageUrl: url,
        fit: BoxFit.cover,
        errorWidget: (context, url, error) => const Icon(Icons.broken_image),
      );
    } else if (type == 'video') {
      return Stack(
        alignment: Alignment.center,
        children: [
          Container(color: Colors.black87),
          const Icon(Icons.play_circle_fill, color: Colors.white, size: 35),
          const Positioned(
            bottom: 5,
            right: 5,
            child: Icon(Icons.videocam, color: Colors.white, size: 14),
          ),
        ],
      );
    } else if (type == 'voice') {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.mic, color: Colors.blue, size: 30),
          Gap(4),
          Text(
            "Voice",
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
          ),
        ],
      );
    }
    return const Icon(Icons.insert_drive_file);
  }

  void _openFullScreenImage(BuildContext context, String url, String tag) {
    Navigator.of(context, rootNavigator: true).pushNamed(
      AppRoutes.fullScreenImageViewRoute,
      arguments: {'url': url, 'tag': tag, 'isAsset': false},
    );
  }
}
