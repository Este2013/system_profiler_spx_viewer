import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/spx_section.dart';
import '../../utils/key_formatter.dart';

/// Displays a list of SPX items as a sortable, filterable table.
class ItemsTable extends StatefulWidget {
  final SpxSection section;
  final String searchQuery;

  const ItemsTable({
    super.key,
    required this.section,
    this.searchQuery = '',
  });

  @override
  State<ItemsTable> createState() => _ItemsTableState();
}

class _ItemsTableState extends State<ItemsTable> {
  final _filterController = TextEditingController();
  String _filter = '';
  String? _sortColumn;
  bool _sortAscending = true;

  static const int _maxColumns = 7;

  @override
  void dispose() {
    _filterController.dispose();
    super.dispose();
  }

  List<String> get _displayColumns {
    final keys = widget.section.columnKeys;
    final filtered = keys
        .where((k) => !k.startsWith('_') || k == '_name')
        .toList();
    // Limit visible columns for readability
    return filtered.take(_maxColumns).toList();
  }

  List<Map<String, dynamic>> get _processedItems {
    var items = widget.section.items.toList();

    // Filter
    final effectiveFilter =
        _filter.isNotEmpty ? _filter : widget.searchQuery;
    if (effectiveFilter.isNotEmpty) {
      final q = effectiveFilter.toLowerCase();
      items = items.where((item) {
        return item.values.any(
          (v) => _flattenToString(v).toLowerCase().contains(q),
        );
      }).toList();
    }

    // Sort
    if (_sortColumn != null) {
      items.sort((a, b) {
        final av = a[_sortColumn];
        final bv = b[_sortColumn];
        final cmp = _compareValues(av, bv);
        return _sortAscending ? cmp : -cmp;
      });
    }

    return items;
  }

  int _compareValues(dynamic a, dynamic b) {
    if (a == null && b == null) return 0;
    if (a == null) return 1;
    if (b == null) return -1;
    if (a is num && b is num) return a.compareTo(b);
    if (a is DateTime && b is DateTime) return a.compareTo(b);
    return a.toString().toLowerCase().compareTo(b.toString().toLowerCase());
  }

  void _toggleSort(String column) {
    setState(() {
      if (_sortColumn == column) {
        _sortAscending = !_sortAscending;
      } else {
        _sortColumn = column;
        _sortAscending = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final columns = _displayColumns;
    final items = _processedItems;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final total = widget.section.items.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Filter bar ──────────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _filterController,
                  decoration: InputDecoration(
                    isDense: true,
                    hintText: 'Filter $total items...',
                    prefixIcon: const Icon(Icons.search, size: 18),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide:
                          BorderSide(color: colorScheme.outlineVariant),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    suffixIcon: _filter.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.close, size: 16),
                            onPressed: () {
                              _filterController.clear();
                              setState(() => _filter = '');
                            },
                          )
                        : null,
                  ),
                  onChanged: (v) => setState(() => _filter = v),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '${items.length} / $total',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),

        // ── Column headers ──────────────────────────────────────────────────
        Container(
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerLow,
            border: Border(
              bottom: BorderSide(
                color: colorScheme.outlineVariant,
                width: 0.5,
              ),
            ),
          ),
          child: Row(
            children: [
              // Expand indicator space
              const SizedBox(width: 24),
              for (final col in columns)
                Expanded(
                  child: InkWell(
                    onTap: () => _toggleSort(col),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 9,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              formatKey(col),
                              style: theme.textTheme.labelMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: _sortColumn == col
                                    ? colorScheme.primary
                                    : colorScheme.onSurfaceVariant,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (_sortColumn == col)
                            Icon(
                              _sortAscending
                                  ? Icons.arrow_upward_rounded
                                  : Icons.arrow_downward_rounded,
                              size: 13,
                              color: colorScheme.primary,
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),

        // ── Rows ────────────────────────────────────────────────────────────
        Expanded(
          child: items.isEmpty
              ? Center(
                  child: Text(
                    'No matching items',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                )
              : ListView.separated(
                  itemCount: items.length,
                  separatorBuilder: (context, index) => Divider(
                    height: 1,
                    color: colorScheme.outlineVariant.withAlpha(60),
                  ),
                  itemBuilder: (context, i) => _ItemRow(
                    item: items[i],
                    columns: columns,
                    searchQuery:
                        _filter.isNotEmpty ? _filter : widget.searchQuery,
                  ),
                ),
        ),
      ],
    );
  }

  String _flattenToString(dynamic value) {
    if (value is Map) {
      return value.values.map(_flattenToString).join(' ');
    }
    if (value is List) {
      return value.map(_flattenToString).join(' ');
    }
    return value.toString();
  }
}

// ---------------------------------------------------------------------------

class _ItemRow extends StatefulWidget {
  final Map<String, dynamic> item;
  final List<String> columns;
  final String searchQuery;

  const _ItemRow({
    required this.item,
    required this.columns,
    this.searchQuery = '',
  });

  @override
  State<_ItemRow> createState() => _ItemRowState();
}

class _ItemRowState extends State<_ItemRow> {
  bool _expanded = false;

  bool get _hasSubItems {
    final sub = widget.item['_items'];
    return sub is List && sub.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Main row
        InkWell(
          onTap: _hasSubItems
              ? () => setState(() => _expanded = !_expanded)
              : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 1),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Expand indicator
                SizedBox(
                  width: 24,
                  child: _hasSubItems
                      ? Icon(
                          _expanded
                              ? Icons.expand_more
                              : Icons.chevron_right,
                          size: 16,
                          color: colorScheme.onSurfaceVariant,
                        )
                      : null,
                ),
                for (final col in widget.columns)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      child: _buildCell(context, widget.item[col]),
                    ),
                  ),
              ],
            ),
          ),
        ),

        // Sub-items expansion
        if (_expanded && _hasSubItems)
          Container(
            margin: const EdgeInsets.only(left: 24, right: 8, bottom: 6),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: colorScheme.outlineVariant.withAlpha(120),
              ),
            ),
            child: _SubItemsView(
              subItems: (widget.item['_items'] as List)
                  .whereType<Map<String, dynamic>>()
                  .toList(),
            ),
          ),
      ],
    );
  }

  Widget _buildCell(BuildContext context, dynamic value) {
    final str = _formatCell(value);
    final q = widget.searchQuery;

    if (q.isNotEmpty && str.toLowerCase().contains(q.toLowerCase())) {
      return _HighlightText(text: str, query: q);
    }

    return Text(
      str,
      overflow: TextOverflow.ellipsis,
      style: Theme.of(context).textTheme.bodyMedium,
    );
  }

  String _formatCell(dynamic value) {
    if (value == null) return '—';
    if (value is bool) return value ? 'Yes' : 'No';
    if (value is DateTime) {
      return DateFormat('yyyy-MM-dd').format(value.toLocal());
    }
    if (value is List) {
      if (value.every((e) => e is! Map && e is! List)) {
        return value.join(', ');
      }
      return '[${value.length} items]';
    }
    if (value is Map) return '{${value.length} fields}';
    return value.toString();
  }
}

