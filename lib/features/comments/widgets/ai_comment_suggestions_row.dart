import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shimmer/shimmer.dart';
import '../../../core/helpers/chat_helper.dart';
import '../../ai_assistant/cubits/ai_preferences_cubit/ai_preferences_cubit.dart';
import '../../ai_assistant/data/repositories/ai_repository_impl.dart';
import '../../ai_assistant/helpers/ai_image_encoder.dart';
import '../../ai_assistant/helpers/remote_media_fetcher.dart';
import '../../ai_assistant/repository/ai_repository.dart';
import '../../posts/models/post_model.dart';

class AiCommentSuggestionsRow extends StatefulWidget {
  final PostModel post;
  final ValueChanged<String> onChipSelected;
  final AiRepository? repository;
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry? padding;

  const AiCommentSuggestionsRow({
    super.key,
    required this.post,
    required this.onChipSelected,
    this.repository,
    this.margin,
    this.padding,
  });

  @override
  State<AiCommentSuggestionsRow> createState() =>
      _AiCommentSuggestionsRowState();
}

class _AiCommentSuggestionsRowState extends State<AiCommentSuggestionsRow> {
  late final AiRepository _repository = widget.repository ?? AiRepositoryImpl();

  bool _loading = true;
  List<String> _chips = const [];

  final List<double> _shimmerWidths = [120.0, 85.0, 140.0, 90.0, 110.0];

  bool get _isMediaOnlyUnsupported {
    final hasImage = widget.post.imageUrl?.isNotEmpty ?? false;
    final hasText = widget.post.text.trim().isNotEmpty;
    if (hasImage || hasText) return false;

    final hasVideo = widget.post.videoUrl?.isNotEmpty ?? false;
    final hasFile = widget.post.fileUrl?.isNotEmpty ?? false;
    return hasVideo || hasFile;
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final enabled =
        context.read<AiPreferencesCubit>().state.commentSuggestionsEnabled;
    if (!enabled || _isMediaOnlyUnsupported) {
      setState(() {
        _loading = false;
        _chips = const [];
      });
      return;
    }

    String? imageBase64;
    final imageUrl = widget.post.imageUrl;
    if (imageUrl != null && imageUrl.isNotEmpty) {
      final bytes = await RemoteMediaFetcher.fetchBytes(imageUrl);
      if (bytes != null) {
        imageBase64 = AiImageEncoder.encodeForCaption(bytes);
      }
    }
    if (!mounted) return;

    final result = await _repository.getCommentSuggestions(
      postId: widget.post.id,
      postText: widget.post.text,
      imageBase64: imageBase64,
      imageMimeType: imageBase64 != null ? 'image/jpeg' : null,
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

        return Padding(
          padding: widget.margin ?? EdgeInsets.zero,
          child: SizedBox(
            height: 32,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.zero,
              itemCount: _loading ? 5 : _chips.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                if (_loading) {
                  return _ShimmerChip(
                    width: _shimmerWidths[index % _shimmerWidths.length],
                  );
                }

                final text = _chips[index];
                final textDir = ChatHelper.getTextDirection(text);

                return Directionality(
                  textDirection: textDir,
                  child: ActionChip(
                    avatar: const Icon(Icons.auto_awesome_rounded, size: 16),
                    label: Text(
                      text,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(height: 1.2),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 0,
                    ),
                    labelPadding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 0,
                    ),
                    visualDensity: const VisualDensity(
                      horizontal: 0,
                      vertical: -4,
                    ),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    onPressed: () => widget.onChipSelected(text),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}

class _ShimmerChip extends StatelessWidget {
  final double width;
  const _ShimmerChip({required this.width});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Shimmer.fromColors(
      baseColor: isDark ? Colors.grey[800]! : Colors.grey[200]!,
      highlightColor: isDark ? Colors.grey[700]! : Colors.white,
      child: Container(
        width: width,
        height: 32,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }
}
