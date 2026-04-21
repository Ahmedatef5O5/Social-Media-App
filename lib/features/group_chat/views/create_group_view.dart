import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../cubit/group_list_cubit/group_list_cubit.dart';
import '../services/group_chat_services.dart';

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
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
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

      // Upload group image if selected
      if (_groupImage != null) {
        final services = GroupChatServices();
        avatarUrl = await services.uploadGroupFile(_groupImage!, 'image');
      }

      final group = await context.read<GroupListCubit>().createGroup(
        name: name,
        avatarUrl: avatarUrl,
        memberIds: _selectedUserIds.toList(),
      );

      if (mounted) {
        Navigator.pop(context, group);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to create group: $e')));
      }
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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text(
          'New Group',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
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
                    : Text(
                      'Create',
                      style: TextStyle(
                        color: primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Group Avatar + Name ──
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: Row(
              children: [
                GestureDetector(
                  onTap: _pickImage,
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 38,
                        backgroundColor: primary.withValues(alpha: 0.15),
                        backgroundImage:
                            _groupImage != null
                                ? FileImage(_groupImage!)
                                : null,
                        child:
                            _groupImage == null
                                ? Icon(
                                  Icons.group_rounded,
                                  size: 36,
                                  color: primary,
                                )
                                : null,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          width: 26,
                          height: 26,
                          decoration: BoxDecoration(
                            color: primary,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Theme.of(context).scaffoldBackgroundColor,
                              width: 2,
                            ),
                          ),
                          child: const Icon(
                            Icons.camera_alt_rounded,
                            color: Colors.white,
                            size: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Gap(16),
                Expanded(
                  child: TextField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      hintText: 'Group name',
                      hintStyle: TextStyle(
                        color: isDark ? Colors.white38 : Colors.black38,
                      ),
                      border: UnderlineInputBorder(
                        borderSide: BorderSide(
                          color: primary.withValues(alpha: 0.5),
                        ),
                      ),
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: primary, width: 2),
                      ),
                    ),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Selected members chips ──
          if (_selectedUserIds.isNotEmpty)
            SizedBox(
              height: 70,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children:
                    _selectedUserIds.map((uid) {
                      final user = _allUsers.firstWhere(
                        (u) => u['id'] == uid,
                        orElse: () => {'name': 'Unknown', 'image_url': ''},
                      );
                      return Padding(
                        padding: const EdgeInsets.only(right: 10),
                        child: Column(
                          children: [
                            Stack(
                              children: [
                                CircleAvatar(
                                  radius: 24,
                                  backgroundColor: primary.withValues(
                                    alpha: 0.15,
                                  ),
                                  backgroundImage:
                                      (user['image_url'] as String?)
                                                  ?.isNotEmpty ==
                                              true
                                          ? CachedNetworkImageProvider(
                                            user['image_url'] as String,
                                          )
                                          : null,
                                  child:
                                      (user['image_url'] as String?)?.isEmpty !=
                                              false
                                          ? Text(
                                            (user['name'] as String)[0]
                                                .toUpperCase(),
                                            style: TextStyle(
                                              color: primary,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          )
                                          : null,
                                ),
                                Positioned(
                                  bottom: -1,
                                  right: -1,
                                  child: GestureDetector(
                                    onTap:
                                        () => setState(
                                          () => _selectedUserIds.remove(uid),
                                        ),
                                    child: Container(
                                      width: 18,
                                      height: 18,
                                      decoration: const BoxDecoration(
                                        color: Colors.red,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.close,
                                        color: Colors.white,
                                        size: 12,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const Gap(4),
                            Text(
                              (user['name'] as String).split(' ').first,
                              style: const TextStyle(fontSize: 10),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      );
                    }).toList(),
              ),
            ),

          // ── Search ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search people',
                prefixIcon: const Icon(Icons.search_rounded),
                filled: true,
                fillColor:
                    isDark
                        ? Colors.white.withValues(alpha: 0.06)
                        : Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),

          // ── Members count label ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '${_selectedUserIds.length} selected',
                style: TextStyle(
                  color: primary,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          ),

          // ── Users list ──
          Expanded(
            child:
                _allUsers.isEmpty
                    ? const Center(child: CircularProgressIndicator())
                    : ListView.builder(
                      itemCount: _filteredUsers.length,
                      itemBuilder: (context, index) {
                        final user = _filteredUsers[index];
                        final uid = user['id'] as String;
                        final isSelected = _selectedUserIds.contains(uid);

                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 4,
                          ),
                          leading: CircleAvatar(
                            radius: 24,
                            backgroundColor: primary.withValues(alpha: 0.12),
                            backgroundImage:
                                (user['image_url'] as String?)?.isNotEmpty ==
                                        true
                                    ? CachedNetworkImageProvider(
                                      user['image_url'] as String,
                                    )
                                    : null,
                            child:
                                (user['image_url'] as String?)?.isEmpty != false
                                    ? Text(
                                      (user['name'] as String)[0].toUpperCase(),
                                      style: TextStyle(
                                        color: primary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    )
                                    : null,
                          ),
                          title: Text(
                            user['name'] as String,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          trailing: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isSelected ? primary : Colors.transparent,
                              border: Border.all(
                                color:
                                    isSelected
                                        ? primary
                                        : (isDark
                                            ? Colors.white30
                                            : Colors.black26),
                                width: 2,
                              ),
                            ),
                            child:
                                isSelected
                                    ? const Icon(
                                      Icons.check_rounded,
                                      color: Colors.white,
                                      size: 16,
                                    )
                                    : null,
                          ),
                          onTap: () {
                            setState(() {
                              if (isSelected) {
                                _selectedUserIds.remove(uid);
                              } else {
                                _selectedUserIds.add(uid);
                              }
                            });
                          },
                        );
                      },
                    ),
          ),
        ],
      ),
    );
  }
}
