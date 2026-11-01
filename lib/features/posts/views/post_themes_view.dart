import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gap/gap.dart';
import '../../../core/design/tokens/typography.dart';
import '../../../core/helpers/emoji_helper.dart';
import '../../../core/themes/app_colors.dart';
import '../../../core/themes/background_theme_widget.dart';
import '../models/post_theme_model.dart';
import '../widgets/themed_post_canvas.dart';
import 'package:social_media_app/core/localization/l10n_extension.dart';

/// Route arguments for `AppRoutes.postThemesViewRoute`.
class PostThemesViewArgs {
  final String? selectedThemeId;

  /// The user's current text, shown in the live preview when not empty.
  final String? sampleText;
  const PostThemesViewArgs({this.selectedThemeId, this.sampleText});
}

/// Theme picker. Pops with the chosen [PostThemeSelection] on "Done",
/// or with null when closed.
class PostThemesView extends StatefulWidget {
  const PostThemesView({super.key});

  @override
  State<PostThemesView> createState() => _PostThemesViewState();
}

class _PostThemesViewState extends State<PostThemesView> {
  PostBackgroundThemeModel? _selected;
  final List<String> _motifs = <String>[];
  int _seed = PostThemeSelection.generateSeed();
  String? _sampleText;
  bool _initialised = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialised) return;
    _initialised = true;
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is PostThemesViewArgs) {
      final parsed = PostThemeSelection.parse(args.selectedThemeId);
      if (parsed != null) {
        _selected = parsed.theme;
        _motifs
          ..clear()
          ..addAll(parsed.motifs);
        if (parsed.seed > 0) _seed = parsed.seed;
      }
      final t = args.sampleText?.trim();
      _sampleText = (t == null || t.isEmpty) ? null : t;
    }
    _selected ??= PostBackgroundThemeModel.all.first;
  }

  void _toggleMotif(String token) {
    HapticFeedback.selectionClick();
    setState(() {
      if (_motifs.contains(token)) {
        _motifs.remove(token);
      } else {
        if (_motifs.length >= PostThemeSelection.maxMotifs) {
          _motifs.removeAt(0);
        }
        _motifs.add(token);
      }
      _seed = PostThemeSelection.generateSeed();
    });
  }

  void _clearMotifs() {
    if (_motifs.isEmpty) return;
    HapticFeedback.selectionClick();
    setState(_motifs.clear);
  }

  void _shuffleSeed() {
    HapticFeedback.lightImpact();
    setState(() {
      _seed = PostThemeSelection.generateSeed();
    });
  }

  Future<void> _openCustomEmojiSheet() async {
    final pickedEmoji = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetCtx) => const _CustomEmojiInputSheet(),
    );
    if (pickedEmoji == null || pickedEmoji.isEmpty || !mounted) return;
    _toggleMotif(pickedEmoji);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final selected = _selected!;
    final previewText = _sampleText ?? l10n.themePreviewSample;
    final themeData = Theme.of(context);
    final colorScheme = themeData.colorScheme;

    final customAddedEmojis =
        _motifs
            .where(
              (m) =>
                  !PostThemePresetIcons.isIconToken(m) &&
                  !PostThemePresetIcons.quickEmojis.contains(m),
            )
            .toList();

    return BackgroundThemeWidget(
      bottom: false,
      child: Scaffold(
        backgroundColor: AppColors.transparent,
        appBar: AppBar(
          backgroundColor: AppColors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          leading: IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close, size: 24),
          ),
          title: Text(
            l10n.chooseTheme,
            style: themeData.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w500,
              fontSize: 18,
            ),
          ),
        ),
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
                child: Stack(
                  children: [
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 220),
                      child: ThemedPostCanvas(
                        key: ValueKey(selected.id),
                        theme: selected,
                        motifs: List.unmodifiable(_motifs),
                        seed: _seed,
                        minHeight: 190,
                        bottomReservedHeight: _motifs.isNotEmpty ? 42 : 0,
                        child: Text(
                          previewText,
                          textAlign: TextAlign.center,
                          maxLines: 5,
                          overflow: TextOverflow.ellipsis,
                          style: ThemedPostCanvas.textStyleFor(
                            selected,
                            fontSize: ThemedPostCanvas.fontSizeFor(previewText),
                            base: const TextStyle(
                              fontFamily: null,
                              fontFamilyFallback: AppTypography.fontFallback,
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (_motifs.isNotEmpty)
                      PositionedDirectional(
                        bottom: 10,
                        end: 10,
                        child: Material(
                          color: Colors.black.withValues(alpha: 0.36),
                          shape: const StadiumBorder(),
                          child: InkWell(
                            customBorder: const StadiumBorder(),
                            onTap: _shuffleSeed,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.shuffle_rounded,
                                    size: 16,
                                    color: Colors.white,
                                  ),
                                  const Gap(5),
                                  Text(
                                    l10n.themeShuffleMotifs,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        l10n.themeMotifsLabel,
                        style: themeData.textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (_motifs.isNotEmpty)
                      Text(
                        '${_motifs.length}/${PostThemeSelection.maxMotifs}',
                        style: themeData.textTheme.labelMedium?.copyWith(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                  ],
                ),
              ),
              const Gap(8),
              SizedBox(
                height: 42,
                child: ListView(
                  physics: ClampingScrollPhysics(),
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    _MotifChoiceChip(
                      isSelected: _motifs.isEmpty,
                      onTap: _clearMotifs,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.block_rounded,
                            size: 16,
                            color:
                                _motifs.isEmpty
                                    ? colorScheme.onPrimary
                                    : colorScheme.onSurfaceVariant,
                          ),
                          const Gap(5),
                          Text(
                            l10n.themeMotifsNone,
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color:
                                  _motifs.isEmpty
                                      ? colorScheme.onPrimary
                                      : colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Gap(8),
                    _MotifChoiceChip(
                      isSelected: false,
                      onTap: _openCustomEmojiSheet,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.add_reaction_outlined,
                            size: 18,
                            color: colorScheme.primary,
                          ),
                          const Gap(4),
                          Text(
                            l10n.themeAddCustomEmoji,
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    for (final customEmoji in customAddedEmojis) ...[
                      const Gap(8),
                      _MotifChoiceChip(
                        isSelected: true,
                        onTap: () => _toggleMotif(customEmoji),
                        child: Text(
                          EmojiHelper.normalize(customEmoji),
                          style: AppTypography.emojiTextStyle.copyWith(
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ],
                    for (final preset in PostThemePresetIcons.all) ...[
                      const Gap(8),
                      _MotifChoiceChip(
                        isSelected: _motifs.contains(preset.token),
                        onTap: () => _toggleMotif(preset.token),
                        child: Icon(
                          preset.icon,
                          size: 19,
                          color:
                              _motifs.contains(preset.token)
                                  ? colorScheme.onPrimary
                                  : colorScheme.onSurface,
                        ),
                      ),
                    ],
                    for (final emoji in PostThemePresetIcons.quickEmojis) ...[
                      const Gap(8),
                      _MotifChoiceChip(
                        isSelected: _motifs.contains(emoji),
                        onTap: () => _toggleMotif(emoji),
                        child: Text(
                          EmojiHelper.normalize(emoji),
                          style: AppTypography.emojiTextStyle.copyWith(
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const Gap(12),
              Expanded(
                child: CustomScrollView(
                  physics: ClampingScrollPhysics(),
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                        child: Text(
                          l10n.themeSectionGradients,
                          style: themeData.textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      sliver: SliverGrid(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              mainAxisSpacing: 12,
                              crossAxisSpacing: 12,
                              childAspectRatio: 0.88,
                            ),
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final theme =
                                PostBackgroundThemeModel.gradients[index];
                            final isSelected = theme == selected;
                            return _ThemeTile(
                              theme: theme,
                              name: theme.localizedName(l10n),
                              isSelected: isSelected,
                              onTap: () => setState(() => _selected = theme),
                            );
                          },
                          childCount: PostBackgroundThemeModel.gradients.length,
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                        child: Text(
                          l10n.themeSectionSolids,
                          style: themeData.textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      sliver: SliverGrid(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              mainAxisSpacing: 12,
                              crossAxisSpacing: 12,
                              childAspectRatio: 0.88,
                            ),
                        delegate: SliverChildBuilderDelegate((context, index) {
                          final theme = PostBackgroundThemeModel.solids[index];
                          final isSelected = theme == selected;
                          return _ThemeTile(
                            theme: theme,
                            name: theme.localizedName(l10n),
                            isSelected: isSelected,
                            onTap: () => setState(() => _selected = theme),
                          );
                        }, childCount: PostBackgroundThemeModel.solids.length),
                      ),
                    ),
                    const SliverToBoxAdapter(child: Gap(12)),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      foregroundColor: colorScheme.onPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: () {
                      Navigator.of(context).pop(
                        PostThemeSelection(
                          theme: selected,
                          motifs: List.unmodifiable(_motifs),
                          seed: _seed,
                        ),
                      );
                    },
                    child: Text(
                      l10n.done,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MotifChoiceChip extends StatelessWidget {
  final bool isSelected;
  final VoidCallback onTap;
  final Widget child;

  const _MotifChoiceChip({
    required this.isSelected,
    required this.onTap,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Material(
      color:
          isSelected
              ? colorScheme.primary
              : colorScheme.surfaceContainerHighest.withValues(alpha: 0.65),
      shape: StadiumBorder(
        side: BorderSide(
          color:
              isSelected
                  ? colorScheme.primary
                  : colorScheme.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Center(child: child),
        ),
      ),
    );
  }
}

class _CustomEmojiInputSheet extends StatefulWidget {
  const _CustomEmojiInputSheet();

  @override
  State<_CustomEmojiInputSheet> createState() => _CustomEmojiInputSheetState();
}

class _CustomEmojiInputSheetState extends State<_CustomEmojiInputSheet> {
  final TextEditingController _controller = TextEditingController();

  static final RegExp _nonEmojiAscii = RegExp(r'^[a-zA-Z0-9\s.,|=_+-]+$');

  String? _extractFirstEmoji(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;
    for (final grapheme in trimmed.characters) {
      if (!_nonEmojiAscii.hasMatch(grapheme)) {
        return grapheme;
      }
    }
    return null;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final emoji = _extractFirstEmoji(_controller.text);

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 16, 20, bottomInset + 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Theme.of(context).dividerColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const Gap(16),
          Text(
            l10n.themeCustomEmojiHint,
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const Gap(14),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  autofocus: true,
                  textAlign: TextAlign.center,
                  style: (Theme.of(context).textTheme.headlineMedium ??
                          const TextStyle())
                      .copyWith(
                        fontSize: 28,
                        fontFamily: null,
                        fontFamilyFallback: AppTypography.emojiFontFallback,
                      ),
                  decoration: InputDecoration(
                    hintText: '✨ 🔥 🌸',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onChanged: (_) => setState(() {}),
                  onSubmitted: (_) {
                    if (emoji != null) Navigator.of(context).pop(emoji);
                  },
                ),
              ),
              const Gap(12),
              FilledButton(
                onPressed:
                    emoji == null
                        ? null
                        : () => Navigator.of(context).pop(emoji),
                style: FilledButton.styleFrom(
                  minimumSize: const Size(56, 54),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Icon(Icons.check_rounded),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ThemeTile extends StatelessWidget {
  final PostBackgroundThemeModel theme;
  final String name;
  final bool isSelected;
  final VoidCallback onTap;

  const _ThemeTile({
    required this.theme,
    required this.name,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Semantics(
      button: true,
      selected: isSelected,
      label: name,
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          children: [
            Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: theme.gradient,
                  color: theme.previewColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color:
                        isSelected
                            ? primary
                            : Colors.white.withValues(alpha: 0.14),
                    width: isSelected ? 3 : 1,
                  ),
                ),
                child: Stack(
                  children: [
                    if (isSelected)
                      const PositionedDirectional(
                        top: 6,
                        end: 6,
                        child: CircleAvatar(
                          radius: 10,
                          backgroundColor: Colors.white,
                          child: Icon(
                            Icons.check_rounded,
                            size: 14,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const Gap(6),
            Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
