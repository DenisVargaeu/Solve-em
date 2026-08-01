library;

import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:url_launcher/url_launcher.dart';

/// Renders text that may contain LaTeX math and Markdown formatting.
///
/// Supported math delimiters:
/// * inline math:  `$...$`
/// * display math: `$$...$$` or `\[...\]`
///
/// Markdown such as **bold**, *italic*, headings, lists and code blocks is
/// rendered for readability. Plain text with no math or markdown keeps the
/// fast [Text] path so single-line truncation still shows an ellipsis.

class MathText extends StatelessWidget {
  const MathText(
    this.data, {
    super.key,
    this.style,
    this.textAlign = TextAlign.left,
    this.maxLines,
    this.selectable = false,
  });

  /// Raw content, possibly containing LaTeX delimiters or Markdown.
  final String data;

  /// Base text style applied to non-math text.
  final TextStyle? style;

  final TextAlign textAlign;
  final int? maxLines;
  final bool selectable;

  /// Triggers the rich renderer: a LaTeX delimiter or a Markdown marker.
  static final RegExp _richTrigger = RegExp(r'[$\\\*_#`>~\n]');

  @override
  Widget build(BuildContext context) {
    final effectiveStyle = style ?? DefaultTextStyle.of(context).style;
    if (!_richTrigger.hasMatch(data) && maxLines != null) {
      // Plain single-line preview: keep the cheap Text with an ellipsis.
      return Text(
        data,
        style: effectiveStyle,
        textAlign: textAlign,
        maxLines: maxLines,
        overflow: TextOverflow.ellipsis,
      );
    }
    return _MarkdownMath(
      data,
      style: effectiveStyle,
      textAlign: textAlign,
      maxLines: maxLines,
      selectable: selectable,
    );
  }
}

/// Renders [data] as Markdown with LaTeX math support.
///
/// A custom inline syntax catches `$...$` / `$$...$$` / `\[...\]` before the
/// default Markdown syntaxes run, and a matching element builder turns them
/// into `flutter_math` widgets that flow inline with the surrounding text.
class _MarkdownMath extends StatelessWidget {
  const _MarkdownMath(
    this.data, {
    required this.style,
    required this.textAlign,
    this.maxLines,
    this.selectable = false,
  });

  final String data;
  final TextStyle style;
  final TextAlign textAlign;
  final int? maxLines;
  final bool selectable;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final fontSize = style.fontSize ?? 14.0;

    final styles = MarkdownStyleSheet.fromTheme(theme).copyWith(
      p: style,
      pPadding: EdgeInsets.zero,
      code: style.copyWith(
        fontFamily: 'monospace',
        fontSize: fontSize * 0.85,
        backgroundColor: scheme.surfaceContainerHighest,
      ),
      h1: style.copyWith(fontSize: fontSize + 6, fontWeight: FontWeight.w700),
      h2: style.copyWith(fontSize: fontSize + 4, fontWeight: FontWeight.w700),
      h3: style.copyWith(fontSize: fontSize + 2, fontWeight: FontWeight.w600),
      h4: style.copyWith(fontWeight: FontWeight.w600),
      h5: style.copyWith(fontWeight: FontWeight.w600),
      h6: style.copyWith(fontWeight: FontWeight.w600),
      em: style.copyWith(fontStyle: FontStyle.italic),
      strong: style.copyWith(fontWeight: FontWeight.w700),
      del: style.copyWith(decoration: TextDecoration.lineThrough),
      blockquote: style.copyWith(
        fontStyle: FontStyle.italic,
        color: scheme.onSurfaceVariant,
      ),
      blockquoteDecoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10),
        border: Border(left: BorderSide(color: scheme.primary, width: 3)),
      ),
      blockquotePadding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      codeblockDecoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10),
      ),
      codeblockPadding: const EdgeInsets.all(12),
      listBullet: style,
      listBulletPadding: const EdgeInsets.only(right: 8),
      blockSpacing: 10,
      listIndent: 18,
      horizontalRuleDecoration: BoxDecoration(
        border: Border(top: BorderSide(color: scheme.outlineVariant)),
      ),
    );

    Widget body = MarkdownBody(
      data: data,
      selectable: selectable,
      styleSheet: styles,
      inlineSyntaxes: [_MathInlineSyntax()],
      builders: {
        'math': _MathElementBuilder(block: false),
        'mathblock': _MathElementBuilder(block: true),
      },
      onTapLink: (_, href, _) => _openLink(href),
    );

    final maxLines = this.maxLines;
    if (maxLines != null) {
      // Clamp to N text lines without triggering flex-overflow warnings: lay
      // the body out with unbounded height and clip it to the expected height.
      final lineHeight = fontSize * (style.height ?? 1.5);
      body = SizedBox(
        height: maxLines * lineHeight,
        child: ClipRect(
          child: OverflowBox(
            alignment: Alignment.topLeft,
            minHeight: 0,
            maxHeight: double.infinity,
            child: body,
          ),
        ),
      );
    }
    return body;
  }

  Future<void> _openLink(String? href) async {
    if (href == null) return;
    final uri = Uri.tryParse(href);
    if (uri == null || !uri.hasScheme) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

/// Inline Markdown syntax that matches LaTeX math delimiters before any other
/// inline syntax (emphasis, code, …) gets a chance to see inside them.
class _MathInlineSyntax extends md.InlineSyntax {
  _MathInlineSyntax() : super(_pattern, caseSensitive: false);

  // `$$...$$` or `\[...\]` for display math, `$...$` for inline math.
  static const String _pattern =
      r'(\$\$[\s\S]+?\$\$|\\\[[\s\S]+?\\\]|\$[\s\S]+?\$)';

  @override
  bool onMatch(md.InlineParser parser, Match match) {
    final raw = match.group(1)!;
    final isBlock = raw.startsWith(r'$$') || raw.startsWith(r'\[');
    final latex = isBlock
        ? raw.substring(2, raw.length - 2)
        : raw.substring(1, raw.length - 1);
    parser.addNode(
      md.Element(isBlock ? 'mathblock' : 'math', [md.Text(latex)]),
    );
    return true;
  }
}

/// Builds a `flutter_math` widget for math elements.
class _MathElementBuilder extends MarkdownElementBuilder {
  _MathElementBuilder({required this.block});

  /// Whether this is display math (`$$…$$`) rendered on its own line.
  final bool block;

  @override
  bool isBlockElement() => false;

  @override
  Widget? visitElementAfterWithContext(
    BuildContext context,
    md.Element element,
    TextStyle? preferredStyle,
    TextStyle? parentStyle,
  ) {
    final latex = element.textContent.trim();
    if (latex.isEmpty) return null;
    final textStyle = parentStyle ?? preferredStyle ?? const TextStyle();

    final tex = Math.tex(
      latex,
      mathStyle: block ? MathStyle.display : MathStyle.text,
      textStyle: block
          ? textStyle.copyWith(fontSize: (textStyle.fontSize ?? 14) + 2)
          : textStyle,
      onErrorFallback: (_) => Text(latex, style: textStyle),
    );

    if (!block) return tex;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Center(child: tex),
    );
  }
}
