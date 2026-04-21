import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/spx_section.dart';
import '../../providers/ui_scale_provider.dart';
import '../../utils/key_formatter.dart';
import '../highlight_text.dart';

/// Displays a list of SPX items as a sortable, filterable table.
class ItemsTable extends StatefulWidget {
  final SpxSection section;
  final String searchQuery;
  /// Optional key label formatter. Defaults to [formatKey].
  final String Function(String) keyFormatter;

  const ItemsTable({
    super.key,
    required this.section,
    this.searchQuery = '',
    this.keyFormatter = formatKey,
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

  /// Returns true when [q] matches the section display name (i.e. the user
  /// searched for the section itself rather than content within it).
  bool _isNameMatch(String q) =>
      q.isNotEmpty &&
      widget.section.displayName.toLowerCase().contains(q.toLowerCase());

  /// Syncs the local filter field to [q], clearing it when [q] is the section
  /// name so all items are shown. Safe to call from initState (no setState).
  void _syncLocalFilter(String q) {
    _filter = _isNameMatch(q) ? '' : q;
    _filterController.text = _filter;
  }

  /// Filtering uses only the local field; highlighting falls back to the
  /// global query so matches stay visible even when the filter is cleared.
  String get _highlightQuery =>
      _filter.isNotEmpty ? _filter : widget.searchQuery;

  @override
  void initState() {
    super.initState();
    _syncLocalFilter(widget.searchQuery);
  }

  @override
  void didUpdateWidget(covariant ItemsTable old) {
    super.didUpdateWidget(old);
    if (old.searchQuery != widget.searchQuery) {
      setState(() => _syncLocalFilter(widget.searchQuery));
    }
  }

  @override
  void dispose() {
    _filterController.dispose();
    super.dispose();
  }

  List<String> get _displayColumns {
    final keys = widget.section.columnKeys;
    final allItems = widget.section.items;
    final filtered = keys
        .where((k) => !k.startsWith('_') || k == '_name')
        // Drop columns where every single row has a null or empty-string value.
        .where((k) => allItems.any((item) {
              final v = item[k];
              return v != null && !(v is String && v.isEmpty);
            }))
        .toList();
    // Limit visible columns for readability
    return filtered.take(_maxColumns).toList();
  }

  List<Map<String, dynamic>> get _processedItems {
    var items = widget.section.items.toList();

    // Filter
    if (_filter.isNotEmpty) {
      final q = _filter.toLowerCase();
      items = items.where((item) {
        return item.entries.any((e) =>
          widget.keyFormatter(e.key).toLowerCase().contains(q) ||
          _flattenToString(e.value).toLowerCase().contains(q),
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
    final sp = context.watch<UiScaleProvider>();
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
                    prefixIcon: Icon(Icons.search, size: sp.sz(18)),
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
                            icon: Icon(Icons.close, size: sp.sz(16)),
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
                              widget.keyFormatter(col),
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
                              size: sp.sz(13),
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
          child: SelectionArea(
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
                      searchQuery: _highlightQuery,
                      keyFormatter: widget.keyFormatter,
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  String _flattenToString(dynamic value) {
    if (value is Map) {
      return value.values.map(_flattenToString).join(', ');
    }
    if (value is List) {
      return value.map(_flattenToString).join(', ');
    }
    return value.toString();
  }
}

// ---------------------------------------------------------------------------

class _ItemRow extends StatefulWidget {
  final Map<String, dynamic> item;
  final List<String> columns;
  final String searchQuery;
  final String Function(String) keyFormatter;

  const _ItemRow({
    required this.item,
    required this.columns,
    this.searchQuery = '',
    this.keyFormatter = formatKey,
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

  bool get _hasSearchMatch {
    final q = widget.searchQuery;
    if (q.isEmpty) return false;
    final qLower = q.toLowerCase();
    return widget.item.entries.any((e) =>
        widget.keyFormatter(e.key).toLowerCase().contains(qLower) ||
        (e.value?.toString().toLowerCase() ?? '').contains(qLower));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final sp = context.watch<UiScaleProvider>();

    final match = _hasSearchMatch;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Main row
        Container(
          color: match ? colorScheme.secondaryContainer.withAlpha(50) : null,
          child: InkWell(
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
                          size: sp.sz(16),
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
              keyFormatter: widget.keyFormatter,
            ),
          ),
      ],
    );
  }

  Widget _buildCell(BuildContext context, dynamic value) {
    final str = _formatCell(value);
    final q = widget.searchQuery;
    return HighlightText(
      text:     str,
      query:    q,
      style:    Theme.of(context).textTheme.bodyMedium,
      overflow: TextOverflow.ellipsis,
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
  final String Function(String) keyFormatter;

  const _SubItemsView({required this.subItems, required this.keyFormatter});

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
                              keyFormatter(e.key),
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

