import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/spx_section.dart';
import '../../providers/ui_scale_provider.dart';
import '../../utils/key_formatter.dart';
import '../resizable_split.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Human-readable labels for storage keys
// ─────────────────────────────────────────────────────────────────────────────

const _kLabels = <String, String>{
  '_name':                'Name',
  'bsd_name':             'BSD Name',
  'file_system':          'File System',
  'free_space_in_bytes':  'Free',
  'size_in_bytes':        'Capacity',
  '_capacity':            'Capacity',
  'mount_point':          'Mount Point',
  'writable':             'Writable',
  'ignore_ownership':     'Ignore Ownership',
  'volume_uuid':          'Volume UUID',
  'physical_drive':       'Physical Drive',
  // physical_drive sub-keys
  'device_name':          'Device Name',
  'media_name':           'Media Name',
  'medium_type':          'Medium Type',
  'protocol':             'Protocol',
  'internal':             'Internal',
  'partition_map_type':   'Partition Map Type',
  'smart_status':         'SMART Status',
};

String _label(String key) => _kLabels[key] ?? formatKey(key);

// ── Preferred order for the detail panel ─────────────────────────────────────
const _kDetailOrder = [
  'free_space_in_bytes',
  'size_in_bytes', '_capacity',
  'mount_point',
  'file_system',
  'writable',
  'ignore_ownership',
  'bsd_name',
  'volume_uuid',
  'physical_drive',
];

// ── Preferred column order for the table ─────────────────────────────────────
const _kColumnOrder = [
  '_name',
  'bsd_name',
  'file_system',
  'free_space_in_bytes',
  'size_in_bytes',
  '_capacity',
  'mount_point',
];
const _kMaxTableColumns = 6;

// ─────────────────────────────────────────────────────────────────────────────
// Byte helpers
// ─────────────────────────────────────────────────────────────────────────────

/// Returns true for keys whose values represent a byte count.
bool _isByteKey(String key) =>
    key.endsWith('_in_bytes') || key == '_capacity';

final _commaFmt = NumberFormat('#,###');

/// Formats a byte count into the best matching unit with 2 decimal places.
String _fmtBytes(dynamic v) {
  if (v == null) return '—';
  final raw = v is num ? v.toDouble() : double.tryParse(v.toString());
  if (raw == null) return v.toString();
  const kb = 1024.0;
  const mb = kb * 1024;
  const gb = mb * 1024;
  const tb = gb * 1024;
  if (raw >= tb) return '${(raw / tb).toStringAsFixed(2)} TB';
  if (raw >= gb) return '${(raw / gb).toStringAsFixed(2)} GB';
  if (raw >= mb) return '${(raw / mb).toStringAsFixed(2)} MB';
  if (raw >= kb) return '${(raw / kb).toStringAsFixed(2)} KB';
  return '${raw.toStringAsFixed(0)} B';
}

/// Detail-panel format: "92.16 GB (92,158,513,152 bytes)" for byte keys.
String _fmtBytesDetailed(dynamic v) {
  if (v == null) return '—';
  final raw = v is num ? v.toDouble() : double.tryParse(v.toString());
  if (raw == null) return v.toString();
  final formatted = _fmtBytes(raw);
  final rawInt = raw.truncate();
  return '$formatted (${_commaFmt.format(rawInt)} bytes)';
}

// ─────────────────────────────────────────────────────────────────────────────
// General value formatter (for detail panel scalar values)
// ─────────────────────────────────────────────────────────────────────────────

String _fmtVal(String key, dynamic v) {
  if (v == null) return '—';
  if (_isByteKey(key)) return _fmtBytesDetailed(v);
  if (v is bool) return v ? 'Yes' : 'No';
  if (v is DateTime) {
    return DateFormat('yyyy-MM-dd  HH:mm:ss').format(v.toLocal());
  }
  if (v is List) {
    if (v.every((e) => e is! Map && e is! List)) return v.join(', ');
    return '${v.length} item${v.length == 1 ? '' : 's'}';
  }
  if (v is Map) return '{${v.length} fields}';
  if (v is String) {
    final f = formatSpxValue(v);
    return f.isEmpty ? '—' : f;
  }
  return v.toString();
}

