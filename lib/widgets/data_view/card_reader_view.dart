import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/ui_scale_provider.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Label + order configuration
// ─────────────────────────────────────────────────────────────────────────────

/// Display name for the reader item (keyed by _name value).
const _kReaderNames = <String, String>{
  'spcardreader': 'Built-in SD Card Reader',
};

String _readerName(String raw) =>
    _kReaderNames[raw] ?? _titleCase(raw.replaceAll('_', ' '));

/// Field labels for reader properties.
const _kReaderLabels = <String, String>{
  'spcardreader_vendor-id':          'Vendor ID',
  'spcardreader_device-id':          'Device ID',
  'spcardreader_subsystem_vendor-id':'Subsystem Vendor ID',
  'spcardreader_subsystem-id':       'Subsystem ID',
  'spcardreader_revision-id':        'Revision',
  'spcardreader_link-width':         'Link Width',
  'spcardreader_link-speed':         'Link Speed',
};

/// Preferred display order for reader properties.
const _kReaderOrder = <String>[
  'spcardreader_vendor-id',
  'spcardreader_device-id',
  'spcardreader_subsystem_vendor-id',
  'spcardreader_subsystem-id',
  'spcardreader_revision-id',
  'spcardreader_link-width',
  'spcardreader_link-speed',
];

/// Field labels for inserted-card properties.
const _kCardLabels = <String, String>{
  '_name':           'Name',
  'bsd_name':        'BSD Name',
  'file_system':     'File System',
  'free_space':      'Free Space',
  'size':            'Size',
  'detachable_drive':'Removable',
  'smart_status':    'S.M.A.R.T. Status',
  'product_name':    'Product Name',
  'vendor_name':     'Vendor',
  'speed':           'Speed',
  'capacity':        'Capacity',
};

String _readerLabel(String key) =>
    _kReaderLabels[key] ?? _titleCase(key.replaceAll('_', ' ').replaceAll('-', ' '));

String _cardLabel(String key) =>
    _kCardLabels[key] ?? _titleCase(key.replaceAll('_', ' ').replaceAll('-', ' '));

String _titleCase(String s) => s.isEmpty ? s : s
    .split(' ')
    .map((w) => w.isEmpty ? w : w[0].toUpperCase() + w.substring(1))
    .join(' ');

// ─────────────────────────────────────────────────────────────────────────────
// Public widget
// ─────────────────────────────────────────────────────────────────────────────

/// Renders SPCardReaderDataType — one block per reader, with inserted-card
/// details below if a card is present.
class CardReaderView extends StatefulWidget {
  final Map<String, dynamic> item;
  final String searchQuery;

  const CardReaderView({
    super.key,
    required this.item,
    this.searchQuery = '',
  });

  @override
  State<CardReaderView> createState() => _CardReaderViewState();
}

class _CardReaderViewState extends State<CardReaderView> {
  final _filterCtrl = TextEditingController();
  String _filter = '';

  String get _q => (_filter.isNotEmpty ? _filter : widget.searchQuery).toLowerCase();

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

    // Ordered reader fields (skip internal + card sub-items keys).
    final readerRows = _buildReaderRows();

    // Inserted cards from _items.
    final cards = _insertedCards();

    // Filter: hide everything if nothing matches.
    final q = _q;
    final filteredReader = q.isEmpty
        ? readerRows
        : readerRows.where((r) =>
            r.label.toLowerCase().contains(q) ||
            r.value.toLowerCase().contains(q)).toList();
    final filteredCards = q.isEmpty
        ? cards
        : cards.where((c) => _cardMatchesQuery(c, q)).toList();

    final hasContent = filteredReader.isNotEmpty || filteredCards.isNotEmpty;

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

