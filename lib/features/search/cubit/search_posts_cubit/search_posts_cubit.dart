import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../posts/model/post_model.dart';
import '../../../posts/services/posts_services.dart';
part 'search_posts_state.dart';

class SearchPostsCubit extends Cubit<SearchPostsState> {
  final PostsServices _postsServices;

  SearchPostsCubit({PostsServices? postsServices})
    : _postsServices = postsServices ?? PostsServices(),
      super(SearchPostsInitial());

  static const int _pageSize = 12;
  String _query = '';
  bool _hasReachedMax = false;
  bool _isFetchingMore = false;
  final List<PostModel> _results = [];

  Future<void> search(String query) async {
    final trimmed = query.trim();
    _query = trimmed;
    _results.clear();
    _hasReachedMax = false;

    if (trimmed.isEmpty) {
      emit(SearchPostsInitial());
      return;
    }

    emit(SearchPostsLoading());
    try {
      final ids = await _postsServices.searchPostIds(
        query: trimmed,
        limit: _pageSize,
      );
      if (_query != trimmed) return;

      if (ids.isEmpty) {
        _hasReachedMax = true;
        emit(const SearchPostsLoaded(posts: [], hasReachedMax: true));
        return;
      }

      final posts = await _postsServices.fetchPostsByIds(ids);
      if (_query != trimmed) return;

      _results.addAll(posts);
      _hasReachedMax = ids.length < _pageSize;
      emit(
        SearchPostsLoaded(
          posts: List.of(_results),
          hasReachedMax: _hasReachedMax,
        ),
      );
    } catch (e) {
      if (_query != trimmed) return;
      debugPrint('SearchPostsCubit.search error: $e');
      emit(
        const SearchPostsError('Something went wrong. Please try again later.'),
      );
    }
  }

  Future<void> loadMore() async {
    if (_query.isEmpty || _hasReachedMax || _isFetchingMore) return;
    _isFetchingMore = true;
    try {
      final ids = await _postsServices.searchPostIds(
        query: _query,
        limit: _pageSize,
        offset: _results.length,
      );
      if (ids.isEmpty) {
        _hasReachedMax = true;
      } else {
        final more = await _postsServices.fetchPostsByIds(ids);
        _results.addAll(more);
        if (ids.length < _pageSize) _hasReachedMax = true;
      }
      emit(
        SearchPostsLoaded(
          posts: List.of(_results),
          hasReachedMax: _hasReachedMax,
        ),
      );
    } catch (e) {
      debugPrint('SearchPostsCubit.loadMore error: $e');
      // Silent on purpose — keep showing what we already have.
    } finally {
      _isFetchingMore = false;
    }
  }
}
