import 'package:flutter/material.dart';

/// Renders [text] with every occurrence of [query] highlighted using
/// the theme's tertiaryContainer / onTertiaryContainer colors.
///
/// Falls back to plain [SelectableText] when [query] is empty or has
/// no matches. Supports optional [style] and [overflow] overrides so it
/// can be used for both value cells (ellipsis) and label columns (clip).
class HighlightText extends StatelessWidget {
  final String text;
  final String query;
  final TextStyle? style;
  final TextOverflow overflow;

  const HighlightText({
    super.key,
    required this.text,
    required this.query,
    this.style,
    this.overflow = TextOverflow.clip,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final base = style ?? theme.textTheme.bodyMedium;

    if (query.isEmpty) {
      return SelectableText(text, style: base);
    }

    final lower = text.toLowerCase();
    final q = query.toLowerCase();

    if (!lower.contains(q)) {
      return SelectableText(text, style: base);
    }

    final spans = <TextSpan>[];
    int start = 0;
    int idx;
    while ((idx = lower.indexOf(q, start)) != -1) {
      if (idx > start) {
        spans.add(TextSpan(text: text.substring(start, idx)));
      }
      spans.add(TextSpan(
        text: text.substring(idx, idx + query.length),
        style: TextStyle(
          backgroundColor: cs.tertiaryContainer,
          color: cs.onTertiaryContainer,
          fontWeight: FontWeight.bold,
        ),
      ));
      start = idx + query.length;
    }
    if (start < text.length) {
      spans.add(TextSpan(text: text.substring(start)));
    }

    return SelectableText.rich(
      TextSpan(style: base, children: spans),
    );
  }
}
