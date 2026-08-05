import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:social_media_app/features/social_graph/models/friend_list_item_model.dart';
import '../../../core/presence/widgets/presence_avatar_widget.dart';
import '../../../core/widgets/app_avatar.dart';

class FriendPickerSheet extends StatefulWidget {
  final List<FriendListItemModel> friends;
  final Set<String> selectedIds;
  final Function(String) onToggle;

  const FriendPickerSheet({
    super.key,
    required this.friends,
    required this.selectedIds,
    required this.onToggle,
  });

  @override
  State<FriendPickerSheet> createState() => _FriendPickerSheetState();
}

class _FriendPickerSheetState extends State<FriendPickerSheet> {
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final displayedFriends =
        widget.friends.where((FriendListItemModel friendModel) {
          final name = (friendModel.user.name).toLowerCase();
          return name.contains(_searchQuery.toLowerCase());
        }).toList();

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          behavior: HitTestBehavior.opaque,
          child: Container(
            decoration: BoxDecoration(
              color: theme.scaffoldBackgroundColor,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
            ),
            child: Column(
              children: [
                const SizedBox(height: 12),
                // Handle Bar
                Container(
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(height: 16),

                // Header
                Text(
                  'Select People',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (widget.selectedIds.isNotEmpty)
                  Text(
                    '${widget.selectedIds.length} selected',
                    style: TextStyle(
                      color: theme.primaryColor,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                const SizedBox(height: 16),

                // Search Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (value) => setState(() => _searchQuery = value),
                    decoration: InputDecoration(
                      hintText: 'Search friends...',
                      hintStyle: const TextStyle(
                        color: Colors.grey,
                        fontSize: 15,
                      ),
                      prefixIcon: const Icon(
                        CupertinoIcons.search,
                        color: Colors.grey,
                        size: 20,
                      ),
                      filled: true,
                      fillColor:
                          theme.brightness == Brightness.dark
                              ? Colors.grey.shade900
                              : Colors.grey.shade100,
                      contentPadding: const EdgeInsets.symmetric(vertical: 0),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      suffixIcon:
                          _searchQuery.isNotEmpty
                              ? IconButton(
                                icon: const Icon(
                                  Icons.clear,
                                  size: 18,
                                  color: Colors.grey,
                                ),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _searchQuery = '');
                                },
                              )
                              : null,
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Friends List
                Expanded(
                  child:
                      displayedFriends.isEmpty
                          ? const Center(
                            child: Text(
                              'No friends found.',
                              style: TextStyle(color: Colors.grey),
                            ),
                          )
                          : ListView.builder(
                            controller: scrollController,
                            keyboardDismissBehavior:
                                ScrollViewKeyboardDismissBehavior.manual,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: displayedFriends.length,
                            itemBuilder: (context, i) {
                              final user = displayedFriends[i];
                              final id = user.user.id;
                              final name = user.user.name;
                              final imageUrl = user.user.imageUrl;
                              final isSelected = widget.selectedIds.contains(
                                id,
                              );

                              return Padding(
                                padding: const EdgeInsets.only(bottom: 6),
                                child: InkWell(
                                  onTap: () => widget.onToggle(id),
                                  borderRadius: BorderRadius.circular(14),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 10,
                                    ),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(14),
                                      color:
                                          isSelected
                                              ? theme.primaryColor.withValues(
                                                alpha: 0.08,
                                              )
                                              : Colors.transparent,
                                    ),
                                    child: Row(
                                      children: [
                                        PresenceAvatarWidget(
                                          userId: id,
                                          avatarSize: 46,
                                          showDot: true,
                                          showBorder: true,
                                          child: AppAvatar(
                                            imageUrl: imageUrl,
                                            size: 46,
                                          ),
                                        ),
                                        const SizedBox(width: 14),
                                        Expanded(
                                          child: Text(
                                            name,
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                        AnimatedContainer(
                                          duration: const Duration(
                                            milliseconds: 200,
                                          ),
                                          curve: Curves.easeInOut,
                                          width: 24,
                                          height: 24,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color:
                                                isSelected
                                                    ? theme.primaryColor
                                                    : Colors.transparent,
                                            border: Border.all(
                                              color:
                                                  isSelected
                                                      ? theme.primaryColor
                                                      : Colors.grey.shade400,
                                              width: 1.5,
                                            ),
                                          ),
                                          child:
                                              isSelected
                                                  ? const Icon(
                                                    Icons.check_rounded,
                                                    size: 16,
                                                    color: Colors.white,
                                                  )
                                                  : null,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                ),

                // Done Button
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.primaryColor,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(
                          widget.selectedIds.isEmpty
                              ? 'Done'
                              : 'Done (${widget.selectedIds.length})',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
