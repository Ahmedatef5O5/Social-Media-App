import 'dart:async';
import 'package:flutter/material.dart';
import '../../themes/app_colors.dart';
import '../../widgets/app_avatar.dart';
import '../../widgets/custom_loading_indicator.dart';
import '../models/mention_suggestion.dart';
import '../services/mention_search_service.dart';
import 'mention_text_editing_controller.dart';

class MentionAwareTextField extends StatefulWidget {
  final MentionTextEditingController controller;
  final FocusNode focusNode;
  final bool enabled;
  final String hintText;
  final ValueChanged<String>? onSubmitted;

  const MentionAwareTextField({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.enabled,
    required this.hintText,
    this.onSubmitted,
  });

  @override
  State<MentionAwareTextField> createState() => _MentionAwareTextFieldState();
}

class _MentionAwareTextFieldState extends State<MentionAwareTextField> {
  final GlobalKey _fieldKey = GlobalKey();
  final _mentionsService = MentionSearchService();

  OverlayEntry? _overlayEntry;
  List<MentionSuggestion> _results = [];
  bool _isSearching = false;
  int? _triggerStart;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    _debounce?.cancel();
    _removeOverlay();
    super.dispose();
  }

  void _onTextChanged() {
    final text = widget.controller.text;
    final selection = widget.controller.selection;

    if (!selection.isValid || !selection.isCollapsed) {
      _closeMentionSearch();
      return;
    }

    final cursor = selection.baseOffset;
    int start = cursor;
    while (start > 0 && text[start - 1] != ' ' && text[start - 1] != '\n') {
      start--;
    }
    final word = text.substring(start, cursor);

    if (word.startsWith('@')) {
      _triggerStart = start;
      _searchMentions(word.substring(1));
    } else {
      _closeMentionSearch();
    }
  }

  void _searchMentions(String query) {
    if (widget.focusNode.hasFocus) {
      widget.focusNode.unfocus();
      Future.delayed(const Duration(milliseconds: 260), _syncOverlay);
    }

    _showOverlay();
    setState(() => _isSearching = true);
    _syncOverlay();

    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () async {
      final results = await _mentionsService.search(query);
      if (!mounted || _triggerStart == null) return;
      setState(() {
        _results = results;
        _isSearching = false;
      });
      _syncOverlay();
    });
  }

  void _closeMentionSearch() {
    if (_triggerStart == null && _overlayEntry == null) return;
    _triggerStart = null;
    _results = [];
    _isSearching = false;
    _debounce?.cancel();
    _removeOverlay();
  }

  void _showOverlay() {
    if (_overlayEntry != null) return;

    _overlayEntry = OverlayEntry(builder: (_) => _buildFollower());
    Overlay.of(context, rootOverlay: true).insert(_overlayEntry!);
  }

  void _syncOverlay() => _overlayEntry?.markNeedsBuild();

  Widget _buildFollower() {
    final renderBox =
        _fieldKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null || !renderBox.attached) {
      return const SizedBox.shrink();
    }

    final fieldSize = renderBox.size;
    final fieldTopLeft = renderBox.localToGlobal(Offset.zero);
    final screenHeight = MediaQuery.of(context).size.height;

    return Positioned(
      left: fieldTopLeft.dx,
      width: fieldSize.width,
      bottom: screenHeight - fieldTopLeft.dy + 8,
      child: Material(
        color: Colors.transparent,
        child: _MentionSuggestionsCard(
          width: fieldSize.width,
          results: _results,
          isLoading: _isSearching,
          onSelect: _selectMention,
          onClose: _closeMentionSearch,
        ),
      ),
    );
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _selectMention(MentionSuggestion suggestion) {
    final triggerStart = _triggerStart;
    if (triggerStart == null) return;
    final cursor = widget.controller.selection.baseOffset;

    widget.controller.insertMention(
      userId: suggestion.userId,
      name: suggestion.name,
      replaceStart: triggerStart,
      replaceEnd: cursor < triggerStart ? triggerStart : cursor,
    );

    _closeMentionSearch();
    widget.focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return TextField(
      key: _fieldKey,
      controller: widget.controller,
      focusNode: widget.focusNode,
      enabled: widget.enabled,
      minLines: 1,
      maxLines: 4,
      textCapitalization: TextCapitalization.sentences,
      onSubmitted: widget.onSubmitted,
      decoration: InputDecoration(
        hintText: widget.hintText,
        hintStyle: theme.textTheme.bodyMedium?.copyWith(
          color: AppColors.grey5,
          fontWeight: FontWeight.w400,
          fontSize: 15,
        ),
        filled: true,
        fillColor: theme.colorScheme.surfaceContainerHighest.withValues(
          alpha: 0.4,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(25),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(25),
          borderSide: BorderSide(color: theme.primaryColor, width: 1.6),
        ),
      ),
    );
  }
}

