import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import '../../settings/widgets/settings_detail_sliver_app_bar.dart';

class MarkdownDocumentArgs {
  final String title;
  final String subtitle;
  final IconData icon;
  final String assetPath;

  const MarkdownDocumentArgs({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.assetPath,
  });
}

/// A single reusable reader screen for any static Markdown document
/// bundled as an asset — used today for Help & FAQ and Privacy Policy so
/// neither needs its own bespoke screen.
class MarkdownDocumentView extends StatefulWidget {
  final MarkdownDocumentArgs args;

  const MarkdownDocumentView({super.key, required this.args});

  @override
  State<MarkdownDocumentView> createState() => _MarkdownDocumentViewState();
}

class _MarkdownDocumentViewState extends State<MarkdownDocumentView> {
  late final Future<String> _content = rootBundle.loadString(
    widget.args.assetPath,
  );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: CustomScrollView(
        physics: const ClampingScrollPhysics(),
        slivers: [
          SettingsDetailSliverAppBar(
            icon: widget.args.icon,
            title: widget.args.title,
            subtitle: widget.args.subtitle,
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 60),
              child: FutureBuilder<String>(
                future: _content,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const Padding(
                      padding: EdgeInsets.only(top: 40),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  if (snapshot.hasError || !snapshot.hasData) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 40),
                      child: Text(
                        "We couldn't load this content. Please try again later.",
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium,
                      ),
                    );
                  }
                  return MarkdownBody(
                    data: snapshot.data!,
                    selectable: true,
                    styleSheet: MarkdownStyleSheet(
                      p: theme.textTheme.bodyMedium?.copyWith(
                        height: 1.6,
                        color: isDark ? Colors.white70 : Colors.black87,
                      ),
                      h1: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                      h2: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                      strong: const TextStyle(fontWeight: FontWeight.w700),
                      listBullet: theme.textTheme.bodyMedium,
                      blockSpacing: 14,
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
