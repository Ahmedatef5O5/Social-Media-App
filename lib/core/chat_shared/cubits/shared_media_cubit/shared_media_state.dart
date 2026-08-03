part of 'shared_media_cubit.dart';

class SharedMediaState {
  final List<SharedMediaItem> preview;
  final bool previewLoading;
  final bool previewLoaded;

  final Map<SharedMediaTab, List<SharedMediaItem>> items;
  final Set<SharedMediaTab> loadingTabs;
  final Set<SharedMediaTab> loadedTabs;
  final Map<SharedMediaTab, String> tabErrors;

  const SharedMediaState({
    this.preview = const [],
    this.previewLoading = false,
    this.previewLoaded = false,
    this.items = const {},
    this.loadingTabs = const {},
    this.loadedTabs = const {},
    this.tabErrors = const {},
  });

  List<SharedMediaItem> itemsFor(SharedMediaTab tab) => items[tab] ?? const [];
  bool isLoading(SharedMediaTab tab) => loadingTabs.contains(tab);
  bool isLoaded(SharedMediaTab tab) => loadedTabs.contains(tab);

  SharedMediaState copyWith({
    List<SharedMediaItem>? preview,
    bool? previewLoading,
    bool? previewLoaded,
    Map<SharedMediaTab, List<SharedMediaItem>>? items,
    Set<SharedMediaTab>? loadingTabs,
    Set<SharedMediaTab>? loadedTabs,
    Map<SharedMediaTab, String>? tabErrors,
  }) {
    return SharedMediaState(
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
