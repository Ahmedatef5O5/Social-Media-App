import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:social_media_app/features/search/utils/chat_tile_skeleton_list.dart';
import '../../../core/presence/widgets/presence_avatar_widget.dart';
import '../../../core/widgets/app_avatar.dart';
import '../../group_chats/models/group_model.dart';
import '../../group_chats/services/group_chat_services.dart';
import '../../social_graph/services/connections_service.dart';
import '../models/forward_target_selection.dart';

class ForwardTargetPickerView extends StatefulWidget {
  final int messageCount;

  const ForwardTargetPickerView({super.key, this.messageCount = 1});

  @override
  State<ForwardTargetPickerView> createState() =>
      _ForwardTargetPickerViewState();
}

class _ForwardTargetPickerViewState extends State<ForwardTargetPickerView> {
  List<Map<String, dynamic>> _people = [];
  List<GroupModel> _groups = [];

  final Set<String> _selectedUserIds = {};
  final Set<String> _selectedGroupIds = {};

  bool _isLoading = true;
  String? _errorMessage;

  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final results = await Future.wait([
        ConnectionsService().getMyConnections(),
        GroupChatServices().getMyGroups(),
      ]);
      if (mounted) {
        setState(() {
          _people = results[0] as List<Map<String, dynamic>>;
          _groups = results[1] as List<GroupModel>;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('ForwardTargetPickerView load error: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load your chats.';
          _isLoading = false;
        });
      }
    }
  }

  void _toggleUser(String id) {
    setState(() {
      if (_selectedUserIds.contains(id)) {
        _selectedUserIds.remove(id);
      } else {
        _selectedUserIds.add(id);
      }
    });
  }

  void _toggleGroup(String id) {
    setState(() {
      if (_selectedGroupIds.contains(id)) {
        _selectedGroupIds.remove(id);
      } else {
        _selectedGroupIds.add(id);
      }
    });
  }

  int get _totalSelected => _selectedUserIds.length + _selectedGroupIds.length;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final displayedPeople =
        _people.where((user) {
          final name = (user['name'] as String? ?? '').toLowerCase();
          return name.contains(_searchQuery.toLowerCase());
        }).toList();

    final displayedGroups =
        _groups
            .where(
              (g) => g.name.toLowerCase().contains(_searchQuery.toLowerCase()),
            )
            .toList();

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      behavior: HitTestBehavior.opaque,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          elevation: 0,
          scrolledUnderElevation: 0,
          shadowColor: Colors.transparent,
          backgroundColor: theme.scaffoldBackgroundColor,
          centerTitle: true,
          title: Column(
            children: [
              Text(
                'Forward ${widget.messageCount > 1 ? '${widget.messageCount} messages' : 'message'}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              if (_totalSelected > 0)
                Text(
                  '$_totalSelected selected',
                  style: TextStyle(
                    color: theme.primaryColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
            ],
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Column(
          children: [
            if (_errorMessage == null &&
                (_isLoading || _people.isNotEmpty || _groups.isNotEmpty))
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: TextField(
                  controller: _searchController,
                  onChanged: (value) => setState(() => _searchQuery = value),
                  decoration: InputDecoration(
                    hintText: 'Search people or groups...',
                    hintStyle: const TextStyle(color: Colors.grey),
                    prefixIcon: const Icon(
                      CupertinoIcons.search,
                      color: Colors.grey,
                    ),
                    filled: true,
                    fillColor:
                        theme.brightness == Brightness.dark
                            ? Colors.grey.shade900
                            : Colors.grey.shade100,
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
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

            Expanded(
              child: _buildContent(displayedPeople, displayedGroups, theme),
            ),

            if (!_isLoading && _errorMessage == null)
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed:
                          _totalSelected == 0
                              ? null
                              : () => Navigator.pop(
                                context,
                                ForwardTargetSelection(
                                  userIds: _selectedUserIds,
                                  groups: {
                                    for (final group in _groups)
                                      if (_selectedGroupIds.contains(group.id))
                                        group.id: group.name,
                                  },
                                ),
                              ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.primaryColor,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: theme.primaryColor.withValues(
                          alpha: 0.35,
                        ),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        _totalSelected == 0 ? 'Send' : 'Send ($_totalSelected)',
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
  }

  Widget _buildContent(
    List<Map<String, dynamic>> displayedPeople,
    List<GroupModel> displayedGroups,
    ThemeData theme,
  ) {
    if (_isLoading) {
      return const ChatTileSkeletonList();
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 60,
              color: Colors.red.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _load,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.primaryColor.withValues(alpha: 0.1),
                foregroundColor: theme.primaryColor,
                elevation: 0,
              ),
            ),
          ],
        ),
      );
    }

    if (_people.isEmpty && _groups.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: theme.primaryColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  CupertinoIcons.paperplane,
                  size: 50,
                  color: theme.primaryColor,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Nowhere to forward yet',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              const Text(
                'Add friends, follow people, or join a group first.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, height: 1.5),
              ),
            ],
          ),
        ),
      );
    }

    if (displayedPeople.isEmpty && displayedGroups.isEmpty) {
      return const Center(
        child: Text(
          'No results found.',
          style: TextStyle(color: Colors.grey, fontSize: 16),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      children: [
        if (displayedGroups.isNotEmpty) ...[
          _sectionHeader('Groups', theme),
          for (final group in displayedGroups) _groupTile(group, theme),
          const SizedBox(height: 8),
        ],
        if (displayedPeople.isNotEmpty) ...[
          _sectionHeader('People', theme),
          for (final user in displayedPeople) _personTile(user, theme),
        ],
      ],
    );
  }

  Widget _sectionHeader(String title, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: theme.primaryColor,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  Widget _selectionCircle(bool isSelected, ThemeData theme) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isSelected ? theme.primaryColor : Colors.transparent,
        border: Border.all(
          color: isSelected ? theme.primaryColor : Colors.grey.shade400,
          width: 1.5,
        ),
      ),
      child:
          isSelected
              ? const Icon(Icons.check_rounded, size: 16, color: Colors.white)
              : null,
    );
  }

  Widget _personTile(Map<String, dynamic> user, ThemeData theme) {
    final id = user['id'] as String;
    final name = user['name'] as String? ?? 'Unknown';
    final isSelected = _selectedUserIds.contains(id);

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: InkWell(
        onTap: () => _toggleUser(id),
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color:
                isSelected
                    ? theme.primaryColor.withValues(alpha: 0.08)
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
                  imageUrl: user['image_url'] as String?,
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
              _selectionCircle(isSelected, theme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _groupTile(GroupModel group, ThemeData theme) {
    final isSelected = _selectedGroupIds.contains(group.id);
    final hasAvatar = group.avatarUrl?.isNotEmpty == true;

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: InkWell(
        onTap: () => _toggleGroup(group.id),
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color:
                isSelected
                    ? theme.primaryColor.withValues(alpha: 0.08)
                    : Colors.transparent,
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 23,
                backgroundColor: theme.primaryColor.withValues(alpha: 0.12),
                backgroundImage:
                    hasAvatar ? NetworkImage(group.avatarUrl!) : null,
                child:
                    !hasAvatar
                        ? Text(
                          group.name.isNotEmpty
                              ? group.name[0].toUpperCase()
                              : '#',
                          style: TextStyle(
                            color: theme.primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                        : null,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  group.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              _selectionCircle(isSelected, theme),
            ],
          ),
        ),
      ),
    );
  }
}
