import 'dart:async';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import '../../../core/themes/app_colors.dart';
import '../model/gif_result_model.dart';
import '../service/giphy_services.dart';
import '../utils/gif_grid_skeleton.dart';
import 'gif_grid.dart';
import 'gif_search_bar.dart';

class GifPickerSheet extends StatefulWidget {
  const GifPickerSheet({super.key});

  @override
  State<GifPickerSheet> createState() => _GifPickerSheetState();
}

class _GifPickerSheetState extends State<GifPickerSheet> {
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

    return DraggableScrollableSheet(
      initialChildSize: 0.80,
      maxChildSize: 0.98,
      minChildSize: 0.30,
      snap: true,
      builder: (context, scrollController) {
        return SafeArea(
          child: Container(
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
                GifSearchBar(
                  controller: _searchController,
                  onChanged: _onSearchChanged,
                ),
                const Gap(12),
                Expanded(child: _buildBody(scrollController)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBody(ScrollController scrollController) {
    if (_isLoading) {
      return GifGridSkeleton(scrollController: scrollController);
    }
    if (_error != null) {
      return Center(child: Text(_error!));
    }
    if (_results.isEmpty) {
      return const Center(child: Text('No GIFs found'));
    }
    return GifGrid(results: _results, scrollController: scrollController);
  }
}
