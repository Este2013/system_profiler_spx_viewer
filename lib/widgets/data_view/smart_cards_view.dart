import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/ui_scale_provider.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Label helpers
// ─────────────────────────────────────────────────────────────────────────────

const _kSectionLabels = <String, String>{
  'READERS':                  'Readers',
  'READERS_DRIVERS':          'Reader Drivers',
  'SMARTCARDS_DRIVERS':       'SmartCard Drivers',
  'AVAIL_SMARTCARDS_KEYCHAIN':'Available SmartCards (keychain)',
  'AVAIL_SMARTCARDS_TOKEN':   'Available SmartCards (token)',
};

String _sectionLabel(String raw) =>
    _kSectionLabels[raw] ?? raw.replaceAll('_', ' ').toLowerCase().split(' ').map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}').join(' ');

// ─────────────────────────────────────────────────────────────────────────────
// Widget
// ─────────────────────────────────────────────────────────────────────────────

/// Renders SPSmartCardsDataType.
///
/// Structure per item:
///   READERS            – empty (no sub-keys)
///   READERS_DRIVERS    – numbered string entries: {"#01": "bundle:ver (path)"}
///   SMARTCARDS_DRIVERS – same numbered pattern, multiple keys
///   AVAIL_*_KEYCHAIN   – _items: [{_name: "com.apple.setoken"}, …]
///   AVAIL_*_TOKEN      – same _items pattern
class SmartCardsView extends StatefulWidget {
  final List<Map<String, dynamic>> items;
  final String searchQuery;

  const SmartCardsView({
    super.key,
    required this.items,
    this.searchQuery = '',
  });

  @override
  State<SmartCardsView> createState() => _SmartCardsViewState();
}

class _SmartCardsViewState extends State<SmartCardsView> {
  final _filterCtrl = TextEditingController();
  String _filter = '';

  String get _q => _filter.isNotEmpty ? _filter : widget.searchQuery;

  @override
  void dispose() {
    _filterCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sp    = context.watch<UiScaleProvider>();
    final theme = Theme.of(context);
    final cs    = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Filter bar ──────────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: TextField(
            controller: _filterCtrl,
            decoration: InputDecoration(
              isDense: true,
              hintText: 'Filter…',
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

        // ── Content ────────────────────────────────────────────────────────
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
            children: [
              for (int i = 0; i < widget.items.length; i++)
                _SectionBlock(
                  item:        widget.items[i],
                  searchQuery: _q,
                  showDivider: i < widget.items.length - 1,
                ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Section block
// ─────────────────────────────────────────────────────────────────────────────

class _SectionBlock extends StatelessWidget {
  final Map<String, dynamic> item;
  final String searchQuery;
  final bool showDivider;

  const _SectionBlock({
    required this.item,
    required this.searchQuery,
    required this.showDivider,
  });

  /// Numbered driver entries: keys matching `#NN` pattern.
  List<MapEntry<String, String>> _numberedEntries() {
    final result = <MapEntry<String, String>>[];
    // Collect #01, #02, … keys in order.
    final numbered = item.entries
        .where((e) => _isNumberedKey(e.key))
        .toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    for (final e in numbered) {
      result.add(MapEntry(e.key, e.value?.toString() ?? ''));
    }
    return result;
  }

  /// Available-card names from `_items` sub-list.
  List<String> _availNames() {
    final sub = item['_items'];
    if (sub is! List) return [];
    return sub
        .whereType<Map>()
        .map((m) => m['_name']?.toString() ?? '')
        .where((s) => s.isNotEmpty)
        .toList();
  }

  static bool _isNumberedKey(String k) =>
      k.startsWith('#') && k.length > 1 && int.tryParse(k.substring(1)) != null;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs    = theme.colorScheme;
    final q     = searchQuery.toLowerCase();

    final rawName = item['_name']?.toString() ?? '';
    final label   = _sectionLabel(rawName);

    final numbered = _numberedEntries();
    final avail    = _availNames();

    // Determine content type.
    final hasNumbered = numbered.isNotEmpty;
    final hasAvail    = avail.isNotEmpty;
    final isEmpty     = !hasNumbered && !hasAvail;

    // Filter: hide entire section if nothing matches.
    if (q.isNotEmpty) {
      final labelHit = label.toLowerCase().contains(q);
      final entryHit = numbered.any((e) => e.value.toLowerCase().contains(q)) ||
          avail.any((s) => s.toLowerCase().contains(q));
      if (!labelHit && !entryHit) return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Section header ───────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              label,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: cs.onSurface,
              ),
            ),
          ),

          // ── Content ──────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.only(left: 12),
            child: isEmpty
                ? Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      'None',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: cs.onSurfaceVariant,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  )
                : hasNumbered
                    ? _NumberedList(entries: numbered, query: q, theme: theme, cs: cs)
                    : _AvailList(names: avail, query: q, theme: theme, cs: cs),
          ),

          if (showDivider) ...const [
            SizedBox(height: 6),
            Divider(),
            SizedBox(height: 2),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Numbered list (driver entries: #01, #02, …)
// ─────────────────────────────────────────────────────────────────────────────

class _NumberedList extends StatelessWidget {
  final List<MapEntry<String, String>> entries;
  final String query;
  final ThemeData theme;
  final ColorScheme cs;

  const _NumberedList({
    required this.entries,
    required this.query,
    required this.theme,
    required this.cs,
  });

  @override
  Widget build(BuildContext context) {
    final filtered = query.isEmpty
        ? entries
        : entries.where((e) => e.value.toLowerCase().contains(query)).toList();

    if (filtered.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: filtered.map((e) => Padding(
        padding: const EdgeInsets.only(bottom: 5),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Number badge.
            SizedBox(
              width: 36,
              child: Text(
                '${e.key}:',
                style: theme.textTheme.bodySmall?.copyWith(
                  color:      cs.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'monospace',
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: query.isNotEmpty
                  ? _Highlight(text: e.value, query: query, theme: theme, cs: cs)
                  : SelectableText(e.value, style: theme.textTheme.bodyMedium),
            ),
          ],
        ),
      )).toList(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Available-cards list (_items entries showing _name:)
// ─────────────────────────────────────────────────────────────────────────────

class _AvailList extends StatelessWidget {
  final List<String> names;
  final String query;
  final ThemeData theme;
  final ColorScheme cs;

  const _AvailList({
    required this.names,
    required this.query,
    required this.theme,
    required this.cs,
  });

  @override
  Widget build(BuildContext context) {
    final filtered = query.isEmpty
        ? names
        : names.where((s) => s.toLowerCase().contains(query)).toList();

    if (filtered.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: filtered.map((name) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '•',
              style: theme.textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: query.isNotEmpty
                  ? _Highlight(
                      text: '$name:',
                      query: query,
                      theme: theme,
                      cs: cs,
                    )
                  : SelectableText(
                      '$name:',
                      style: theme.textTheme.bodyMedium,
                    ),
            ),
          ],
        ),
      )).toList(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Highlight widget (matches query within text)
// ─────────────────────────────────────────────────────────────────────────────

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
    final lower  = text.toLowerCase();
    final q      = query.toLowerCase();
    final spans  = <TextSpan>[];
    int start = 0, idx;
    while ((idx = lower.indexOf(q, start)) != -1) {
      if (idx > start) spans.add(TextSpan(text: text.substring(start, idx)));
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
    if (start < text.length) spans.add(TextSpan(text: text.substring(start)));
    return SelectableText.rich(
        TextSpan(style: theme.textTheme.bodyMedium, children: spans));
  }
}