// ─────────────────────────────────────────────────────────────────────────────
// Public widget
// ─────────────────────────────────────────────────────────────────────────────

class StorageView extends StatefulWidget {
  final SpxSection section;
  final String searchQuery;

  const StorageView({
    super.key,
    required this.section,
    this.searchQuery = '',
  });

  @override
  State<StorageView> createState() => _StorageViewState();
}

class _StorageViewState extends State<StorageView> {
  final _filterCtrl = TextEditingController();
  String _filter = '';
  String? _sortColumn;
  bool _sortAscending = true;
  Map<String, dynamic>? _selectedItem;

  String get _q => _filter;

  String get _highlightQuery =>
      _filter.isNotEmpty ? _filter : widget.searchQuery;

  bool _isNameMatch(String q) =>
      q.isNotEmpty &&
      widget.section.displayName.toLowerCase().contains(q.toLowerCase());

  void _syncLocalFilter(String q) {
    _filter = _isNameMatch(q) ? '' : q;
    _filterCtrl.text = _filter;
  }

  @override
  void initState() {
    super.initState();
    _syncLocalFilter(widget.searchQuery);
  }

  @override
  void didUpdateWidget(covariant StorageView old) {
    super.didUpdateWidget(old);
    if (old.searchQuery != widget.searchQuery) {
      setState(() => _syncLocalFilter(widget.searchQuery));
    }
  }

  @override
  void dispose() {
    _filterCtrl.dispose();
    super.dispose();
  }

  // ── Column selection ───────────────────────────────────────────────────────

  List<String> get _displayColumns {
    final allKeys = <String>{};
    for (final item in widget.section.items) {
      allKeys.addAll(item.keys);
    }
    // Start with preferred order, then append any remaining useful keys.
    final cols = <String>[];
    for (final k in _kColumnOrder) {
      if (allKeys.contains(k)) cols.add(k);
    }
    for (final k in allKeys) {
      if (!cols.contains(k) && !k.startsWith('_') && k != 'physical_drive') {
        cols.add(k);
      }
    }
    return cols.take(_kMaxTableColumns).toList();
  }

  // ── Filtering & sorting ────────────────────────────────────────────────────

  List<Map<String, dynamic>> get _rows {
    var items = widget.section.items.toList();
    final q = _q;
    if (q.isNotEmpty) {
      final lower = q.toLowerCase();
      items = items.where((item) {
        return item.entries.any((e) {
          if (e.value is Map || e.value is List) return false;
          return e.value.toString().toLowerCase().contains(lower) ||
              _label(e.key).toLowerCase().contains(lower);
        });
      }).toList();
    }
    if (_sortColumn != null) {
      items.sort((a, b) {
        final av = a[_sortColumn];
        final bv = b[_sortColumn];
        if (av is num && bv is num) {
          return _sortAscending
              ? av.compareTo(bv)
              : bv.compareTo(av);
        }
        final cmp = (av?.toString() ?? '')
            .toLowerCase()
            .compareTo((bv?.toString() ?? '').toLowerCase());
        return _sortAscending ? cmp : -cmp;
      });
    }
    return items;
  }

  void _toggleSort(String col) {
    setState(() {
      if (_sortColumn == col) {
        _sortAscending = !_sortAscending;
      } else {
        _sortColumn = col;
        _sortAscending = true;
      }
    });
  }

  // ── Format a table cell value ──────────────────────────────────────────────