// ---------------------------------------------------------------------------

class _SubItemsView extends StatelessWidget {
  final List<Map<String, dynamic>> subItems;

  const _SubItemsView({required this.subItems});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: subItems.map((sub) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: sub.entries
                .where((e) => !isInternalKey(e.key))
                .map((e) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 1),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 180,
                            child: Text(
                              formatKey(e.key),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _fmt(e.value),
                              style: theme.textTheme.bodySmall,
                            ),
                          ),
                        ],
                      ),
                    ))
                .toList(),
          ),
        );
      }).toList(),
    );
  }

  String _fmt(dynamic v) {
    if (v == null) return '—';
    if (v is bool) return v ? 'Yes' : 'No';
    if (v is DateTime) {
      return DateFormat('yyyy-MM-dd HH:mm:ss').format(v.toLocal());
    }
    if (v is List) return v.join(', ');
    if (v is Map) return '{${v.length} fields}';
    return v.toString();
  }
}

// ---------------------------------------------------------------------------

class _HighlightText extends StatelessWidget {
  final String text;
  final String query;

  const _HighlightText({required this.text, required this.query});

  @override
  Widget build(BuildContext context) {
    if (query.isEmpty) {
      return Text(text, overflow: TextOverflow.ellipsis);
    }

    final theme = Theme.of(context);
    final lower = text.toLowerCase();
    final queryLower = query.toLowerCase();
    final spans = <TextSpan>[];
    int start = 0;

    int idx;
    while ((idx = lower.indexOf(queryLower, start)) != -1) {
      if (idx > start) {
        spans.add(TextSpan(text: text.substring(start, idx)));
      }
      spans.add(TextSpan(
        text: text.substring(idx, idx + query.length),
        style: TextStyle(
          backgroundColor: theme.colorScheme.tertiaryContainer,
          color: theme.colorScheme.onTertiaryContainer,
          fontWeight: FontWeight.bold,
        ),
      ));
      start = idx + query.length;
    }

    if (start < text.length) {
      spans.add(TextSpan(text: text.substring(start)));
    }

    return RichText(
      overflow: TextOverflow.ellipsis,
      text: TextSpan(
        style: theme.textTheme.bodyMedium,
        children: spans,
      ),
    );
  }
}