class _MentionSuggestionsCard extends StatelessWidget {
  final double width;
  final List<MentionSuggestion> results;
  final bool isLoading;
  final ValueChanged<MentionSuggestion> onSelect;
  final VoidCallback onClose;

  const _MentionSuggestionsCard({
    required this.width,
    required this.results,
    required this.isLoading,
    required this.onSelect,
    required this.onClose,
  });

  static const double _rowHeight = 56;
  static const double _maxVisibleRows = 4.5;
  static const double _compactHeight = 64;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    late final Widget body;
    late final double bodyHeight;

    if (isLoading) {
      bodyHeight = _compactHeight;
      body = _MentionStatusRow(
        key: const ValueKey('mentions_loading'),
        icon: const SizedBox(
          width: 16,
          height: 16,
          child: CustomLoadingIndicator(radius: 8),
        ),
        label: 'Searching...',
      );
    } else if (results.isEmpty) {
      bodyHeight = _compactHeight;
      body = _MentionStatusRow(
        key: const ValueKey('mentions_empty'),
        icon: Icon(
          Icons.person_search_rounded,
          size: 20,
          color: AppColors.grey5,
        ),
        label: 'No users found',
      );
    } else {
      final visibleRows =
          results.length <= _maxVisibleRows.floor()
              ? results.length.toDouble()
              : _maxVisibleRows;
      bodyHeight = visibleRows * _rowHeight;

      body = ListView.builder(
        key: const ValueKey('mentions_results'),
        padding: EdgeInsets.zero,
        physics: const ClampingScrollPhysics(),
        itemCount: results.length,
        itemExtent: _rowHeight,
        itemBuilder: (context, index) {
          final suggestion = results[index];
          final isLast = index == results.length - 1;
          return InkWell(
            onTap: () => onSelect(suggestion),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                border:
                    isLast
                        ? null
                        : Border(
                          bottom: BorderSide(
                            color: AppColors.grey4.withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
              ),
              child: Row(
                children: [
                  AppAvatar(
                    imageUrl: suggestion.imageUrl,
                    size: 34,
                    heroTag: 'mention_${suggestion.userId}',
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      suggestion.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    }

    return Padding(
      padding: const EdgeInsets.only(top: 10, left: 6),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: width,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: isDark ? theme.colorScheme.surface : Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: AppColors.grey4.withValues(alpha: 0.25),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.14),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: AnimatedSize(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              alignment: Alignment.topCenter,
              child: SizedBox(
                height: bodyHeight,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 150),
                  child: body,
                ),
              ),
            ),
          ),
          Positioned(top: -10, left: -6, child: _CloseBadge(onTap: onClose)),
        ],
      ),
    );
  }
}

class _MentionStatusRow extends StatelessWidget {
  final Widget icon;
  final String label;

  const _MentionStatusRow({super.key, required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          icon,
          const SizedBox(width: 10),
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.grey6,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _CloseBadge extends StatelessWidget {
  final VoidCallback onTap;
  const _CloseBadge({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.grey7,
            border: Border.all(color: Colors.white, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: const Icon(Icons.close_rounded, size: 14, color: Colors.white),
        ),
      ),
    );
  }
}
