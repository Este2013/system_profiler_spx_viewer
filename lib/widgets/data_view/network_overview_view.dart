import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/spx_section.dart';
import '../../providers/ui_scale_provider.dart';
import '../../utils/key_formatter.dart';
import '../resizable_split.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Label helpers
// ─────────────────────────────────────────────────────────────────────────────

/// Explicit overrides for known coded keys.
const _kLabels = <String, String>{
  // Interface top-level fields
  'spnetwork_interface_type':        'Type',
  'spnetwork_interface_hardware':    'Hardware',
  'spnetwork_interface_bsdDevice':   'BSD Device Name',
  'spnetwork_interface_bsd_device':  'BSD Device Name',
  'bsd_device_name':                 'BSD Device Name',
  'spnetwork_interface_addresses':   'IPv4 Addresses',
  'spnetwork_interface_order':       'Service Order',
  'service_order':                   'Service Order',
  // IPv4 sub-keys
  'Configuration Method':            'Configuration Method',
  'Addresses':                       'Addresses',
  'Router':                          'Router',
  'Subnet Masks':                    'Subnet Masks',
  'Interface Name':                  'Interface Name',
  'Confirmed Interface Name':        'Confirmed Interface Name',
  'Network Signature':               'Network Signature',
  'ARP Resolved Hardware Address':   'ARP Resolved Hardware Address',
  'ARP Resolved IP Address':         'ARP Resolved IP Address',
  // Additional Routes sub-keys
  'Destination Address':             'Destination Address',
  'Subnet Mask':                     'Subnet Mask',
  // DNS sub-keys
  'Domain Name':                     'Domain Name',
  'Server Addresses':                'Server Addresses',
  // DHCP sub-keys
  'Domain Name Servers':             'Domain Name Servers',
  'Lease Duration (seconds)':        'Lease Duration (seconds)',
  'DHCP Message Type':               'DHCP Message Type',
  'Routers':                         'Routers',
  'Server Identifier':               'Server Identifier',
  // Ethernet sub-keys
  'MAC Address':                     'MAC Address',
  'Media Options':                   'Media Options',
  'Media Subtype':                   'Media Subtype',
  // Proxies sub-keys
  'Exceptions List':                 'Exceptions List',
  'FTP Passive Mode':                'FTP Passive Mode',
};

/// Human-readable label for a network key.
/// Keys that look already-formatted (capital-start, no underscores, may have
/// spaces – e.g. "IPv4", "DNS", "DHCP Server Responses") are returned as-is.
String _netLabel(String key) {
  if (_kLabels.containsKey(key)) return _kLabels[key]!;
  // Already-formatted: starts with uppercase, contains no underscores (or has spaces).
  if (key.isNotEmpty &&
      key[0] == key[0].toUpperCase() &&
      (!key.contains('_') || key.contains(' '))) {
    return key;
  }
  // Strip spnetwork_ prefix.
  if (key.startsWith('spnetwork_')) {
    return formatKey(key.substring('spnetwork_'.length));
  }
  return formatKey(key);
}

// ─────────────────────────────────────────────────────────────────────────────
// Value helpers
// ─────────────────────────────────────────────────────────────────────────────

String _fmtScalar(dynamic v) {
  if (v == null) return '—';
  if (v is bool) return v ? 'Yes' : 'No';
  if (v is DateTime) {
    return DateFormat('yyyy-MM-dd  HH:mm:ss').format(v.toLocal());
  }
  if (v is List) {
    if (v.isEmpty) return '—';
    if (v.every((e) => e is! Map && e is! List)) {
      return v.join(', ');
    }
    return '${v.length} item${v.length == 1 ? '' : 's'}';
  }
  if (v is Map) return '{${v.length} fields}';
  if (v is String) {
    final f = formatSpxValue(v);
    return f.isEmpty ? '—' : f;
  }
  return v.toString();
}

/// Returns true when a value should be rendered as a sub-section header
/// rather than a plain KV cell.
bool _isNested(dynamic v) =>
    v is Map || (v is List && v.any((e) => e is Map));

