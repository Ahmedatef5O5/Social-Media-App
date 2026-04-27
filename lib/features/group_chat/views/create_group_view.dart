import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../cubit/group_list_cubit/group_list_cubit.dart';
import '../services/group_chat_services.dart';
import '../widgets/group_header_section_widget.dart';
import '../widgets/group_search_field_section_widget.dart';
import '../widgets/group_users_list.dart';
import '../widgets/members_count_label_widget.dart';
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
  }

  Future<void> _loadUsers() async {
    final currentId = Supabase.instance.client.auth.currentUser!.id;
    final data = await Supabase.instance.client
        .from('users')
        .select('id, name, image_url')
        .neq('id', currentId);

    if (mounted) {
      setState(() {
        _allUsers = (data as List).cast<Map<String, dynamic>>();
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

  Future<void> _createGroup() async {
    final name = _nameController.text.trim();

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a group name')),
      );
      return;
    }

    if (_selectedUserIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one member')),
      );
      return;
    }

    setState(() => _isCreating = true);

    try {
      String? avatarUrl;

      if (_groupImage != null) {
        final services = GroupChatServices();
        avatarUrl = await services.uploadGroupFile(_groupImage!, 'image');
      }

      final group = await context.read<GroupListCubit>().createGroup(
        name: name,
        avatarUrl: avatarUrl,
        memberIds: _selectedUserIds.toList(),
      );

      if (mounted) Navigator.pop(context, group);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to create group: $e')));
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
    final primary = Theme.of(context).primaryColor;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text('New Group'),
        actions: [
          TextButton(
            onPressed: _isCreating ? null : _createGroup,
            child:
                _isCreating
                    ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                    : Text('Create', style: TextStyle(color: primary)),
          ),
        ],
      ),
      body: Column(
        children: [
          GroupHeaderSection(
            groupImage: _groupImage,
            onPickImage: _pickImage,
            controller: _nameController,
            primary: primary,
            isDark: isDark,
          ),

          SelectedMembersSection(
            selectedUserIds: _selectedUserIds,
            allUsers: _allUsers,
            primary: primary,
            onRemove: (uid) => setState(() => _selectedUserIds.remove(uid)),
          ),

          SearchField(controller: _searchController, isDark: isDark),

          MembersCountLabel(count: _selectedUserIds.length, primary: primary),

          Expanded(
            child: UsersList(
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
