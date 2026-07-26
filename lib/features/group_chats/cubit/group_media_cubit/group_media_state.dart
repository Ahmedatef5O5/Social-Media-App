part of 'group_media_cubit.dart';

class GroupMediaState {
  final List<GroupMessageModel> preview;
  final bool previewLoading;
  final bool previewLoaded;

  final Map<GroupMediaTab, List<GroupMessageModel>> items;
  final Set<GroupMediaTab> loadingTabs;
  final Set<GroupMediaTab> loadedTabs;
  final Map<GroupMediaTab, String?> tabErrors;

  const GroupMediaState({
    this.preview = const [],
    this.previewLoading = false,
    this.previewLoaded = false,
    this.items = const {},
    this.loadingTabs = const {},
    this.loadedTabs = const {},
    this.tabErrors = const {},
  });

  GroupMediaState copyWith({
    List<GroupMessageModel>? preview,
    bool? previewLoading,
    bool? previewLoaded,
    Map<GroupMediaTab, List<GroupMessageModel>>? items,
    Set<GroupMediaTab>? loadingTabs,
    Set<GroupMediaTab>? loadedTabs,
    Map<GroupMediaTab, String?>? tabErrors,
  }) {
    return GroupMediaState(
      preview: preview ?? this.preview,
      previewLoading: previewLoading ?? this.previewLoading,
      previewLoaded: previewLoaded ?? this.previewLoaded,
      items: items ?? this.items,
      loadingTabs: loadingTabs ?? this.loadingTabs,
      loadedTabs: loadedTabs ?? this.loadedTabs,
      tabErrors: tabErrors ?? this.tabErrors,
    );
  }
}
