import 'dart:async';
import 'package:flutter/material.dart';
import 'accounts_tab_view.dart';
import 'for_you_tab_view.dart';
import 'friends_tab_view.dart';
import 'global_search_input_field.dart';
import 'reels_tab_view.dart';

class SearchViewBodyWidget extends StatefulWidget {
  const SearchViewBodyWidget({super.key});

  @override
  State<SearchViewBodyWidget> createState() => _SearchViewBodyWidgetState();
}

class _SearchViewBodyWidgetState extends State<SearchViewBodyWidget>
    with SingleTickerProviderStateMixin {
  static const List<String> _tabLabels = [
    'For You',
    'Accounts',
    'Reels',
    'Friends',
  ];

  late final TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final ValueNotifier<String> _query = ValueNotifier<String>('');
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabLabels.length, vsync: this);
    _searchController.addListener(_onQueryChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _searchFocusNode.requestFocus();
    });
  }

  void _onQueryChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      _query.value = _searchController.text.trim();
    });
  }

  void _clearQuery() {
    _debounce?.cancel();

    _searchController.clear();
    _query.value = '';
    _searchFocusNode.requestFocus();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _tabController.dispose();
    _searchController.removeListener(_onQueryChanged);
    _searchController.dispose();
    _searchFocusNode.dispose();
    _query.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          titleSpacing: 4,
          toolbarHeight: 60,
          title: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                onPressed: () => Navigator.of(context).maybePop(),
              ),
              Expanded(
                child: GlobalSearchInputField(
                  controller: _searchController,
                  focusNode: _searchFocusNode,
                  queryListenable: _query,
                  onClear: _clearQuery,
                ),
              ),
            ],
          ),
          bottom: TabBar(
            controller: _tabController,
            isScrollable: true,
            padding: const EdgeInsets.only(left: 16),
            tabAlignment: TabAlignment.start,
            dividerColor: Colors.transparent,
            splashBorderRadius: BorderRadius.circular(24),
            indicatorSize: TabBarIndicatorSize.tab,
            indicatorPadding: const EdgeInsets.symmetric(
              vertical: 6,
              horizontal: -4,
            ),
            indicator: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              color: theme.primaryColor,
              boxShadow: [
                BoxShadow(
                  color: theme.primaryColor.withValues(alpha: 0.35),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            overlayColor: WidgetStateProperty.all(Colors.transparent),
            labelColor: Colors.white,
            unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
            labelStyle: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
            unselectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
            tabs:
                _tabLabels
                    .map(
                      (label) => Tab(
                        height: 36,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 13.0),
                          child: Text(label),
                        ),
                      ),
                    )
                    .toList(),
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            ForYouTabView(searchQuery: _query),
            AccountsTabView(searchQuery: _query),
            ReelsTabView(searchQuery: _query),
            const FriendsTabView(),
          ],
        ),
      ),
    );
  }
}
