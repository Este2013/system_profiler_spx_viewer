import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/spx_section.dart';
import '../../providers/ui_scale_provider.dart';
import '../../utils/key_formatter.dart';
import '../resizable_split.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Label overrides
// ─────────────────────────────────────────────────────────────────────────────

/// Maps raw plist keys → human-readable labels.
/// Handles both prefixed (spnetworkvolume_*) and un-prefixed variants.
const _kLabels = <String, String>{
  '_name':                          'Name',
  // type / filesystem type  (actual SPX key: spnetworkvolume_fstypename)
  'spnetworkvolume_fstypename':     'Type',
  'spnetworkvolume_type':           'Type',
  'type':                           'Type',
  'protocol':                       'Type',
  'fstypename':                     'Type',
  // mount point  (actual SPX key: spnetworkvolume_fsmtnonname)
  'spnetworkvolume_fsmtnonname':    'Mount Point',
  'spnetworkvolume_mountpoint':     'Mount Point',
  'spnetworkvolume_mount_point':    'Mount Point',
  'mount_point':                    'Mount Point',
  'mountpoint':                     'Mount Point',
  'fsmtnonname':                    'Mount Point',
  'mntonname':                      'Mount Point',
  // mounted-from / URL / server  (actual SPX key: spnetworkvolume_mntfromname)
  'spnetworkvolume_mntfromname':    'Mounted From',
  'spnetworkvolume_url':            'Mounted From',
  'spnetworkvolume_remote_url':     'Mounted From',
  'spnetworkvolume_server':         'Mounted From',
  'url':                            'Mounted From',
  'remote_url':                     'Mounted From',
  'server':                         'Mounted From',
  'mntfromname':                    'Mounted From',
  // automounted
  'spnetworkvolume_automounted':    'Automounted',
  'automounted':                    'Automounted',
  // optional extras
  'spnetworkvolume_mounted_by_uid': 'Mounted by UID',
  'mounted_by_uid':                 'Mounted by UID',
  'spnetworkvolume_flags':          'Flags',
  'flags':                          'Flags',
};

String _label(String key) {
  if (_kLabels.containsKey(key)) return _kLabels[key]!;
  if (key.startsWith('spnetworkvolume_')) {
    return formatKey(key.substring('spnetworkvolume_'.length));
  }
  return formatKey(key);
}

// ── Column definitions ────────────────────────────────────────────────────────
/// Each column: a fixed display label + a priority-ordered list of plist keys
/// to try when looking up a value. All 4 columns are always shown.
const _kColName       = <String>['_name'];
const _kColType       = <String>['spnetworkvolume_fstypename',  // actual SPX key
                                  'spnetworkvolume_type', 'fstypename',
                                  'type', 'protocol'];
const _kColMountPoint = <String>['spnetworkvolume_fsmtnonname',  // actual SPX key
                                  'spnetworkvolume_mountpoint',
                                  'spnetworkvolume_mount_point',
                                  'fsmtnonname', 'mntonname',
                                  'mount_point', 'mountpoint'];
const _kColMountedFrom= <String>['spnetworkvolume_mntfromname',  // actual SPX key
                                  'spnetworkvolume_url',
                                  'spnetworkvolume_remote_url',
                                  'spnetworkvolume_server',
                                  'mntfromname',
                                  'url', 'remote_url', 'server'];

/// Preferred detail-panel order: type, mount-point, mounted-from, then extras.
const _kDetailOrder = <String>[
  ..._kColType,
  ..._kColMountPoint,
  ..._kColMountedFrom,
  'spnetworkvolume_automounted', 'automounted',
  'spnetworkvolume_mounted_by_uid', 'mounted_by_uid',
  'spnetworkvolume_flags', 'flags',
];

/// Alias groups used to de-duplicate the detail panel.
const _kAliasGroups = [
  _kColName,
  _kColType,        // includes fstypename
  _kColMountPoint,  // includes fsmtnonname / mntonname
  _kColMountedFrom, // includes mntfromname
  <String>['spnetworkvolume_automounted', 'automounted'],
  <String>['spnetworkvolume_mounted_by_uid', 'mounted_by_uid'],
  <String>['spnetworkvolume_flags', 'flags'],
];