// ─────────────────────────────────────────────────────────────────────────────
// Column selection
// ─────────────────────────────────────────────────────────────────────────────

/// Preferred column key order for the interface table.
const _kColumnOrder = [
  '_name',
  'spnetwork_interface_type',        'type',     'Type',
  'spnetwork_interface_hardware',    'hardware', 'Hardware',
  'spnetwork_interface_bsdDevice',   'spnetwork_interface_bsd_device',
  'bsd_device_name',                 'BSD Device Name',
  'spnetwork_interface_addresses',   'IPv4 Addresses',
  'spnetwork_interface_order',       'service_order', 'Service Order',
];
const _kMaxColumns = 6;

List<String> _buildColumns(List<Map<String, dynamic>> items) {
  final allKeys = <String>{};
  for (final item in items) {
    allKeys.addAll(item.keys);
  }

  final cols = <String>[];

  // Preferred order first.
  for (final k in _kColumnOrder) {
    if (allKeys.contains(k) && !cols.contains(k)) {
      // Only include columns that have at least one scalar value.
      if (items.any((item) {
        final v = item[k];
        return v != null && !_isNested(v);
      })) {
        cols.add(k);
      }
    }
  }

  // Append any remaining scalar columns not in the preferred list.
  for (final k in allKeys) {
    if (cols.contains(k)) continue;
    if (k.startsWith('_') && k != '_name') continue;
    if (items.any((item) {
      final v = item[k];
      return v != null && !_isNested(v);
    })) {
      cols.add(k);
    }
  }

  return cols.take(_kMaxColumns).toList();
}

// ─────────────────────────────────────────────────────────────────────────────
// Detail display order
// ─────────────────────────────────────────────────────────────────────────────

const _kDetailOrder = [
  'spnetwork_interface_type',      'type',     'Type',
  'spnetwork_interface_hardware',  'hardware', 'Hardware',
  'spnetwork_interface_bsdDevice', 'spnetwork_interface_bsd_device',
  'bsd_device_name',               'BSD Device Name',
  'spnetwork_interface_addresses', 'IPv4 Addresses',
  'IPv4',  'spnetwork_ipv4',
  'IPv6',  'spnetwork_ipv6',
  'DNS',   'spnetwork_dns',
  'DHCP Server Responses',
  'Ethernet',
  'Proxies',
  'spnetwork_interface_order', 'service_order', 'Service Order',
];

// ─────────────────────────────────────────────────────────────────────────────
// Public widget
// ─────────────────────────────────────────────────────────────────────────────

/// Renders [SPNetworkDataType] as a filterable interface table with a
/// row-selection detail pane.
///
/// The table only shows scalar columns (Map-valued columns like IPv4 / IPv6
/// are excluded).  Selecting a row opens a detail pane that recursively
/// renders the full interface data including nested sub-sections.
class NetworkOverviewView extends StatefulWidget {
  final SpxSection section;
  final String searchQuery;

  const NetworkOverviewView({
    super.key,
    required this.section,
    this.searchQuery = '',
  });

  @override
  State<NetworkOverviewView> createState() => _NetworkOverviewViewState();
}

class _NetworkOverviewViewState extends State<NetworkOverviewView> {
  final _filterCtrl = TextEditingController();
  String _filter = '';
  String? _sortColumn;
  bool _sortAscending = true;
  Map<String, dynamic>? _selectedItem;

  @override
  void dispose() {
    _filterCtrl.dispose();
    super.dispose();
  }

  String get _q => _filter.isNotEmpty ? _filter : widget.searchQuery;

  // ── Filtering & sorting ────────────────────────────────────────────────────

  List<Map<String, dynamic>> get _rows {
    var items = widget.section.items.toList();
    final q = _q;
    if (q.isNotEmpty) {
      final lower = q.toLowerCase();
      items = items.where((item) {
        return item.entries.any((e) {
          if (_isNested(e.value)) return false;
          return e.value.toString().toLowerCase().contains(lower) ||
              _netLabel(e.key).toLowerCase().contains(lower);
        });
      }).toList();
    }
    if (_sortColumn != null) {
      items.sort((a, b) {
        final av = a[_sortColumn];
        final bv = b[_sortColumn];
        if (av is num && bv is num) {
          return _sortAscending ? av.compareTo(bv) : bv.compareTo(av);
        }
        final cmp = (av?.toString() ?? '')
            .toLowerCase()
            .compareTo((bv?.toString() ?? '').toLowerCase());
        return _sortAscending ? cmp : -cmp;
      });
    }
    return items;
  }