  String _cellVal(String col, dynamic v) {
    if (v == null) return '—';
    if (_isByteKey(col)) return _fmtBytes(v);
    if (v is bool) return v ? 'Yes' : 'No';
    if (v is List) {
      if (v.every((e) => e is! Map && e is! List)) return v.join(', ');
      return '[${v.length}]';
    }
    if (v is Map) return '…';
    if (v is String) {
      final f = formatSpxValue(v);
      return f.isEmpty ? '—' : f;
    }
    return v.toString();
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final sp = context.watch<UiScaleProvider>();
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final columns = _displayColumns;
    final rows = _rows;
    final total = widget.section.items.length;

    final tableContent = rows.isEmpty
        ? Center(
            child: Text(
              'No matching volumes',
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: cs.onSurfaceVariant),
            ),
          )
        : ListView.separated(
            itemCount: rows.length,
            separatorBuilder: (_, _) => Divider(
              height: 1,
              color: cs.outlineVariant.withAlpha(60),
            ),
            itemBuilder: (context, i) {
              final item = rows[i];
              final selected = _selectedItem == item;
              return _TableRow(
                item: item,
                columns: columns,
                cellVal: _cellVal,
                searchQuery: _highlightQuery,
                selected: selected,
                onTap: () => setState(() {
                  _selectedItem = selected ? null : item;
                }),
                theme: theme,
                cs: cs,
                sp: sp,
              );
            },
          );

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
                  controller: _filterCtrl,
                  decoration: InputDecoration(
                    isDense: true,
                    hintText: 'Filter $total volumes…',
                    prefixIcon: Icon(Icons.search, size: sp.sz(18)),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: cs.outlineVariant),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
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
              const SizedBox(width: 12),
              Text(
                '${rows.length} / $total',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: cs.onSurfaceVariant),
              ),
            ],
          ),
        ),

        // ── Column headers ──────────────────────────────────────────────────
        Container(
          decoration: BoxDecoration(
            color: cs.surfaceContainerLow,
            border: Border(
              bottom: BorderSide(color: cs.outlineVariant, width: 0.5),
            ),
          ),
          child: Row(
            children: [
              for (final col in columns)
                Expanded(
                  child: InkWell(
                    onTap: () => _toggleSort(col),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 9),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              _label(col),
                              style: theme.textTheme.labelMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: _sortColumn == col
                                    ? cs.primary
                                    : cs.onSurfaceVariant,
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
                              color: cs.primary,
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),

        // ── Table rows + (optional) resizable detail panel ──────────────────
        if (_selectedItem == null) ...[
          Expanded(child: tableContent),
        ] else ...[
          Expanded(
            child: ResizableHSplit(
              top: tableContent,
              bottom: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _DetailDivider(
                    item: _selectedItem!, cs: cs, theme: theme, sp: sp,
                    onClose: () => setState(() => _selectedItem = null),
                  ),
                  Expanded(
                    child: _DetailPanel(
                      item: _selectedItem!, sp: sp, theme: theme, cs: cs,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Table row
// ─────────────────────────────────────────────────────────────────────────────

class _TableRow extends StatelessWidget {
  final Map<String, dynamic> item;
  final List<String> columns;
  final String Function(String, dynamic) cellVal;
  final String searchQuery;
  final bool selected;
  final VoidCallback onTap;
  final ThemeData theme;
  final ColorScheme cs;
  final UiScaleProvider sp;

  const _TableRow({
    required this.item,
    required this.columns,
    required this.cellVal,
    required this.searchQuery,
    required this.selected,
    required this.onTap,
    required this.theme,
    required this.cs,
    required this.sp,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? cs.primaryContainer : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 1),
          child: Row(
            children: [
              for (final col in columns)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 7),
                    child: _Cell(
                      text: cellVal(col, item[col]),
                      query: searchQuery,
                      selected: selected,
                      theme: theme,
                      cs: cs,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Table cell with optional search highlight
// ─────────────────────────────────────────────────────────────────────────────

class _Cell extends StatelessWidget {
  final String text;
  final String query;
  final bool selected;
  final ThemeData theme;
  final ColorScheme cs;

  const _Cell({
    required this.text,
    required this.query,
    required this.selected,
    required this.theme,
    required this.cs,
  });

  @override
  Widget build(BuildContext context) {
    final baseStyle = theme.textTheme.bodyMedium?.copyWith(
      color: selected ? cs.onPrimaryContainer : null,
    );
    if (query.isEmpty ||
        !text.toLowerCase().contains(query.toLowerCase())) {
      return Text(text, overflow: TextOverflow.ellipsis, style: baseStyle);
    }
    final lower = text.toLowerCase();
    final q = query.toLowerCase();
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
    return RichText(
      overflow: TextOverflow.ellipsis,
      text: TextSpan(style: baseStyle, children: spans),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Detail-panel divider / title bar
// ─────────────────────────────────────────────────────────────────────────────

class _DetailDivider extends StatelessWidget {
  final Map<String, dynamic> item;
  final ColorScheme cs;
  final ThemeData theme;
  final UiScaleProvider sp;
  final VoidCallback onClose;

  const _DetailDivider({
    required this.item,
    required this.cs,
    required this.theme,
    required this.sp,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final name = item['_name']?.toString() ?? 'Volume';
    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        border: Border(
          top: BorderSide(color: cs.outlineVariant, width: 0.5),
          bottom: BorderSide(color: cs.outlineVariant, width: 0.5),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(16, 6, 8, 6),
      child: Row(
        children: [
          Icon(Icons.storage_outlined, size: sp.sz(15),
              color: cs.onSurfaceVariant),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              name,
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: cs.onSurface,
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.close, size: sp.sz(15)),
            color: cs.onSurfaceVariant,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: onClose,
            tooltip: 'Close details',
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Detail panel — scrollable KV list matching macOS System Information layout
// ─────────────────────────────────────────────────────────────────────────────

class _DetailPanel extends StatelessWidget {
  final Map<String, dynamic> item;
  final UiScaleProvider sp;
  final ThemeData theme;
  final ColorScheme cs;

  const _DetailPanel({
    required this.item,
    required this.sp,
    required this.theme,
    required this.cs,
  });

  static const double _keyW = 220.0;

  @override
  Widget build(BuildContext context) {
    final rows = _buildRows(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
      children: rows,
    );
  }

  List<Widget> _buildRows(BuildContext context) {
    final widgets = <Widget>[];
    final keyW = sp.sz(_keyW);
    final seen = <String>{};

    void addKv(String key, dynamic value, {double indent = 0}) {
      if (isInternalKey(key) || key == '_name') return;
      if (value is Map) return; // handled separately as sub-section
      final labelText = _label(key);
      final valueText = _fmtVal(key, value);
      widgets.add(_DetailRow(
        label: labelText,
        value: valueText,
        indent: indent,
        keyWidth: (keyW - indent).clamp(80.0, double.infinity),
        theme: theme,
        cs: cs,
      ));
    }

    void addSubSection(String key, Map<String, dynamic> sub,
        {double indent = 0}) {
      widgets.add(_SubHeader(
        label: _label(key),
        indent: indent,
        theme: theme,
        cs: cs,
      ));
      for (final e in sub.entries) {
        if (isInternalKey(e.key) || e.key == '_name') continue;
        if (e.value is Map) {
          addSubSection(e.key, (e.value as Map).cast<String, dynamic>(),
              indent: indent + sp.sz(20));
        } else {
          addKv(e.key, e.value, indent: indent + sp.sz(20));
        }
      }
    }

    // 1. Preferred-order keys
    for (final key in _kDetailOrder) {
      if (!item.containsKey(key)) continue;
      seen.add(key);
      final v = item[key];
      if (v is Map) {
        addSubSection(key, v.cast<String, dynamic>());
      } else {
        addKv(key, v);
      }
    }

    // 2. Remaining keys not in preferred order
    for (final e in item.entries) {
      if (seen.contains(e.key)) continue;
      if (isInternalKey(e.key) || e.key == '_name') continue;
      seen.add(e.key);
      if (e.value is Map) {
        addSubSection(e.key, (e.value as Map).cast<String, dynamic>());
      } else {
        addKv(e.key, e.value);
      }
    }

    return widgets;
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final double indent;
  final double keyWidth;
  final ThemeData theme;
  final ColorScheme cs;

  const _DetailRow({
    required this.label,
    required this.value,
    required this.indent,
    required this.keyWidth,
    required this.theme,
    required this.cs,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: indent, top: 4, bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: keyWidth,
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: cs.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: SelectableText(value, style: theme.textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}

class _SubHeader extends StatelessWidget {
  final String label;
  final double indent;
  final ThemeData theme;
  final ColorScheme cs;

  const _SubHeader({
    required this.label,
    required this.indent,
    required this.theme,
    required this.cs,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: indent, top: 10, bottom: 4),
      child: Text(
        label,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: cs.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