// ─────────────────────────────────────────────────────────────────────────────
// Value formatters
// ─────────────────────────────────────────────────────────────────────────────

String _fmtVal(dynamic v) {
  if (v == null) return '—';
  if (v is bool) return v ? 'Yes' : 'No';
  if (v is List) {
    if (v.isEmpty) return '—';
    if (v.every((e) => e is! Map && e is! List)) return v.join(', ');
    return '${v.length} items';
  }
  if (v is Map) return '{…}';
  if (v is String) {
    if (v.toLowerCase() == 'yes') return 'Yes';
    if (v.toLowerCase() == 'no') return 'No';
    final t = formatSpxValue(v);
    return t.isEmpty ? '—' : t;
  }
  return v.toString();
}


// ─────────────────────────────────────────────────────────────────────────────
// Public widget
// ─────────────────────────────────────────────────────────────────────────────

class NetworkVolumesView extends StatefulWidget {
  final SpxSection section;
  final String searchQuery;

  const NetworkVolumesView({
    super.key,
    required this.section,
    this.searchQuery = '',
  });

  @override
  State<NetworkVolumesView> createState() => _NetworkVolumesViewState();
}

class _NetworkVolumesViewState extends State<NetworkVolumesView> {
  final _filterCtrl = TextEditingController();
  String _filter = '';
  String? _sortColumnKey;   // the actual resolved plist key being sorted
  bool   _sortAscending = true;
  Map<String, dynamic>? _selectedItem;

  String get _q => _filter.isNotEmpty ? _filter : widget.searchQuery;

  @override
  void dispose() {
    _filterCtrl.dispose();
    super.dispose();
  }

  // ── Column resolution ─────────────────────────────────────────────────────

  /// Builds the 4 logical columns by scanning the actual keys present in the
  /// data, using [_label] as a reverse-lookup fallback so any key naming
  /// convention is handled automatically.
  ///
  /// Always returns all 4 columns; [key] is null when nothing matches
  /// (cell will show "—").
  List<({String label, String? key})> _buildColumns() {
    // Union of all keys that actually exist across every item.
    final allKeys = <String>{};
    for (final item in widget.section.items) {
      allKeys.addAll(item.keys);
    }
    // Also pull in any keys registered in the plist column-order metadata.
    allKeys.addAll(widget.section.columnKeys);

    String? best(String targetLabel, List<String> candidates) {
      // Pass 1 – try explicit candidate key names in priority order.
      for (final k in candidates) {
        if (allKeys.contains(k)) return k;
      }
      // Pass 2 – scan every real key and match by its human label.
      for (final k in allKeys) {
        if (_label(k) == targetLabel) return k;
      }
      return null;
    }

    return [
      (label: 'Name',         key: best('Name',         _kColName)),
      (label: 'Type',         key: best('Type',         _kColType)),
      (label: 'Mount Point',  key: best('Mount Point',  _kColMountPoint)),
      (label: 'Mounted From', key: best('Mounted From', _kColMountedFrom)),
    ];
  }