        // ── Content ─────────────────────────────────────────────────────────
        Expanded(
          child: hasContent
              ? ListView(
                  padding: const EdgeInsets.fromLTRB(0, 4, 0, 24),
                  children: [
                    // Reader hardware block.
                    if (filteredReader.isNotEmpty) ...[
                      _SectionHeader(
                        label: _readerName(widget.item['_name']?.toString() ?? ''),
                        icon: Icons.sd_card_outlined,
                        theme: theme,
                        cs: cs,
                      ),
                      for (final row in filteredReader)
                        _KvRow(
                          label: row.label,
                          value: row.value,
                          query: q,
                          theme: theme,
                          cs: cs,
                        ),
                    ],

                    // Inserted cards block.
                    if (filteredCards.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      _SectionHeader(
                        label: 'Inserted Media',
                        icon: Icons.sd_storage_outlined,
                        theme: theme,
                        cs: cs,
                      ),
                      for (final card in filteredCards)
                        _CardBlock(card: card, query: q, theme: theme, cs: cs),
                    ],
                  ],
                )
              : Center(
                  child: Text(
                    q.isNotEmpty ? 'No matching fields' : 'No data',
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: cs.onSurfaceVariant),
                  ),
                ),
        ),
      ],
    );
  }

  List<({String label, String value})> _buildReaderRows() {
    final result = <({String label, String value})>[];
    // Emit in preferred order first.
    for (final key in _kReaderOrder) {
      final v = widget.item[key];
      if (v == null) continue;
      result.add((label: _readerLabel(key), value: v.toString()));
    }
    // Any remaining non-internal, non-items keys not in the order list.
    for (final e in widget.item.entries) {
      if (e.key.startsWith('_')) continue;
      if (_kReaderOrder.contains(e.key)) continue;
      if (e.value == null) continue;
      result.add((label: _readerLabel(e.key), value: e.value.toString()));
    }
    return result;
  }

  List<Map<String, dynamic>> _insertedCards() {
    final raw = widget.item['_items'];
    if (raw is! List) return [];
    return raw.whereType<Map<String, dynamic>>().toList();
  }

  bool _cardMatchesQuery(Map<String, dynamic> card, String q) =>
      card.entries.any((e) =>
          !e.key.startsWith('_') &&
          e.value.toString().toLowerCase().contains(q)) ||
      (card['_name']?.toString().toLowerCase().contains(q) ?? false);
}

// ─────────────────────────────────────────────────────────────────────────────
// Section header (reader name / "Inserted Media")
// ─────────────────────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String label;
  final IconData icon;
  final ThemeData theme;
  final ColorScheme cs;

  const _SectionHeader({
    required this.label,
    required this.icon,
    required this.theme,
    required this.cs,
  });

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 6),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: cs.outlineVariant.withAlpha(100), width: 0.5),
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 15, color: cs.primary),
            const SizedBox(width: 8),
            Text(
              label,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: cs.onSurface,
              ),
            ),
          ],
        ),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// KV row (single field)
// ─────────────────────────────────────────────────────────────────────────────

class _KvRow extends StatelessWidget {
  final String label;
  final String value;
  final String query;
  final ThemeData theme;
  final ColorScheme cs;

  const _KvRow({
    required this.label,
    required this.value,
    required this.query,
    required this.theme,
    required this.cs,
  });

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 220,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  label,
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: cs.onSurfaceVariant),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: query.isNotEmpty
                    ? _Highlight(text: value, query: query, theme: theme, cs: cs)
                    : SelectableText(
                        value,
                        style: theme.textTheme.bodyMedium,
                      ),
              ),
            ),
          ],
        ),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Inserted-card block (groups all card fields under its name)
// ─────────────────────────────────────────────────────────────────────────────

class _CardBlock extends StatelessWidget {
  final Map<String, dynamic> card;
  final String query;
  final ThemeData theme;
  final ColorScheme cs;

  const _CardBlock({
    required this.card,
    required this.query,
    required this.theme,
    required this.cs,
  });

  @override
  Widget build(BuildContext context) {
    final name = card['_name']?.toString() ?? 'Card';
    final rows = <({String label, String value})>[];
    for (final e in card.entries) {
      if (e.key == '_name') continue;
      if (e.key.startsWith('_')) continue;
      if (e.value == null) continue;
      rows.add((label: _cardLabel(e.key), value: e.value.toString()));
    }

    final q = query.toLowerCase();
    final visible = q.isEmpty
        ? rows
        : rows.where((r) =>
            r.label.toLowerCase().contains(q) ||
            r.value.toLowerCase().contains(q)).toList();

    if (visible.isEmpty && q.isNotEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
          child: Text(
            name,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: cs.onSurface,
            ),
          ),
        ),
        for (final row in visible)
          _KvRow(label: row.label, value: row.value, query: q, theme: theme, cs: cs),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Search highlight
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
    final lower = text.toLowerCase();
    final q     = query.toLowerCase();
    final spans = <TextSpan>[];
    int start = 0, idx;
    while ((idx = lower.indexOf(q, start)) != -1) {
      if (idx > start) spans.add(TextSpan(text: text.substring(start, idx)));
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
    if (start < text.length) spans.add(TextSpan(text: text.substring(start)));
    return SelectableText.rich(
      TextSpan(style: theme.textTheme.bodyMedium, children: spans),
    );
  }
}
