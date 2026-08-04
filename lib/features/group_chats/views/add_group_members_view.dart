import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import '../../../core/toast/app_toast.dart';
import '../../../core/widgets/custom_loading_indicator.dart';
import '../../social_graph/services/connections_service.dart';
import '../cubit/group_members_cubit/group_members_cubit.dart';
import '../helpers/group_user_list_tile.dart';
import '../widgets/group_search_field_widget.dart';
import '../widgets/selected_members_section_widget.dart';

class AddGroupMembersView extends StatefulWidget {
  final GroupMembersCubit membersCubit;
  final Set<String> existingMemberIds;
  final String currentUserId;

  const AddGroupMembersView({
    super.key,
    required this.membersCubit,
    required this.existingMemberIds,
    required this.currentUserId,
  });

  @override
  State<AddGroupMembersView> createState() => _AddGroupMembersViewState();
}

class _AddGroupMembersViewState extends State<AddGroupMembersView> {
  final _searchController = TextEditingController();
  List<Map<String, dynamic>> _allUsers = [];
  List<Map<String, dynamic>> _filteredUsers = [];
  final Set<String> _selectedUserIds = {};
  bool _isLoadingUsers = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadUsers();
    _searchController.addListener(_filterUsers);
  }

  Future<void> _loadUsers() async {
    final data = await ConnectionsService().getMyConnections();
    final available =
        data
            .where((u) => !widget.existingMemberIds.contains(u['id'] as String))
            .toList();

    if (mounted) {
      setState(() {
        _allUsers = available;
        _filteredUsers = available;
        _isLoadingUsers = false;
      });
    }
  }

  void _filterUsers() {
    final q = _searchController.text.toLowerCase();
    setState(() {
      _filteredUsers =
          q.isEmpty
              ? _allUsers
              : _allUsers
                  .where((u) => (u['name'] as String).toLowerCase().contains(q))
                  .toList();
    });
  }

  Future<void> _confirmAdd() async {
    if (_selectedUserIds.isEmpty) return;
    setState(() => _isSubmitting = true);

    try {
      final result = await widget.membersCubit.addMembers(
        _selectedUserIds.toList(),
        currentUserId: widget.currentUserId,
      );

      if (result.isFullSuccess) {
        if (mounted) Navigator.pop(context);
      } else if (result.isPartialSuccess) {
        AppToast.error(
          result.failed.length == 1
              ? 'Added ${result.added.length}. One person isn\'t available to join right now.'
              : 'Added ${result.added.length}. ${result.failed.length} people aren\'t available to join right now.',
        );
        if (mounted) Navigator.pop(context);
      } else {
        AppToast.error(
          result.failed.length == 1
              ? "This person isn't available to join the group right now."
              : "These people aren't available to join the group right now.",
        );
      }
    } catch (e) {
      AppToast.error('Failed to add members. Please try again.');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.primaryColor;
    final isDark = theme.brightness == Brightness.dark;

    final isKeyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;
    final bool canAdd = _selectedUserIds.isNotEmpty;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: theme.scaffoldBackgroundColor,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: true,
          title: Text(
            'Add Members',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: primary,
            ),
          ),
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 20,
              color: primary,
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body:
            _isLoadingUsers
                ? const Center(child: CustomLoadingIndicator())
                : _allUsers.isEmpty
                ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.people_outline_rounded,
                        size: 64,
                        color: Colors.grey.shade400,
                      ),
                      const Gap(16),
                      Text(
                        'No new connections to add',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                )
                : CustomScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.manual,
                  slivers: [
                    SliverToBoxAdapter(
                      child: AnimatedSize(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                        child: SelectedMembersSection(
                          selectedUserIds: _selectedUserIds,
                          allUsers: _allUsers,
                          primary: primary,
                          onRemove:
                              (uid) =>
                                  setState(() => _selectedUserIds.remove(uid)),
                        ),
                      ),
                    ),

                    SliverPersistentHeader(
                      pinned: true,
                      delegate: _StickySearchBarDelegate(
                        child: Container(
                          color: theme.scaffoldBackgroundColor,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              GroupSearchField(
                                controller: _searchController,
                                isDark: isDark,
                              ),
                              if (_selectedUserIds.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(
                                    left: 24,
                                    right: 24,
                                    bottom: 8,
                                  ),
                                  child: Text(
                                    '${_selectedUserIds.length} selected',
                                    style: theme.textTheme.labelLarge?.copyWith(
                                      color: primary,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        height: _selectedUserIds.isNotEmpty ? 115.0 : 75.0,
                      ),
                    ),

                    if (_filteredUsers.isEmpty)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 40),
                          child: Center(
                            child: Text(
                              'No people found',
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ),
                        ),
                      )
                    else
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate((
                            context,
                            index,
                          ) {
                            final user = _filteredUsers[index];
                            final uid = user['id'] as String;
                            final isSelected = _selectedUserIds.contains(uid);

                            return GroupUserListTile(
                              user: user,
                              isSelected: isSelected,
                              primary: primary,
                              onTap: () {
                                setState(() {
                                  isSelected
                                      ? _selectedUserIds.remove(uid)
                                      : _selectedUserIds.add(uid);
                                });
                              },
                            );
                          }, childCount: _filteredUsers.length),
                        ),
                      ),

                    const SliverToBoxAdapter(child: Gap(120)),
                  ],
                ),

        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
        floatingActionButton:
            isKeyboardOpen || _isLoadingUsers || _allUsers.isEmpty
                ? null
                : Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Container(
                    width: double.infinity,
                    height: 56,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(100),
                      boxShadow: [
                        if (canAdd)
                          BoxShadow(
                            color: primary.withValues(alpha: 0.35),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: canAdd && !_isSubmitting ? _confirmAdd : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primary,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor:
                            isDark
                                ? Colors.grey.shade800
                                : Colors.grey.shade300,
                        disabledForegroundColor:
                            isDark ? Colors.white54 : Colors.black38,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(100),
                        ),
                      ),
                      child:
                          _isSubmitting
                              ? const CustomLoadingIndicator(
                                color: Colors.white,
                              )
                              : Text(
                                _selectedUserIds.isEmpty
                                    ? 'Add Members'
                                    : 'Add ${_selectedUserIds.length} Members',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.5,
                                ),
                              ),
                    ),
                  ),
                ),
      ),
    );
  }
}

class _StickySearchBarDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  final double height;

  _StickySearchBarDelegate({required this.child, required this.height});

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return child;
  }

  @override
  double get maxExtent => height;

  @override
  double get minExtent => height;

  @override
  bool shouldRebuild(covariant _StickySearchBarDelegate oldDelegate) {
    return oldDelegate.height != height || oldDelegate.child != child;
  }
}
