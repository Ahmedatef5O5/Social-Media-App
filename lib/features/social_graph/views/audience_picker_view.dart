import 'package:flutter/material.dart';
import 'package:social_media_app/core/widgets/custom_loading_indicator.dart';
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

  @override
  void initState() {
    super.initState();
    _load();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select people'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, _selectedIds),
            child: const Text('Done'),
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CustomLoadingIndicator());
    }
    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_errorMessage!),
            const SizedBox(height: 12),
            TextButton(onPressed: _load, child: const Text('Retry')),
          ],
        ),
      );
    }
    if (_connections.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 32),
          child: Text(
            "You don't have any friends or followers yet. Add some "
            "connections first so you can share private posts with them.",
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    return ListView.builder(
      itemCount: _connections.length,
      itemBuilder: (context, i) {
        final user = _connections[i];
        final id = user['id'] as String;
        return CheckboxListTile(
          value: _selectedIds.contains(id),
          title: Text(user['name'] as String? ?? ''),
          secondary: AppAvatar(
            imageUrl: user['image_url'] as String?,
            size: 40,
          ),
          onChanged:
              (checked) => setState(() {
                if (checked == true) {
                  _selectedIds.add(id);
                } else {
                  _selectedIds.remove(id);
                }
              }),
        );
      },
    );
  }
}
