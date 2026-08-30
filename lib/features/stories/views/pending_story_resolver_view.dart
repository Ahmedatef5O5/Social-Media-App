import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/toast/app_toast.dart';
import '../cubits/stories_cubit/stories_cubit.dart';
import '../models/story_model.dart';
import '../widgets/story_shimmer_widget.dart';
import 'story_display_view.dart';

class PendingStoryResolverView extends StatefulWidget {
  final String storyId;
  final String? authorId;

  const PendingStoryResolverView({
    super.key,
    required this.storyId,
    this.authorId,
  });

  @override
  State<PendingStoryResolverView> createState() =>
      _PendingStoryResolverViewState();
}

class _PendingStoryResolverViewState extends State<PendingStoryResolverView> {
  late final StoriesCubit _storiesCubit;
  StreamSubscription<StoriesState>? _silentSyncSub;

  List<List<StoryModel>>? _groups;
  int _groupIndex = 0;
  int _storyIndex = 0;

  @override
  void initState() {
    super.initState();
    _storiesCubit = context.read<StoriesCubit>();
    _resolveInstantlyFromCache();
  }

  void _resolveInstantlyFromCache() {
    // fastest source (fetchStories() from app.dart)
    if (_tryBuildGroups(_storiesCubit.cachedStories)) {
      _startSilentBackgroundSync();
      return;
    }

    // Hive sync
    if (_tryBuildGroups(_storiesCubit.readCachedSnapshot())) {
      _startSilentBackgroundSync();
      return;
    }

    // (edge case) -> network + Shimmer
    unawaited(_resolveFromNetworkFallback());
  }

  bool _tryBuildGroups(List<StoryModel> source) {
    if (source.isEmpty) return false;

    final Map<String, List<StoryModel>> storiesByUser = {};
    for (final story in source) {
      storiesByUser.putIfAbsent(story.authorId, () => []).add(story);
    }
    final groups = storiesByUser.values.toList();

    final groupIndex = groups.indexWhere(
      (g) => g.any((s) => s.id == widget.storyId),
    );
    if (groupIndex == -1) return false;

    final storyIndex = groups[groupIndex].indexWhere(
      (s) => s.id == widget.storyId,
    );

    _groups = groups;
    _groupIndex = groupIndex;
    _storyIndex = storyIndex < 0 ? 0 : storyIndex;
    return true;
  }

  void _startSilentBackgroundSync() {
    _silentSyncSub = _storiesCubit.stream.listen((state) {
      if (state is StoriesLoaded) _mergeNewStoriesSilently(state.stories);
    });
    unawaited(_storiesCubit.fetchStories(isRefresh: true));
  }

  void _mergeNewStoriesSilently(List<StoryModel> freshStories) {
    if (!mounted || _groups == null) return;

    final currentGroup = _groups![_groupIndex];
    final authorId = currentGroup.first.authorId;

    final freshAuthorStories =
        freshStories.where((s) => s.authorId == authorId).toList();
    if (freshAuthorStories.isEmpty) return;

    final existingIds = currentGroup.map((s) => s.id).toSet();
    final newlyAdded =
        freshAuthorStories.where((s) => !existingIds.contains(s.id)).toList();
    if (newlyAdded.isEmpty) return;

    setState(() {
      _groups = List<List<StoryModel>>.from(_groups!);
      _groups![_groupIndex] = [...currentGroup, ...newlyAdded];
    });
  }

  Future<void> _resolveFromNetworkFallback() async {
    try {
      await _storiesCubit.fetchStories();
      if (!mounted) return;
      if (_tryBuildGroups(_storiesCubit.cachedStories)) {
        setState(() {});
        _startSilentBackgroundSync();
        return;
      }
      _closeWithToast();
    } catch (e) {
      debugPrint('PendingStoryResolverView: network fallback failed - $e');
      _closeWithToast();
    }
  }

  void _closeWithToast() {
    AppToast.warning('This story is no longer available');
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Navigator.of(context).maybePop();
    });
  }

  @override
  void dispose() {
    unawaited(_silentSyncSub?.cancel());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_groups == null) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: StoryShimmerWidget(),
      );
    }

    return StoryDisplayView(
      storiesCubit: _storiesCubit,
      allUserGroups: _groups!,
      initialGroupIndex: _groupIndex,
      initialStoryIndex: _storyIndex,
    );
  }
}
