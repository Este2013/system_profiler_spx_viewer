import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../utils/key_formatter.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Public widget
// ─────────────────────────────────────────────────────────────────────────────

/// Two-pane view for sections where the real items are nested one level deep
/// inside a single wrapper item (e.g. Audio → "coreaudio_device" → devices).
///
/// Left panel: selectable item list.
/// Right panel: KV detail for the selected item.
class NestedItemsView extends StatefulWidget {
  final List<Map<String, dynamic>> items;
  final String searchQuery;

  /// Optional custom key-label formatter (defaults to [formatKey]).
  final String Function(String) keyFormatter;

  /// Optional function to derive a subtitle line for each list row.
  final String? Function(Map<String, dynamic>)? subtitleBuilder;

  /// Icon shown in the detail-panel header.
  final IconData detailIcon;

  NestedItemsView({
    super.key,
    required this.items,
    this.searchQuery = '',
    String Function(String)? keyFormatter,
    this.subtitleBuilder,
    this.detailIcon = Icons.tune,
  }) : keyFormatter = keyFormatter ?? formatKey;

  @override
  State<NestedItemsView> createState() => _NestedItemsViewState();
}

class _NestedItemsViewState extends State<NestedItemsView> {
  Map<String, dynamic>? _selected;

  @override
  void initState() {
    super.initState();
    if (widget.items.isNotEmpty) _selected = widget.items.first;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Item list ──────────────────────────────────────────────────────
        SizedBox(
          width: 260,
          child: _ListPanel(
            items: widget.items,
            selected: _selected,
            onSelect: (item) => setState(() => _selected = item),
            subtitleBuilder: widget.subtitleBuilder,
          ),
        ),

        VerticalDivider(width: 1, thickness: 1, color: cs.outlineVariant),

        // ── Detail panel ───────────────────────────────────────────────────
        Expanded(
          child: _selected == null
              ? Center(
                  child: Text(
                    'Select an item',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: cs.onSurface.withAlpha(100),
                        ),
                  ),
                )
              : _DetailPanel(
                  key: ValueKey(_selected!['_name']),
                  item: _selected!,
                  keyFormatter: widget.keyFormatter,
                  searchQuery: widget.searchQuery,
                  icon: widget.detailIcon,
                ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Left panel
// ─────────────────────────────────────────────────────────────────────────────

class _ListPanel extends StatelessWidget {
  final List<Map<String, dynamic>> items;
  final Map<String, dynamic>? selected;
  final ValueChanged<Map<String, dynamic>> onSelect;
  final String? Function(Map<String, dynamic>)? subtitleBuilder;

  const _ListPanel({
    required this.items,
    required this.selected,
    required this.onSelect,
    this.subtitleBuilder,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      color: cs.surfaceContainerLow,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 6),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          final isSel = selected == item;
          final name = item['_name']?.toString() ?? 'Unknown';
          final subtitle = subtitleBuilder?.call(item);
          final theme = Theme.of(context);

          return Material(
            color: isSel ? cs.primaryContainer : Colors.transparent,
            child: InkWell(
              onTap: () => onSelect(item),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 12, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight:
                            isSel ? FontWeight.w600 : FontWeight.normal,
                        color: isSel
                            ? cs.onPrimaryContainer
                            : cs.onSurface,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (subtitle != null && subtitle.isNotEmpty)
                      Text(
                        subtitle,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: isSel
                              ? cs.onPrimaryContainer.withAlpha(160)
                              : cs.onSurfaceVariant,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Detail panel
// ─────────────────────────────────────────────────────────────────────────────

class _DetailPanel extends StatelessWidget {
  final Map<String, dynamic> item;
  final String Function(String) keyFormatter;
  final String searchQuery;
  final IconData icon;

  const _DetailPanel({
    super.key,
    required this.item,
    required this.keyFormatter,
    required this.searchQuery,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final name = item['_name']?.toString() ?? 'Unknown';
    final fields = item.entries.where((e) => !isInternalKey(e.key)).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Header ─────────────────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 10),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: cs.outlineVariant, width: 0.5),
            ),
          ),
          child: Row(
            children: [
              Icon(icon, size: 22, color: cs.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  name,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),

        // ── KV fields ──────────────────────────────────────────────────────
        Expanded(
          child: fields.isEmpty
              ? Center(
                  child: Text(
                    'No details available',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: cs.onSurface.withAlpha(100),
                    ),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  itemCount: fields.length,
                  separatorBuilder: (_, __) => Divider(
                    height: 1,
                    color: cs.outlineVariant.withAlpha(80),
                    indent: 20,
                    endIndent: 20,
                  ),
                  itemBuilder: (context, i) {
                    final e = fields[i];
                    return _FieldRow(
                      label: keyFormatter(e.key),
                      value: _renderValue(e.value),
                      searchQuery: searchQuery,
                    );
                  },
                ),
        ),
      ],
    );
  }

  String _renderValue(dynamic v) {
    if (v == null) return '—';
    if (v is bool) return v ? 'Yes' : 'No';
    if (v is DateTime) {
      return DateFormat('yyyy-MM-dd  HH:mm:ss').format(v.toLocal());
    }
    // Whole-number doubles (e.g. 48000.0) → clean integer string.
    if (v is double) {
      return v == v.truncateToDouble()
          ? v.toInt().toString()
          : v.toStringAsFixed(2);
    }
    if (v is List) {
      return v.map(_renderValue).join(', ');
    }
    if (v is Map) {
      return v.entries
          .take(5)
          .map((e) => '${e.key}: ${_renderValue(e.value)}')
          .join('; ');
    }
    if (v is String) return formatSpxValue(v);
    return v.toString();
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _FieldRow extends StatelessWidget {
  final String label;
  final String value;
  final String searchQuery;

  const _FieldRow({
    required this.label,
    required this.value,
    required this.searchQuery,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 190,
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: cs.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: searchQuery.isNotEmpty
                ? _HighlightText(
                    text: value,
                    query: searchQuery,
                  )
                : SelectableText(
                    value,
                    style: theme.textTheme.bodyMedium,
                  ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _HighlightText extends StatelessWidget {
  final String text;
  final String query;
  const _HighlightText({required this.text, required this.query});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    final lower = text.toLowerCase();
    final q = query.toLowerCase();
    final spans = <TextSpan>[];
    int start = 0;
    int idx;
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
        TextSpan(style: theme.textTheme.bodyMedium, children: spans));
  }
}
