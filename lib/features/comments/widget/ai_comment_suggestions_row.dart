import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../ai_assistant/cubits/ai_preferences_cubit/ai_preferences_cubit.dart';
import '../../ai_assistant/data/repositories/ai_repository_impl.dart';
import '../../ai_assistant/repository/ai_repository.dart';

class AiCommentSuggestionsRow extends StatefulWidget {
  final String postId;
  final String postText;
  final ValueChanged<String> onChipSelected;
  final AiRepository? repository;

  const AiCommentSuggestionsRow({
    super.key,
    required this.postId,
    required this.postText,
    required this.onChipSelected,
    this.repository,
  });

  @override
  State<AiCommentSuggestionsRow> createState() =>
      _AiCommentSuggestionsRowState();
}

class _AiCommentSuggestionsRowState extends State<AiCommentSuggestionsRow> {
  late final AiRepository _repository = widget.repository ?? AiRepositoryImpl();

  bool _loading = true;
  List<String> _chips = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final enabled =
        context.read<AiPreferencesCubit>().state.commentSuggestionsEnabled;
    if (!enabled) {
      setState(() {
        _loading = false;
        _chips = const [];
      });
      return;
    }

    final result = await _repository.getCommentSuggestions(
      postId: widget.postId,
      postText: widget.postText,
    );
    if (!mounted) return;
    if (result.quota != null) {
      context.read<AiPreferencesCubit>().recordUsageFromQuota(
        result.quota!,
        provider: result.provider,
        modelId: result.model,
      );
    }
    setState(() {
      _loading = false;
      _chips = (result.success ? result.suggestions : null) ?? const [];
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_loading && _chips.isEmpty) return const SizedBox.shrink();

    return BlocBuilder<AiPreferencesCubit, AiPreferencesState>(
      buildWhen:
          (previous, current) =>
              previous.commentSuggestionsEnabled !=
              current.commentSuggestionsEnabled,

      builder: (context, prefs) {
        if (!prefs.commentSuggestionsEnabled) return const SizedBox.shrink();
        if (!_loading && _chips.isEmpty) return const SizedBox.shrink();
        return SizedBox(
          height: 38,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.zero,
            itemCount: _loading ? 3 : _chips.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              if (_loading) return const _ShimmerChip();

              final text = _chips[index];
              return ActionChip(
                avatar: const Icon(Icons.auto_awesome_rounded, size: 14),
                label: Text(text, overflow: TextOverflow.ellipsis),
                onPressed: () => widget.onChipSelected(text),
              );
            },
          ),
        );
      },
    );
  }
}

class _ShimmerChip extends StatelessWidget {
  const _ShimmerChip();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 92,
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(20),
      ),
    );
  }
}
