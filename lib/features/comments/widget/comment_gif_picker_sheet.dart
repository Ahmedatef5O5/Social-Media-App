import 'dart:async';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:social_media_app/core/models/gif_result_model.dart';
import 'package:social_media_app/core/services/giphy_services.dart';
import 'package:social_media_app/core/themes/app_colors.dart';
import 'package:social_media_app/features/comments/model/comment_attachment_draft.dart';
import 'package:social_media_app/features/comments/model/comment_type.dart';
import '../../../core/widgets/custom_loading_indicator.dart';

class CommentGifPickerSheet extends StatefulWidget {
  const CommentGifPickerSheet({super.key});

  @override
  State<CommentGifPickerSheet> createState() => _CommentGifPickerSheetState();
}

class _CommentGifPickerSheetState extends State<CommentGifPickerSheet> {
  final _searchController = TextEditingController();
  List<GifResult> _results = [];
  bool _isLoading = true;
  String? _error;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load([String query = '']) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final results = await GiphyServices.instance.search(query);
      if (!mounted) return;
      setState(() {
        _results = results;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = 'Could not load GIFs';
      });
    }
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () => _load(value));
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: Container(
        height: MediaQuery.of(context).size.height * 0.65,
        margin: const EdgeInsets.all(10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          children: [
            Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.grey5,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const Gap(14),
            TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Search GIFs...',
                prefixIcon: const Icon(Icons.search_rounded),
                filled: true,
                fillColor: theme.colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.4,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
            ),
            const Gap(12),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CustomLoadingIndicator());
    }
    if (_error != null) {
      return Center(child: Text(_error!));
    }
    if (_results.isEmpty) {
      return const Center(child: Text('No GIFs found'));
    }
    return GridView.builder(
      itemCount: _results.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 1.0,
      ),
      itemBuilder: (context, index) {
        final gif = _results[index];
        return ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            onTap:
                () => Navigator.of(context).pop(
                  CommentAttachmentDraft(
                    type: CommentType.gif,
                    remoteUrl: gif.sendUrl,
                  ),
                ),
            child: Image.network(gif.previewUrl, fit: BoxFit.cover),
          ),
        );
      },
    );
  }
}
