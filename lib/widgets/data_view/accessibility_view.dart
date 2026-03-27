import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/ui_scale_provider.dart';
import '../../utils/key_formatter.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Label + value overrides
// ─────────────────────────────────────────────────────────────────────────────

const _kLabels = <String, String>{
  'contrast':     'Contrast',
  'cursor_mag':   'Cursor Magnification',
  'display':      'Display',
  'flash_screen': 'Flash Screen',
  'keyboardZoom': 'Keyboard Zoom',
  'mouse_keys':   'Mouse Keys',
  'scrollZoom':   'Scroll Zoom',
  'slow_keys':    'Slow Keys',
  'sticky_keys':  'Sticky Keys',
  'voiceover':    'VoiceOver',
  'zoomMode':     'Zoom Mode',
};

String _label(String key) => _kLabels[key] ?? formatKey(key);

String _value(String key, dynamic raw) {
  if (raw == null) return '—';
  if (raw is bool) return raw ? 'Yes' : 'No';
  final s = raw.toString();

  // display: "black_on_white" → "Black On White" (replace _ with space)
  if (key == 'display') {
    return s
        .replaceAll('_', ' ')
        .split(' ')
        .where((w) => w.isNotEmpty)
        .map((w) => w[0].toUpperCase() + w.substring(1))
        .join(' ');
  }

  // zoomMode: "zoom_full_screen" → strip "zoom_" prefix then replace _ with space
  if (key == 'zoomMode') {
    final stripped = s.startsWith('zoom_') ? s.substring('zoom_'.length) : s;
    return stripped
        .replaceAll('_', ' ')
        .split(' ')
        .where((w) => w.isNotEmpty)
        .map((w) => w[0].toUpperCase() + w.substring(1))
        .join(' ');
  }

  final cleaned = formatSpxValue(s);
  return cleaned.isEmpty ? s : cleaned;
}

// ─────────────────────────────────────────────────────────────────────────────
// Widget
// ─────────────────────────────────────────────────────────────────────────────

class AccessibilityView extends StatefulWidget {
  final Map<String, dynamic> item;
  final String searchQuery;

  const AccessibilityView({
    super.key,
    required this.item,
    this.searchQuery = '',
  });

  @override
  State<AccessibilityView> createState() => _AccessibilityViewState();
}

class _AccessibilityViewState extends State<AccessibilityView> {
  final _filterCtrl = TextEditingController();
  String _filter = '';

  String get _q => _filter.isNotEmpty ? _filter : widget.searchQuery;

  @override
  void dispose() {
    _filterCtrl.dispose();
    super.dispose();
  }

  List<({String key, String label, String value})> get _rows {
    final q = _q.toLowerCase();
    return widget.item.entries
        .where((e) => !isInternalKey(e.key) && e.key != '_name')
        .where((e) => e.value is! Map && e.value is! List)
        .map((e) => (
              key:   e.key,
              label: _label(e.key),
              value: _value(e.key, e.value),
            ))
        .where((r) =>
            q.isEmpty ||
            r.label.toLowerCase().contains(q) ||
            r.value.toLowerCase().contains(q))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final sp    = context.watch<UiScaleProvider>();
    final theme = Theme.of(context);
    final cs    = theme.colorScheme;
    final rows  = _rows;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: TextField(
            controller: _filterCtrl,
            decoration: InputDecoration(
              isDense: true,
              hintText: 'Filter fields…',
              prefixIcon: Icon(Icons.search, size: sp.sz(18)),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: cs.outlineVariant),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              suffixIcon: _filter.isNotEmpty
                  ? IconButton(
                      icon: Icon(Icons.close, size: sp.sz(16)),
                      onPressed: () {
                        _filterCtrl.clear();
                        setState(() => _filter = '');
                      },
                    )
                  : null,
            ),
            onChanged: (v) => setState(() => _filter = v),
          ),
        ),
        Expanded(
          child: rows.isEmpty
              ? Center(
                  child: Text(
                    'No matching fields',
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: cs.onSurfaceVariant),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                  itemCount: rows.length,
                  separatorBuilder: (context, index) => Divider(
                    height: 1,
                    color: cs.outlineVariant.withAlpha(80),
                  ),
                  itemBuilder: (context, i) => _Row(
                    label:       rows[i].label,
                    value:       rows[i].value,
                    searchQuery: _q,
                    keyWidth:    sp.sz(240),
                    theme:       theme,
                    cs:          cs,
                  ),
                ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Row + highlight
// ─────────────────────────────────────────────────────────────────────────────

class _Row extends StatelessWidget {
  final String label;
  final String value;
  final String searchQuery;
  final double keyWidth;
  final ThemeData theme;
  final ColorScheme cs;

  const _Row({
    required this.label,
    required this.value,
    required this.searchQuery,
    required this.keyWidth,
    required this.theme,
    required this.cs,
  });

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: keyWidth,
              child: Text(
                label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color:      cs.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: searchQuery.isNotEmpty
                  ? _Highlight(
                      text: value, query: searchQuery, theme: theme, cs: cs)
                  : SelectableText(value, style: theme.textTheme.bodyMedium),
            ),
          ],
        ),
      );
}

class _Highlight extends StatelessWidget {
  final String text;
  final String query;
  final ThemeData theme;
  final ColorScheme cs;

  const _Highlight({
    required this.text,
    required this.query,
    required this.theme,
    required this.cs,
  });

  @override
  Widget build(BuildContext context) {
    final lower = text.toLowerCase();
    final q     = query.toLowerCase();
    final spans = <TextSpan>[];
    int start = 0, idx;
    while ((idx = lower.indexOf(q, start)) != -1) {
      if (idx > start) {
        spans.add(TextSpan(text: text.substring(start, idx)));
      }
      spans.add(TextSpan(
        text: text.substring(idx, idx + query.length),
        style: TextStyle(
          backgroundColor: cs.tertiaryContainer,
          color:           cs.onTertiaryContainer,
          fontWeight:      FontWeight.bold,
        ),
      ));
      start = idx + query.length;
    }
    if (start < text.length) {
      spans.add(TextSpan(text: text.substring(start)));
    }
    return SelectableText.rich(
        TextSpan(style: theme.textTheme.bodyMedium, children: spans));
  }
}
