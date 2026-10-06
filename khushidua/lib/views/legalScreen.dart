import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

import '../constants/colors.dart';
import '../constants/theme.dart';
import '../widgets/customSnackbar.dart';

/// The privacy policy and terms, read from the app's own assets and shown
/// natively rather than in a browser. The same Markdown files are what gets
/// published for the store listings, so the two never drift apart.
class LegalScreen extends StatelessWidget {
  const LegalScreen({super.key, this.initialTab = 0});

  /// 0 for the privacy policy, 1 for the terms.
  final int initialTab;

  static const _documents = [
    'assets/legal/privacy-policy.md',
    'assets/legal/terms-and-conditions.md',
  ];

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: _documents.length,
      initialIndex: initialTab,
      child: Scaffold(
        backgroundColor: AppSurface.page,
        appBar: AppBar(
          title: Text("Terms & Privacy".tr),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
            onPressed: () => Get.back(),
          ),
          bottom: TabBar(
            labelColor: rbluedark,
            unselectedLabelColor: AppText.onPageMuted,
            indicatorColor: rbluedark,
            labelStyle: const TextStyle(fontWeight: FontWeight.bold),
            tabs: [
              Tab(text: "Privacy Policy".tr),
              Tab(text: "Terms & Conditions".tr),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            for (final path in _documents) _LegalDocument(assetPath: path),
          ],
        ),
      ),
    );
  }
}

/// The references and credits, from `assets/legal/references.md`, rendered
/// the same way as the legal documents.
class ReferencesScreen extends StatelessWidget {
  const ReferencesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppSurface.page,
      appBar: AppBar(
        title: Text("References".tr),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Get.back(),
        ),
      ),
      body: const _LegalDocument(assetPath: 'assets/legal/references.md'),
    );
  }
}

class _LegalDocument extends StatefulWidget {
  const _LegalDocument({required this.assetPath});

  final String assetPath;

  @override
  State<_LegalDocument> createState() => _LegalDocumentState();
}

class _LegalDocumentState extends State<_LegalDocument>
    with AutomaticKeepAliveClientMixin {
  late final Future<String> _text = rootBundle.loadString(widget.assetPath);

  // Keeps each tab's scroll position when switching between them.
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return FutureBuilder<String>(
      future: _text,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        return SelectionArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpace.xl,
              AppSpace.lg,
              AppSpace.xl,
              AppSpace.xxl,
            ),
            children: _MarkdownBlocks.parse(snapshot.data!),
          ),
        );
      },
    );
  }
}

/// Renders the small Markdown subset the legal documents use: `#`–`###`
/// headings, `---` rules, `-` bullets (nested by two-space indent), and
/// inline `**bold**`, `` `code` `` and bare links. A line break inside a
/// paragraph is kept, so the documents read exactly as written.
abstract final class _MarkdownBlocks {
  static final _bullet = RegExp(r'^(\s*)- (.*)$');
  static final _heading = RegExp(r'^(#{1,3}) (.*)$');

  static const _body = TextStyle(color: rtext, fontSize: 14.5, height: 1.5);

