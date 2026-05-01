import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/app_images.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/widgets/empty_findings_animation_widget.dart';

class SearchView extends StatefulWidget {
  const SearchView({super.key});

  @override
  State<SearchView> createState() => _SearchViewState();
}

class _SearchViewState extends State<SearchView>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  List<Map<String, dynamic>> _allUsers = [];
  List<Map<String, dynamic>> _filteredUsers = [];
  bool _isLoading = true;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _loadUsers();
    _searchController.addListener(_onSearch);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  Future<void> _loadUsers() async {
    final currentId = Supabase.instance.client.auth.currentUser!.id;
    try {
      final data = await Supabase.instance.client
          .from('users')
          .select('id, name, username, image_url, bio')
          .neq('id', currentId)
          .order('name');
      if (mounted) {
        setState(() {
          _allUsers = (data as List).cast<Map<String, dynamic>>();
          _filteredUsers = _allUsers;
          _isLoading = false;
        });
        _animController.forward();
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _onSearch() {
    final q = _searchController.text.trim();
    setState(() {
      _query = q;
      _filteredUsers =
          q.isEmpty
              ? _allUsers
              : _allUsers.where((u) {
                final name = (u['name'] as String? ?? '').toLowerCase();
                final username = (u['username'] as String? ?? '').toLowerCase();
                return name.contains(q.toLowerCase()) ||
                    username.contains(q.toLowerCase());
              }).toList();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = theme.primaryColor;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context, isDark, primary),
            Expanded(
              child:
                  _isLoading
                      ? _buildShimmerList(isDark)
                      : FadeTransition(
                        opacity: _fadeAnim,
                        child:
                            _filteredUsers.isEmpty
                                ? _buildEmptyState(isDark, primary)
                                : _buildUserGrid(isDark, primary),
                      ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark, Color primary) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 12, 16, 12),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(
          bottom: BorderSide(
            color:
                isDark
                    ? Colors.white.withValues(alpha: 0.07)
                    : Colors.black.withValues(alpha: 0.07),
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 20,
              color: Theme.of(context).primaryColor,
            ),
            onPressed: () => Navigator.pop(context),
          ),
          Expanded(
            child: Container(
              height: 46,
              decoration: BoxDecoration(
                color:
                    isDark
                        ? Colors.white.withValues(alpha: 0.07)
                        : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(14),
              ),
              child: TextField(
                controller: _searchController,
                focusNode: _focusNode,
                style: TextStyle(
                  fontSize: 15,
                  color: isDark ? Colors.white : Colors.black87,
                ),
                decoration: InputDecoration(
                  hintText: 'Search people...',
                  hintStyle: TextStyle(
                    color:
                        isDark
                            ? Colors.white.withValues(alpha: 0.35)
                            : Colors.grey.shade400,
                    fontSize: 15,
                  ),
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    color: primary,
                    size: 22,
                  ),
                  suffixIcon:
                      _query.isNotEmpty
                          ? IconButton(
                            icon: Icon(
                              Icons.close_rounded,
                              size: 18,
                              color:
                                  isDark
                                      ? Colors.white54
                                      : Colors.grey.shade500,
                            ),
                            onPressed: () {
                              _searchController.clear();
                              _focusNode.requestFocus();
                            },
                          )
                          : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 13),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserGrid(bool isDark, Color primary) {
    if (_query.isEmpty) {
      // Grid view when no search
      return GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.82,
        ),
        itemCount: _filteredUsers.length,
        itemBuilder: (context, i) {
          return _buildUserTile(_filteredUsers[i], isDark, primary, i);
        },
      );
    } else {
      // List view when searching
      return ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: _filteredUsers.length,
        separatorBuilder:
            (_, __) => Divider(
              height: 1,
              indent: 72,
              color:
                  isDark
                      ? Colors.white.withValues(alpha: 0.06)
                      : Colors.black.withValues(alpha: 0.05),
            ),
        itemBuilder: (context, i) {
          return _buildSearchResultItem(_filteredUsers[i], isDark, primary, i);
        },
      );
    }
  }

  Widget _buildUserTile(
    Map<String, dynamic> user,
    bool isDark,
    Color primary,
    int index,
  ) {
    final name = user['name'] as String? ?? '';
    final username = user['username'] as String? ?? '';
    final imageUrl = user['image_url'] as String? ?? '';

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 300 + (index * 50).clamp(0, 400)),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: child,
          ),
        );
      },
      child: GestureDetector(
        onTap: () => _navigateToProfile(user['id']),
        child: Container(
          decoration: BoxDecoration(
            color:
                isDark
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.grey.shade50,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color:
                  isDark
                      ? Colors.white.withValues(alpha: 0.07)
                      : Colors.black.withValues(alpha: 0.06),
              width: 0.8,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 18),
              _buildAvatar(imageUrl, name, primary, radius: 38),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Text(
                  name,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),
              if (username.isNotEmpty) ...[
                const SizedBox(height: 3),
                Text(
                  '@$username',
                  style: TextStyle(
                    fontSize: 12,
                    color: primary.withValues(alpha: 0.8),
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 14),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchResultItem(
    Map<String, dynamic> user,
    bool isDark,
    Color primary,
    int index,
  ) {
    final name = user['name'] as String? ?? '';
    final username = user['username'] as String? ?? '';
    final imageUrl = user['image_url'] as String? ?? '';
    final bio = user['bio'] as String? ?? '';

    return InkWell(
      onTap: () => _navigateToProfile(user['id']),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            _buildAvatar(imageUrl, name, primary, radius: 26),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHighlightedText(
                    name,
                    _query,
                    primary,
                    isDark,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                  if (username.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    _buildHighlightedText(
                      '@$username',
                      _query,
                      primary,
                      isDark,
                      fontSize: 13,
                      isUsername: true,
                    ),
                  ],
                  if (bio.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      bio,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white38 : Colors.grey.shade500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color: isDark ? Colors.white24 : Colors.grey.shade300,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHighlightedText(
    String text,
    String query,
    Color primary,
    bool isDark, {
    double fontSize = 14,
    FontWeight fontWeight = FontWeight.normal,
    bool isUsername = false,
  }) {
    if (query.isEmpty) {
      return Text(
        text,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: fontWeight,
          color:
              isUsername
                  ? primary.withValues(alpha: 0.8)
                  : (isDark ? Colors.white : Colors.black87),
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );
    }

    final lowerText = text.toLowerCase();
    final lowerQuery = query.toLowerCase();
    final List<TextSpan> spans = [];
    int start = 0;

    while (start < text.length) {
      final index = lowerText.indexOf(lowerQuery, start);
      if (index == -1) {
        spans.add(
          TextSpan(
            text: text.substring(start),
            style: TextStyle(
              color:
                  isUsername
                      ? (isDark ? Colors.white38 : Colors.grey.shade500)
                      : (isDark ? Colors.white70 : Colors.black54),
              fontWeight: fontWeight,
            ),
          ),
        );
        break;
      }
      if (index > start) {
        spans.add(
          TextSpan(
            text: text.substring(start, index),
            style: TextStyle(
              color:
                  isUsername
                      ? (isDark ? Colors.white38 : Colors.grey.shade500)
                      : (isDark ? Colors.white70 : Colors.black54),
              fontWeight: fontWeight,
            ),
          ),
        );
      }
      spans.add(
        TextSpan(
          text: text.substring(index, index + query.length),
          style: TextStyle(
            color: primary,
            fontWeight: FontWeight.w700,
            backgroundColor: primary.withValues(alpha: 0.12),
          ),
        ),
      );
      start = index + query.length;
    }

    return Text.rich(
      TextSpan(children: spans, style: TextStyle(fontSize: fontSize)),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildAvatar(
    String imageUrl,
    String name,
    Color primary, {
    double radius = 26,
  }) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: primary.withValues(alpha: 0.12),
      backgroundImage:
          imageUrl.isNotEmpty ? CachedNetworkImageProvider(imageUrl) : null,
      child:
          imageUrl.isEmpty
              ? Text(
                name.isNotEmpty ? name[0].toUpperCase() : '?',
                style: TextStyle(
                  color: primary,
                  fontWeight: FontWeight.bold,
                  fontSize: radius * 0.55,
                ),
              )
              : null,
    );
  }

  Widget _buildEmptyState(bool isDark, Color primary) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          EmptyFindingsThemedAnimation(
            animationPath: AppImages.emptyFindingsLot,
            width: 320,
            height: 280,
          ),
          const SizedBox(height: 16),
          Text(
            'No results for "$_query"',
            style: TextStyle(
              fontSize: 16,
              color: isDark ? Colors.white38 : Colors.grey.shade500,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Try a different name or username',
            style: TextStyle(
              fontSize: 13,
              color: isDark ? Colors.white24 : Colors.grey.shade400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerList(bool isDark) {
    final baseColor =
        isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade200;
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.82,
      ),
      itemCount: 8,
      itemBuilder:
          (_, __) => Container(
            decoration: BoxDecoration(
              color: baseColor,
              borderRadius: BorderRadius.circular(18),
            ),
          ),
    );
  }

  void _navigateToProfile(String userId) {
    Navigator.of(
      context,
    ).pushNamed(AppRoutes.profileViewRoute, arguments: userId);
  }
}
