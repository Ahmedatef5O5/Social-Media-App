import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:social_media_app/core/widgets/custom_loading_indicator.dart';
import '../../../core/presence/widgets/presence_avatar_widget.dart';
import '../../../core/widgets/app_avatar.dart';
import '../services/connections_service.dart';

class AudiencePickerView extends StatefulWidget {
  final Set<String> initialSelectedIds;
  const AudiencePickerView({super.key, this.initialSelectedIds = const {}});

  @override
  State<AudiencePickerView> createState() => _AudiencePickerViewState();
}

class _AudiencePickerViewState extends State<AudiencePickerView> {
  List<Map<String, dynamic>> _connections = [];
  late Set<String> _selectedIds = {...widget.initialSelectedIds};
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
      final data = await ConnectionsService().getMyConnections();
      if (mounted) {
        setState(() {
          _connections = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('AudiencePickerView load error: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load your connections.';
          _isLoading = false;
        });
      }
    }
  }

  void _toggleSelection(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final displayedConnections =
        _connections.where((user) {
          final name = (user['name'] as String? ?? '').toLowerCase();
          return name.contains(_searchQuery.toLowerCase());
        }).toList();

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      behavior: HitTestBehavior.opaque,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          elevation: 0,
          backgroundColor: theme.scaffoldBackgroundColor,
          centerTitle: true,
          title: Column(
            children: [
              const Text(
                'Select People',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              if (_selectedIds.isNotEmpty)
                Text(
                  '${_selectedIds.length} selected',
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
            onPressed: () => Navigator.pop(context, _selectedIds),
          ),
        ),
        body: Column(
          children: [
            if (!_isLoading && _errorMessage == null && _connections.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: TextField(
                  controller: _searchController,
                  onChanged: (value) => setState(() => _searchQuery = value),
                  decoration: InputDecoration(
                    hintText: 'Search friends...',
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

            Expanded(child: _buildContent(displayedConnections, theme)),

            if (!_isLoading && _errorMessage == null)
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context, _selectedIds),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.primaryColor,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        _selectedIds.isEmpty
                            ? 'Done'
                            : 'Done (${_selectedIds.length})',
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
    List<Map<String, dynamic>> displayedConnections,
    ThemeData theme,
  ) {
    if (_isLoading) {
      return const Center(child: CustomLoadingIndicator());
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

    if (_connections.isEmpty) {
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
                  CupertinoIcons.person_3,
                  size: 50,
                  color: theme.primaryColor,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                "No Connections Yet",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              const Text(
                "Add some friends or followers first so you can share private posts with them.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, height: 1.5),
              ),
            ],
          ),
        ),
      );
    }

    if (displayedConnections.isEmpty) {
      return const Center(
        child: Text(
          "No users found.",
          style: TextStyle(color: Colors.grey, fontSize: 16),
        ),
      );
    }

    return ListView.builder(
      itemCount: displayedConnections.length,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      itemBuilder: (context, i) {
        final user = displayedConnections[i];
        final id = user['id'] as String;
        final name = user['name'] as String? ?? 'Unknown';
        final isSelected = _selectedIds.contains(id);

        return Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: InkWell(
            onTap: () => _toggleSelection(id),
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
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeInOut,
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color:
                          isSelected ? theme.primaryColor : Colors.transparent,
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
    );
  }
}