  // ── Filtering & sorting ───────────────────────────────────────────────────

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
    if (_sortColumnKey != null) {
      items.sort((a, b) {
        final av = _fmtVal(a[_sortColumnKey]).toLowerCase();
        final bv = _fmtVal(b[_sortColumnKey]).toLowerCase();
        final cmp = av.compareTo(bv);
        return _sortAscending ? cmp : -cmp;
      });
    }
    return items;
  }

  void _toggleSort(String? key) {
    if (key == null) return;
    setState(() {
      if (_sortColumnKey == key) {
        _sortAscending = !_sortAscending;
      } else {
        _sortColumnKey = key;
        _sortAscending = true;
      }
    });
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final sp    = context.watch<UiScaleProvider>();
    final theme = Theme.of(context);
    final cs    = theme.colorScheme;

    final columns = _buildColumns();
    final rows    = _rows;
    final total   = widget.section.items.length;

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
            separatorBuilder: (context, index) => Divider(
              height: 1,
              color: cs.outlineVariant.withAlpha(60),
            ),
            itemBuilder: (context, i) {
              final item     = rows[i];
              final selected = _selectedItem == item;
              return _TableRow(
                item:        item,
                columns:     columns,
                searchQuery: _q,
                selected:    selected,
                onTap: () => setState(() {
                  _selectedItem = selected ? null : item;
                }),
                theme: theme,
                cs:    cs,
                sp:    sp,
              );
            },
          );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Filter bar ────────────────────────────────────────────────────
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
              Text(
                '${rows.length} / $total',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: cs.onSurfaceVariant),
              ),
            ],
          ),
        ),

        // ── Column headers ────────────────────────────────────────────────
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
                    onTap: () => _toggleSort(col.key),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 9),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              col.label,
                              style: theme.textTheme.labelMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: _sortColumnKey == col.key
                                    ? cs.primary
                                    : cs.onSurfaceVariant,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (_sortColumnKey == col.key && col.key != null)
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

        // ── Table rows + (optional) resizable detail panel ───────────────
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
                    item:    _selectedItem!,
                    cs:      cs,
                    theme:   theme,
                    sp:      sp,
                    onClose: () => setState(() => _selectedItem = null),
                  ),
                  Expanded(
                    child: _DetailPanel(
                      item:  _selectedItem!,
                      sp:    sp,
                      theme: theme,
                      cs:    cs,
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
  final List<({String label, String? key})> columns;
  final String searchQuery;
  final bool selected;
  final VoidCallback onTap;
  final ThemeData theme;
  final ColorScheme cs;
  final UiScaleProvider sp;

  const _TableRow({
    required this.item,
    required this.columns,
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
                      text:     _fmtVal(col.key != null ? item[col.key] : null),
                      query:    searchQuery,
                      selected: selected,
                      theme:    theme,
                      cs:       cs,
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
    if (query.isEmpty || !text.toLowerCase().contains(query.toLowerCase())) {
      return Text(text, overflow: TextOverflow.ellipsis, style: baseStyle);
    }
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
          color:           cs.onTertiaryContainer,
          fontWeight:      FontWeight.bold,
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
          top:    BorderSide(color: cs.outlineVariant, width: 0.5),
          bottom: BorderSide(color: cs.outlineVariant, width: 0.5),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(16, 6, 8, 6),
      child: Row(
        children: [
          Icon(Icons.folder_shared_outlined,
              size: sp.sz(15), color: cs.onSurfaceVariant),
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
// Detail panel
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

  static const double _keyW = 200.0;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
      children: _buildRows(),
    );
  }

  List<Widget> _buildRows() {
    final widgets = <Widget>[];
    final keyW    = sp.sz(_keyW);
    final seen    = <String>{};

    void addKv(String key, dynamic value, {double indent = 0}) {
      if (isInternalKey(key) || key == '_name') return;
      if (value is Map) return;
      widgets.add(_DetailRow(
        label:    _label(key),
        value:    _fmtVal(value),
        indent:   indent,
        keyWidth: (keyW - indent).clamp(80.0, double.infinity),
        theme:    theme,
        cs:       cs,
      ));
    }

    // 1. Preferred-order keys (de-duplicated across alias groups).
    for (final key in _kDetailOrder) {
      if (!item.containsKey(key)) continue;
      if (seen.contains(key)) continue;
      // Mark the entire alias group as seen so we never show duplicates.
      for (final group in _kAliasGroups) {
        if (group.contains(key)) {
          seen.addAll(group);
          break;
        }
      }
      seen.add(key);
      addKv(key, item[key]);
    }

    // 2. Any remaining keys not yet shown.
    for (final e in item.entries) {
      if (seen.contains(e.key)) continue;
      if (isInternalKey(e.key) || e.key == '_name') continue;
      seen.add(e.key);
      if (e.value is Map) {
        // sub-dict: show as indented block
        widgets.add(_SubHeader(
          label:  _label(e.key),
          indent: 0,
          theme:  theme,
          cs:     cs,
        ));
        for (final sub in (e.value as Map).entries) {
          final subKey = sub.key.toString();
          if (isInternalKey(subKey) || subKey == '_name') continue;
          addKv(subKey, sub.value, indent: sp.sz(20));
        }
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
                color:      cs.onSurfaceVariant,
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
          color:      cs.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
