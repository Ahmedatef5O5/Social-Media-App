import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:gap/gap.dart';
import '../../../core/toast/app_toast.dart';
import 'package:social_media_app/core/widgets/custom_loading_indicator.dart';
import 'package:social_media_app/features/social_graph/services/connections_service.dart';
import '../cubit/group_list_cubit/group_list_cubit.dart';
import '../helpers/group_user_list_tile.dart';
import '../services/group_chat_services.dart';
import '../widgets/group_header_section_widget.dart';
import '../widgets/group_search_field_widget.dart';
import '../widgets/selected_members_section_widget.dart';

class CreateGroupView extends StatefulWidget {
  const CreateGroupView({super.key});

  @override
  State<CreateGroupView> createState() => _CreateGroupViewState();
}

class _CreateGroupViewState extends State<CreateGroupView> {
  final _nameController = TextEditingController();
  final _searchController = TextEditingController();

  File? _groupImage;
  bool _isCreating = false;

  List<Map<String, dynamic>> _allUsers = [];
  List<Map<String, dynamic>> _filteredUsers = [];
  final Set<String> _selectedUserIds = {};

  @override
  void initState() {
    super.initState();
    _loadUsers();
    _searchController.addListener(_filterUsers);
    _nameController.addListener(() => setState(() {}));
  }

  Future<void> _loadUsers() async {
    final data = await ConnectionsService().getMyConnections();
    if (mounted) {
      setState(() {
        _allUsers = data;
        _filteredUsers = _allUsers;
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

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => _groupImage = File(picked.path));
    }
  }

  bool get _canCreate =>
      _nameController.text.trim().isNotEmpty && _selectedUserIds.isNotEmpty;

  Future<void> _createGroup() async {
    if (!_canCreate) return;

    setState(() => _isCreating = true);

    try {
      String? avatarUrl;
      String? avatarPublicId;

      if (_groupImage != null) {
        final result = await context
            .read<GroupChatServices>()
            .uploadGroupAvatar(_groupImage!);
        avatarUrl = result.secureUrl;
        avatarPublicId = result.publicId;
      }
      if (!mounted) return;
      final group = await context.read<GroupListCubit>().createGroup(
        name: _nameController.text.trim(),
        avatarUrl: avatarUrl,
        avatarPublicId: avatarPublicId,
        memberIds: _selectedUserIds.toList(),
      );

      if (mounted) Navigator.pop(context, group);
    } catch (e) {
      AppToast.error('Failed to create group: $e');
    } finally {
      if (mounted) setState(() => _isCreating = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = Theme.of(context).primaryColor;
    final isDark = theme.brightness == Brightness.dark;
    final isKeyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;

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
            'New Group',
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
        body: CustomScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.manual,
          slivers: [
            SliverToBoxAdapter(
              child: GroupHeaderSection(
                groupImage: _groupImage,
                onPickImage: _pickImage,
                controller: _nameController,
                primary: primary,
                isDark: isDark,
              ),
            ),

            SliverToBoxAdapter(
              child: AnimatedSize(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                child: SelectedMembersSection(
                  selectedUserIds: _selectedUserIds,
                  allUsers: _allUsers,
                  primary: primary,
                  onRemove:
                      (uid) => setState(() => _selectedUserIds.remove(uid)),
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
                            '${_selectedUserIds.length} members selected',
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

            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
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
            isKeyboardOpen
                ? null
                : Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Container(
                    width: double.infinity,
                    height: 56,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(100),
                      boxShadow: [
                        if (_canCreate)
                          BoxShadow(
                            color: primary.withValues(alpha: 0.35),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed:
                          _canCreate && !_isCreating ? _createGroup : null,
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
                          _isCreating
                              ? const CustomLoadingIndicator(
                                color: Colors.white,
                              )
                              : Text(
                                _selectedUserIds.isEmpty
                                    ? 'Create Group'
                                    : 'Create Group (${_selectedUserIds.length})',
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