  static List<Widget> parse(String markdown) {
    final widgets = <Widget>[];
    var lastWasGap = true;

    void gap(double height) {
      if (lastWasGap) return;
      widgets.add(SizedBox(height: height));
      lastWasGap = true;
    }

    for (final raw in markdown.split('\n')) {
      final line = raw.trimRight();

      if (line.trim().isEmpty) {
        gap(AppSpace.md);
        continue;
      }

      if (line.trim() == '---') {
        gap(AppSpace.sm);
        widgets.add(Divider(color: rbluedark.withValues(alpha: 0.1)));
        gap(AppSpace.sm);
        continue;
      }

      final heading = _heading.firstMatch(line);
      if (heading != null) {
        final level = heading.group(1)!.length;
        if (level > 1) gap(AppSpace.sm);
        widgets.add(
          _InlineText(
            heading.group(2)!,
            style: TextStyle(
              color: rbluedark,
              fontWeight: FontWeight.bold,
              height: 1.3,
              fontSize: switch (level) {
                1 => 24,
                2 => 18,
                _ => 15.5,
              },
            ),
          ),
        );
        widgets.add(const SizedBox(height: AppSpace.sm));
        lastWasGap = true;
        continue;
      }

      final bullet = _bullet.firstMatch(line);
      if (bullet != null) {
        final depth = bullet.group(1)!.length ~/ 2;
        widgets.add(
          Padding(
            padding: EdgeInsets.only(left: depth * 18.0, bottom: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 18,
                  child: Text(
                    depth == 0 ? '•' : '◦',
                    style: _body.copyWith(color: rbluedark),
                  ),
                ),
                Expanded(child: _InlineText(bullet.group(2)!, style: _body)),
              ],
            ),
          ),
        );
        lastWasGap = false;
        continue;
      }

      // A plain line; leading spaces continue an item of the list above.
      final indent = line.length - line.trimLeft().length;
      widgets.add(
        Padding(
          padding: EdgeInsets.only(left: indent > 0 ? 18.0 : 0),
          child: _InlineText(line.trimLeft(), style: _body),
        ),
      );
      lastWasGap = false;
    }
    return widgets;
  }
}

/// One line of text with its inline formatting. Stateful because link taps
/// need gesture recognizers, which must be disposed.
class _InlineText extends StatefulWidget {
  const _InlineText(this.text, {required this.style});

  final String text;
  final TextStyle style;

  @override
  State<_InlineText> createState() => _InlineTextState();
}

class _InlineTextState extends State<_InlineText> {
  static final _token = RegExp(r'\*\*(.+?)\*\*|`([^`]+)`|(https?://\S+)');

  final List<TapGestureRecognizer> _recognizers = [];

  void _disposeRecognizers() {
    for (final r in _recognizers) {
      r.dispose();
    }
    _recognizers.clear();
  }

  @override
  void dispose() {
    _disposeRecognizers();
    super.dispose();
  }

  Future<void> _open(String url) async {
    final opened = await launchUrl(
      Uri.parse(url),
      mode: LaunchMode.externalApplication,
    );
    if (!opened) {
      CustomSnackbar.show(
        'Error',
        'Could not open the link'.tr,
        isSuccess: false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    _disposeRecognizers();
    final spans = <InlineSpan>[];
    var cursor = 0;

    for (final match in _token.allMatches(widget.text)) {
      if (match.start > cursor) {
        spans.add(TextSpan(text: widget.text.substring(cursor, match.start)));
      }
      if (match.group(1) != null) {
        spans.add(
          TextSpan(
            text: match.group(1),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        );
      } else if (match.group(2) != null) {
        spans.add(
          TextSpan(
            text: match.group(2),
            style: TextStyle(
              fontFamily: 'monospace',
              backgroundColor: rbluedark.withValues(alpha: 0.06),
            ),
          ),
        );
      } else {
        // Sentence punctuation after a link is not part of it.
        var url = match.group(3)!;
        var trailing = '';
        while (url.endsWith('.') || url.endsWith(',') || url.endsWith(')')) {
          trailing = url[url.length - 1] + trailing;
          url = url.substring(0, url.length - 1);
        }
        final recognizer = TapGestureRecognizer()..onTap = () => _open(url);
        _recognizers.add(recognizer);
        spans.add(
          TextSpan(
            text: url,
            recognizer: recognizer,
            style: const TextStyle(
              color: Color(0xFF3949AB),
              decoration: TextDecoration.underline,
            ),
          ),
        );
        if (trailing.isNotEmpty) spans.add(TextSpan(text: trailing));
      }
      cursor = match.end;
    }
    if (cursor < widget.text.length) {
      spans.add(TextSpan(text: widget.text.substring(cursor)));
    }

    return Text.rich(TextSpan(style: widget.style, children: spans));
  }
}
