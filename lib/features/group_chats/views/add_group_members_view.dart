import 'package:flutter/material.dart';
import '../../../core/toast/app_toast.dart';
import '../../../core/widgets/custom_loading_indicator.dart';
import '../../social_graph/services/connections_service.dart';
import '../cubit/group_members_cubit/group_members_cubit.dart';
import '../widgets/group_users_list.dart';

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
      await widget.membersCubit.addMembers(
        _selectedUserIds.toList(),
        currentUserId: widget.currentUserId,
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      AppToast.error('Failed to add members: $e');
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
    final primary = Theme.of(context).primaryColor;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Members'),
        actions: [
          TextButton(
            onPressed:
                (_isSubmitting || _selectedUserIds.isEmpty)
                    ? null
                    : _confirmAdd,
            child:
                _isSubmitting
                    ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CustomLoadingIndicator(),
                    )
                    : Text(
                      'Add (${_selectedUserIds.length})',
                      style: TextStyle(color: primary),
                    ),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Search people',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
          ),
          Expanded(
            child:
                _isLoadingUsers
                    ? const Center(child: CustomLoadingIndicator())
                    : _filteredUsers.isEmpty
                    ? const Center(
                      child: Text('No connections available to add'),
                    )
                    : UsersList(
                      users: _filteredUsers,
                      selectedIds: _selectedUserIds,
                      primary: primary,
                      isDark: isDark,
                      onToggle: (uid) {
                        setState(() {
                          _selectedUserIds.contains(uid)
                              ? _selectedUserIds.remove(uid)
                              : _selectedUserIds.add(uid);
                        });
                      },
                    ),
          ),
        ],
      ),
    );
  }
}