  void _toggleSort(String col) => setState(() {
        if (_sortColumn == col) {
          _sortAscending = !_sortAscending;
        } else {
          _sortColumn = col;
          _sortAscending = true;
        }
      });

  String _cellVal(String col, dynamic v) {
    if (v == null) return '—';
    if (_isNested(v)) return '…';
    return _fmtScalar(v);
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final sp = context.watch<UiScaleProvider>();
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final columns = _buildColumns(widget.section.items);
    final rows = _rows;
    final total = widget.section.items.length;

    final tableContent = rows.isEmpty
        ? Center(
            child: Text('No matching interfaces',
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: cs.onSurfaceVariant)),
          )
        : ListView.separated(
            itemCount: rows.length,
            separatorBuilder: (_, _) =>
                Divider(height: 1, color: cs.outlineVariant.withAlpha(60)),
            itemBuilder: (context, i) {
              final item = rows[i];
              final selected = _selectedItem == item;
              return _TableRow(
                item: item,
                columns: columns,
                cellVal: _cellVal,
                searchQuery: _q,
                selected: selected,
                onTap: () => setState(() {
                  _selectedItem = selected ? null : item;
                }),
                theme: theme,
                cs: cs,
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
                    hintText: 'Filter $total interfaces…',
                    prefixIcon: Icon(Icons.search, size: sp.sz(18)),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: cs.outlineVariant),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
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
              Text('${rows.length} / $total',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: cs.onSurfaceVariant)),
            ],
          ),
        ),

        // ── Column headers ──────────────────────────────────────────────────
        Container(
          decoration: BoxDecoration(
            color: cs.surfaceContainerLow,
            border: Border(
                bottom: BorderSide(color: cs.outlineVariant, width: 0.5)),
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
                              _netLabel(col),
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
                  _DetailBar(
                    item: _selectedItem!, cs: cs, theme: theme, sp: sp,
                    onClose: () => setState(() => _selectedItem = null),
                  ),
                  Expanded(
                    child: _DetailPanel(
                      item: _selectedItem!, theme: theme, cs: cs, sp: sp,
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

  const _TableRow({
    required this.item,
    required this.columns,
    required this.cellVal,
    required this.searchQuery,
    required this.selected,
    required this.onTap,
    required this.theme,
    required this.cs,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? cs.primaryContainer : Colors.transparent,
      child: InkWell(
        onTap: onTap,
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
    if (start < text.length) spans.add(TextSpan(text: text.substring(start)));
    return RichText(
      overflow: TextOverflow.ellipsis,
      text: TextSpan(style: baseStyle, children: spans),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Detail panel title bar
// ─────────────────────────────────────────────────────────────────────────────

class _DetailBar extends StatelessWidget {
  final Map<String, dynamic> item;
  final ColorScheme cs;
  final ThemeData theme;
  final UiScaleProvider sp;
  final VoidCallback onClose;

  const _DetailBar({
    required this.item,
    required this.cs,
    required this.theme,
    required this.sp,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final name = item['_name']?.toString() ?? 'Interface';
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
          Icon(Icons.router_outlined, size: sp.sz(15),
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
// Detail panel — recursively renders the full interface data
// ─────────────────────────────────────────────────────────────────────────────

class _DetailPanel extends StatelessWidget {
  final Map<String, dynamic> item;
  final ThemeData theme;
  final ColorScheme cs;
  final UiScaleProvider sp;

  const _DetailPanel({
    required this.item,
    required this.theme,
    required this.cs,
    required this.sp,
  });

  static const double _keyBase = 260.0;
  static const double _indentStep = 20.0;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: _buildSection(item, 0),
    );
  }

  /// Recursively builds widgets for a map at a given indent depth.
  List<Widget> _buildSection(Map<String, dynamic> map, int depth) {
    final widgets = <Widget>[];
    final indent = depth * _indentStep;
    final keyW = (_keyBase - indent).clamp(80.0, _keyBase);
    final seen = <String>{};

    // 1. Preferred order for the top-level (depth 0) fields.
    if (depth == 0) {
      for (final key in _kDetailOrder) {
        if (!map.containsKey(key)) continue;
        if (seen.contains(key)) continue;
        seen.add(key);
        _addEntry(key, map[key], depth, indent, keyW, widgets);
      }
    }

    // 2. Remaining entries (respects insertion order for nested maps).
    for (final e in map.entries) {
      if (seen.contains(e.key)) continue;
      if (isInternalKey(e.key) || e.key == '_name') continue;
      seen.add(e.key);
      _addEntry(e.key, e.value, depth, indent, keyW, widgets);
    }

    return widgets;
  }

  void _addEntry(
    String key,
    dynamic value,
    int depth,
    double indent,
    double keyW,
    List<Widget> widgets,
  ) {
    if (value is Map) {
      // ── Map sub-section ──────────────────────────────────────────────────
      widgets.add(_SectionHeader(
        label: _netLabel(key),
        indent: indent,
        depth: depth,
        theme: theme,
        cs: cs,
      ));
      widgets.addAll(_buildSection(
          value.cast<String, dynamic>(), depth + 1));

    } else if (value is List && value.any((e) => e is Map)) {
      // ── List-of-maps sub-section (e.g. "Additional Routes") ─────────────
      // Render the header once, then output each map's KV pairs sequentially
      // (matching the macOS flat list style — no sub-numbering).
      widgets.add(_SectionHeader(
        label: _netLabel(key),
        indent: indent,
        depth: depth,
        theme: theme,
        cs: cs,
      ));
      final nextIndent = (depth + 1) * _indentStep;
      final nextKeyW = (_keyBase - nextIndent).clamp(80.0, _keyBase);
      for (final entry in value) {
        if (entry is Map) {
          for (final e in entry.entries.where(
              (e) => !isInternalKey(e.key) && e.key != '_name')) {
            if (_isNested(e.value)) continue; // skip deeply nested
            widgets.add(_KvRow(
              label: _netLabel(e.key),
              value: _fmtScalar(e.value),
              indent: nextIndent,
              keyWidth: nextKeyW,
              theme: theme,
              cs: cs,
            ));
          }
        } else {
          widgets.add(_KvRow(
            label: '',
            value: _fmtScalar(entry),
            indent: nextIndent,
            keyWidth: nextKeyW,
            theme: theme,
            cs: cs,
          ));
        }
      }

    } else {
      // ── Scalar KV row ────────────────────────────────────────────────────
      widgets.add(_KvRow(
        label: _netLabel(key),
        value: _fmtScalar(value),
        indent: indent,
        keyWidth: keyW,
        theme: theme,
        cs: cs,
      ));
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sub-section header
// ─────────────────────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String label;
  final double indent;
  final int depth;
  final ThemeData theme;
  final ColorScheme cs;

  const _SectionHeader({
    required this.label,
    required this.indent,
    required this.depth,
    required this.theme,
    required this.cs,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: indent, top: depth == 0 ? 8 : 6,
          bottom: 3),
      child: Text(
        label,
        style: (depth == 0
                ? theme.textTheme.titleSmall
                : theme.textTheme.bodyMedium)
            ?.copyWith(
          color: cs.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Key-value row
// ─────────────────────────────────────────────────────────────────────────────

class _KvRow extends StatelessWidget {
  final String label;
  final String value;
  final double indent;
  final double keyWidth;
  final ThemeData theme;
  final ColorScheme cs;

  const _KvRow({
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
            child: label.isEmpty
                ? null
                : Text(
                    label,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: cs.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
          ),
          if (label.isNotEmpty) const SizedBox(width: 16),
          Expanded(
            child: SelectableText(
              value,
              style: theme.textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}
