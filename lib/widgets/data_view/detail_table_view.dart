import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/spx_section.dart';
import '../../providers/ui_scale_provider.dart';
import '../../utils/key_formatter.dart';
import '../highlight_text.dart';
import '../resizable_split.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Shared date formatter
// ─────────────────────────────────────────────────────────────────────────────

final _kDateFmt     = DateFormat('dd.MM.yy, HH:mm');
final _kDateCellFmt = DateFormat('dd.MM.yy');

// ─────────────────────────────────────────────────────────────────────────────
// Per-section label maps, detail-panel key order, and value formatters
// ─────────────────────────────────────────────────────────────────────────────

// ── Applications ─────────────────────────────────────────────────────────────

const _kAppLabels = <String, String>{
  '_name':         'Name',
  'version':        'Version',
  'obtained_from':  'Obtained from',
  'lastModified':   'Last Modified',
  'arch_kind':      'Kind',
  'signed_by':      'Signed by',
  'path':           'Location',
};

const _kAppDetailOrder = <String>[
  'version', 'obtained_from', 'lastModified', 'arch_kind', 'signed_by', 'path',
];

String _fmtApp(String key, dynamic v) {
  if (v == null) return '—';
  if (v is bool) return v ? 'Yes' : 'No';
  if (v is DateTime) return _kDateFmt.format(v.toLocal());
  if (v is List) return v.whereType<String>().join(', ');
  final s = v.toString();
  switch (key) {
    case 'obtained_from':
      switch (s) {
        case 'apple':                return 'Apple';
        case 'mac_app_store':        return 'Mac App Store';
        case 'identified_developer': return 'Identified Developer';
        case 'unknown':              return 'Unknown';
        default: return formatKey(s);
      }
    case 'arch_kind':
      switch (s) {
        case 'arch_arm_i64': return 'Universal';
        case 'arch_arm':     return 'Apple Silicon';
        case 'arch_i64':     return 'Intel';
        default:
          return formatKey(s.startsWith('arch_') ? s.substring(5) : s);
      }
  }
  return s;
}

// ── Extensions ────────────────────────────────────────────────────────────────

const _kExtLabels = <String, String>{
  '_name':                    'Name',
  'version':                   'Version',
  'spext_lastModified':        'Last Modified',
  'spext_bundleid':            'Bundle ID',
  'spext_loaded':              'Loaded',
  'spext_architectures':       'Architectures',
  'spext_has64BitIntelCode':   '64-Bit (Intel)',
  'spext_path':                'Location',
  'spext_version':             'Kext Version',
  'spext_load_address':        'Load Address',
  'spext_loadable':            'Loadable',
  'spext_hasAllDependencies':  'Dependencies',
  'spext_signed_by':           'Signed by',
  'spext_info':                'Info',
};

const _kExtDetailOrder = <String>[
  'version',
  'spext_lastModified',
  'spext_bundleid',
  'spext_loaded',
  'spext_architectures',
  'spext_has64BitIntelCode',
  'spext_path',
  'spext_version',
  'spext_load_address',
  'spext_loadable',
  'spext_hasAllDependencies',
  'spext_signed_by',
  'spext_info',
];

String _fmtExt(String key, dynamic v) {
  if (v == null) return '—';
  if (v is bool) return v ? 'Yes' : 'No';
  if (v is DateTime) return _kDateFmt.format(v.toLocal());
  if (v is List) return v.whereType<String>().join(', ');
  final s = v.toString();
  switch (s) {
    case 'spext_yes':           return 'Yes';
    case 'spext_no':            return 'No';
    case 'spext_satisfied':     return 'Satisfied';
    case 'spext_not_satisfied': return 'Not Satisfied';
    case 'yes':                 return 'Yes';
    case 'no':                  return 'No';
    default:                    return s;
  }
}

// ── Fonts ─────────────────────────────────────────────────────────────────────

const _kFontLabels = <String, String>{
  '_name':      'Name',
  'type':       'Kind',
  'valid':      'Valid',
  'enabled':    'Enabled',
  'path':       'Location',
  'typefaces':  'Typefaces',
};

const _kFontDetailOrder = <String>[
  'type', 'valid', 'enabled', 'path', 'typefaces',
];

const _kTypefaceLabels = <String, String>{
  'fullname':       'Full Name',
  'family':         'Family',
  'style':          'Style',
  'version':        'Version',
  'vendor':         'Vendor',
  'unique':         'Unique Name',
  'designer':       'Designer',
  'copyright':      'Copyright',
  'trademark':      'Trademark',
  'description':    'Description',
  'outline':        'Outline',
  'valid':          'Valid',
  'enabled':        'Enabled',
  'duplicate':      'Duplicate',
  'copy_protected': 'Copy Protected',
  'embeddable':     'Embeddable',
};

String _fmtFont(String key, dynamic v) {
  if (v == null) return '—';
  if (v is bool) return v ? 'Yes' : 'No';
  if (v is DateTime) return _kDateFmt.format(v.toLocal());
  final s = v.toString();
  if (key == 'type') {
    switch (s) {
      case 'truetype': return 'TrueType';
      case 'opentype': return 'OpenType';
      case 'bitmap':   return 'Bitmap';
      default: return formatKey(s);
    }
  }
  switch (s) {
    case 'yes': return 'Yes';
    case 'no':  return 'No';
    default:    return s;
  }
}

// ── Frameworks ────────────────────────────────────────────────────────────────

const _kFwLabels = <String, String>{
  '_name':             'Name',
  'version':            'Version',
  'obtained_from':      'Obtained from',
  'lastModified':       'Last Modified',
  'path':               'Location',
  'private_framework':  'Private',
};

const _kFwDetailOrder = <String>[
  'version', 'obtained_from', 'lastModified', 'path', 'private_framework',
];

String _fmtFw(String key, dynamic v) {
  if (v == null) return '—';
  if (v is bool) return v ? 'Yes' : 'No';
  if (v is DateTime) return _kDateFmt.format(v.toLocal());
  final s = v.toString();
  if (key == 'obtained_from') {
    switch (s) {
      case 'apple':                return 'Apple';
      case 'unknown':              return 'Unknown';
      case 'identified_developer': return 'Identified Developer';
      default: return formatKey(s);
    }
  }
  switch (s) {
    case 'yes': return 'Yes';
    case 'no':  return 'No';
    default:    return s;
  }
}

// ── Install History ───────────────────────────────────────────────────────────

const _kInstLabels = <String, String>{
  '_name':            'Name',
  'install_version':  'Version',
  'package_source':   'Source',
  'install_date':     'Install Date',
};

const _kInstDetailOrder = <String>[
  'install_version', 'package_source', 'install_date',
];

String _fmtInst(String key, dynamic v) {
  if (v == null) return '—';
  if (v is bool) return v ? 'Yes' : 'No';
  if (v is DateTime) return _kDateFmt.format(v.toLocal());
  final s = v.toString();
  if (key == 'package_source') {
    switch (s) {
      case 'package_source_apple': return 'Apple';
      case 'package_source_other': return 'Other';
      default:
        return formatKey(s.startsWith('package_source_')
            ? s.substring('package_source_'.length)
            : s);
    }
  }
  return s;
}

// ─────────────────────────────────────────────────────────────────────────────
// Helper: look up a human label for a key given a label map + section prefix
// ─────────────────────────────────────────────────────────────────────────────

String _colLabel(String key, Map<String, String> labels) {
  if (labels.containsKey(key)) return labels[key]!;
  if (key.startsWith('spext_'))    return formatKey(key.substring(6));
  if (key.startsWith('install_'))  return formatKey(key.substring(8));
  return formatKey(key);
}

// ─────────────────────────────────────────────────────────────────────────────
// Table cell value (brief, no time component for dates)
// ─────────────────────────────────────────────────────────────────────────────

String _cellValue(dynamic v, String Function(String, dynamic) fmt, String key) {
  if (v == null) return '—';
  if (v is bool) return v ? 'Yes' : 'No';
  if (v is DateTime) return _kDateCellFmt.format(v.toLocal());
  if (v is List) {
    final strings = v.whereType<String>().toList();
    if (strings.isNotEmpty) return strings.join(', ');
    if (v.isEmpty) return '—';
    return '[${v.length} items]';
  }
  if (v is Map) return '…';
  // Delegate to section formatter for known keys
  final formatted = fmt(key, v);
  return formatted.isEmpty ? v.toString() : formatted;
}

// ─────────────────────────────────────────────────────────────────────────────
// Public widget
// ─────────────────────────────────────────────────────────────────────────────

class DetailTableView extends StatefulWidget {
  final SpxSection section;
  final String searchQuery;
  final Map<String, String> keyLabels;
  final String Function(String key, dynamic value) valueFmt;
  final List<String> detailOrder;
  final IconData detailIcon;
  /// When set, overrides section.columnKeys entirely for the table columns.
  final List<String>? fixedColumns;
  /// Keys to always exclude from the table columns.
  final Set<String> excludeColumns;

  const DetailTableView._({
    super.key,
    required this.section,
    required this.searchQuery,
    required this.keyLabels,
    required this.valueFmt,
    required this.detailOrder,
    required this.detailIcon,
    this.fixedColumns,
    this.excludeColumns = const {},
  });

  factory DetailTableView.applications({
    Key? key,
    required SpxSection section,
    String searchQuery = '',
  }) =>
      DetailTableView._(
        key:         key,
        section:     section,
        searchQuery: searchQuery,
        keyLabels:   _kAppLabels,
        valueFmt:    _fmtApp,
        detailOrder: _kAppDetailOrder,
        detailIcon:  Icons.apps_outlined,
      );

  factory DetailTableView.extensions({
    Key? key,
    required SpxSection section,
    String searchQuery = '',
  }) =>
      DetailTableView._(
        key:            key,
        section:        section,
        searchQuery:    searchQuery,
        keyLabels:      _kExtLabels,
        valueFmt:       _fmtExt,
        detailOrder:    _kExtDetailOrder,
        detailIcon:     Icons.extension_outlined,
        // Remove Bundle ID, Info, and Runtime Environment from table columns.
        excludeColumns: const {'spext_bundleid', 'spext_info', 'spext_runtime_environment'},
      );

  factory DetailTableView.fonts({
    Key? key,
    required SpxSection section,
    String searchQuery = '',
  }) =>
      DetailTableView._(
        key:          key,
        section:      section,
        searchQuery:  searchQuery,
        keyLabels:    _kFontLabels,
        valueFmt:     _fmtFont,
        detailOrder:  _kFontDetailOrder,
        detailIcon:   Icons.font_download_outlined,
        // Hardcode the four visible columns; plist metadata omits 'enabled'.
        fixedColumns: const ['_name', 'type', 'valid', 'enabled'],
      );

  factory DetailTableView.frameworks({
    Key? key,
    required SpxSection section,
    String searchQuery = '',
  }) =>
      DetailTableView._(
        key:         key,
        section:     section,
        searchQuery: searchQuery,
        keyLabels:   _kFwLabels,
        valueFmt:    _fmtFw,
        detailOrder: _kFwDetailOrder,
        detailIcon:  Icons.view_in_ar_outlined,
      );

  factory DetailTableView.installations({
    Key? key,
    required SpxSection section,
    String searchQuery = '',
  }) =>
      DetailTableView._(
        key:         key,
        section:     section,
        searchQuery: searchQuery,
        keyLabels:   _kInstLabels,
        valueFmt:    _fmtInst,
        detailOrder: _kInstDetailOrder,
        detailIcon:  Icons.history_outlined,
      );

  @override
  State<DetailTableView> createState() => _DetailTableViewState();
}

class _DetailTableViewState extends State<DetailTableView> {
  final _filterCtrl = TextEditingController();
  String _filter = '';
  String? _sortColumn;
  bool _sortAscending = true;
  Map<String, dynamic>? _selectedItem;

  static const int _maxCols = 7;

  /// Used for row filtering — local field only.
  String get _q => _filter;

  /// Used for text highlighting — falls back to global query when local
  /// filter is empty, so highlights stay visible on name-matched sections
  /// or after the user has cleared the field.
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
    _sortColumn = '_name';
    _sortAscending = true;
    _syncLocalFilter(widget.searchQuery);
  }

  @override
  void didUpdateWidget(covariant DetailTableView old) {
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

  // ── Column list from plist metadata (or fixed override) ───────────────────

  List<String> get _columns {
    final base = widget.fixedColumns ??
        widget.section.columnKeys
            .where((k) => !k.startsWith('_') || k == '_name')
            .toList();
    return base
        .where((k) => !widget.excludeColumns.contains(k))
        .take(_maxCols)
        .toList();
  }

  // ── Filtered + sorted rows ─────────────────────────────────────────────────

  List<Map<String, dynamic>> get _rows {
    var items = widget.section.items.toList();
    final q = _q;
    if (q.isNotEmpty) {
      final lower = q.toLowerCase();
      items = items.where((item) {
        return item.entries.any((e) =>
            _colLabel(e.key, widget.keyLabels).toLowerCase().contains(lower) ||
            _flatStr(e.value).toLowerCase().contains(lower));
      }).toList();
    }
    final col = _sortColumn;
    if (col != null) {
      items.sort((a, b) {
        final cmp = _cmp(a[col], b[col]);
        return _sortAscending ? cmp : -cmp;
      });
    }
    return items;
  }

  int _cmp(dynamic a, dynamic b) {
    if (a == null && b == null) return 0;
    if (a == null) return 1;
    if (b == null) return -1;
    if (a is num && b is num) return a.compareTo(b);
    if (a is DateTime && b is DateTime) return a.compareTo(b);
    return a.toString().toLowerCase().compareTo(b.toString().toLowerCase());
  }

  String _flatStr(dynamic v) {
    if (v is List) return v.map(_flatStr).join(', ');
    if (v is Map) return v.values.map(_flatStr).join(', ');
    if (v is DateTime) return _kDateFmt.format(v.toLocal());
    return v.toString();
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

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final sp      = context.watch<UiScaleProvider>();
    final theme   = Theme.of(context);
    final cs      = theme.colorScheme;
    final columns = _columns;
    final rows    = _rows;
    final total   = widget.section.items.length;

    // Build the table content once; reused in both the plain and split layouts.
    final tableContent = rows.isEmpty
        ? Center(
            child: Text(
              'No matching items',
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
                keyLabels:   widget.keyLabels,
                valueFmt:    widget.valueFmt,
                searchQuery: _highlightQuery,
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
                    hintText: 'Filter $total items…',
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
                    onTap: () => _toggleSort(col),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 9),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              _colLabel(col, widget.keyLabels),
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
                  _DetailBar(
                    item:    _selectedItem!,
                    icon:    widget.detailIcon,
                    cs:      cs,
                    theme:   theme,
                    sp:      sp,
                    onClose: () => setState(() => _selectedItem = null),
                  ),
                  Expanded(
                    child: _DetailPanel(
                      item:        _selectedItem!,
                      keyLabels:   widget.keyLabels,
                      valueFmt:    widget.valueFmt,
                      detailOrder: widget.detailOrder,
                      searchQuery: _highlightQuery,
                      sp:          sp,
                      theme:       theme,
                      cs:          cs,
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
  final Map<String, String> keyLabels;
  final String Function(String, dynamic) valueFmt;
  final String searchQuery;
  final bool selected;
  final VoidCallback onTap;
  final ThemeData theme;
  final ColorScheme cs;
  final UiScaleProvider sp;

  const _TableRow({
    required this.item,
    required this.columns,
    required this.keyLabels,
    required this.valueFmt,
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
                        horizontal: 10, vertical: 6),
                    child: _Cell(
                      text:     _cellValue(item[col], valueFmt, col),
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
// Table cell with optional highlight
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
  final IconData icon;
  final ColorScheme cs;
  final ThemeData theme;
  final UiScaleProvider sp;
  final VoidCallback onClose;

  const _DetailBar({
    required this.item,
    required this.icon,
    required this.cs,
    required this.theme,
    required this.sp,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final name = item['_name']?.toString() ?? '—';
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
          Icon(icon, size: sp.sz(15), color: cs.onSurfaceVariant),
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
// Detail panel body
// ─────────────────────────────────────────────────────────────────────────────

class _DetailPanel extends StatelessWidget {
  final Map<String, dynamic> item;
  final Map<String, String> keyLabels;
  final String Function(String, dynamic) valueFmt;
  final List<String> detailOrder;
  final String searchQuery;
  final UiScaleProvider sp;
  final ThemeData theme;
  final ColorScheme cs;

  static const double _keyW = 220.0;

  const _DetailPanel({
    required this.item,
    required this.keyLabels,
    required this.valueFmt,
    required this.detailOrder,
    this.searchQuery = '',
    required this.sp,
    required this.theme,
    required this.cs,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
      children: _buildRows(),
    );
  }

  String _label(String key) => _colLabel(key, keyLabels);

  List<Widget> _buildRows() {
    final widgets = <Widget>[];
    final seen    = <String>{};
    final keyW    = sp.sz(_keyW);

    void addScalar(String key, dynamic value) {
      if (isInternalKey(key) || key == '_name') return;
      if (seen.contains(key)) return;
      seen.add(key);
      if (value is Map) return; // handled by addMap
      if (value is List && value.isNotEmpty && value.first is Map) return; // handled by addListOfMaps

      final str = value is List
          ? value.whereType<String>().join(', ')
          : valueFmt(key, value);
      if (str.isEmpty) return;

      widgets.add(_DetailRow(
        label:       _label(key),
        value:       str,
        indent:      0,
        keyWidth:    keyW,
        searchQuery: searchQuery,
        theme:       theme,
        cs:          cs,
      ));
    }

    void addListOfMaps(String key, List<dynamic> list) {
      if (isInternalKey(key) || key == '_name') return;
      if (seen.contains(key)) return;
      seen.add(key);
      final maps = list.whereType<Map>().toList();
      if (maps.isEmpty) return;

      final isFontTypefaces = key == 'typefaces';

      // Section header ("Typefaces", etc.)
      widgets.add(_SubHeader(
        label:  _label(key),
        indent: 0,
        theme:  theme,
        cs:     cs,
      ));

      for (final m in maps) {
        final sub = Map<String, dynamic>.fromEntries(
            m.entries.map((e) => MapEntry(e.key.toString(), e.value)));
        final subName = sub['_name']?.toString() ?? '';

        if (isFontTypefaces) {
          // Collapsible typeface entry — styled like _GpuSection in Displays.
          widgets.add(_CollapsibleEntry(
            name:        subName.isNotEmpty ? subName : '—',
            data:        sub,
            labelFn:     (k) => _kTypefaceLabels[k] ?? formatKey(k),
            valueFmt:    valueFmt,
            keyWidth:    keyW,
            searchQuery: searchQuery,
            sp:          sp,
            theme:       theme,
            cs:          cs,
          ));
        } else {
          // Non-font list-of-maps: static sub-header + KV rows.
          if (subName.isNotEmpty) {
            widgets.add(_SubHeader(
              label:  subName,
              indent: sp.sz(20),
              theme:  theme,
              cs:     cs,
            ));
          }
          for (final e in sub.entries) {
            if (isInternalKey(e.key) || e.key == '_name') continue;
            if (e.value is Map || e.value is List) continue;
            final val = valueFmt(e.key, e.value);
            widgets.add(_DetailRow(
              label:       _label(e.key),
              value:       val.isEmpty ? e.value.toString() : val,
              indent:      sp.sz(subName.isNotEmpty ? 36 : 20),
              keyWidth:    (keyW - sp.sz(subName.isNotEmpty ? 36 : 20)).clamp(80.0, double.infinity),
              searchQuery: searchQuery,
              theme:       theme,
              cs:          cs,
            ));
          }
        }
      }
    }

    // 1. Preferred order
    for (final key in detailOrder) {
      if (!item.containsKey(key)) continue;
      final v = item[key];
      if (v is List && v.isNotEmpty && v.first is Map) {
        addListOfMaps(key, v);
      } else {
        addScalar(key, v);
      }
    }

    // 2. Remaining keys not yet shown
    for (final e in item.entries) {
      if (seen.contains(e.key)) continue;
      if (isInternalKey(e.key) || e.key == '_name') continue;
      final v = e.value;
      if (v is List && v.isNotEmpty && v.first is Map) {
        addListOfMaps(e.key, v);
      } else if (v is Map) {
        // Show map as sub-header + indented rows
        seen.add(e.key);
        widgets.add(_SubHeader(
          label: _label(e.key), indent: 0, theme: theme, cs: cs));
        for (final se in v.entries) {
          final sk = se.key.toString();
          if (isInternalKey(sk)) continue;
          widgets.add(_DetailRow(
            label:       _label(sk),
            value:       valueFmt(sk, se.value),
            indent:      sp.sz(20),
            keyWidth:    (keyW - sp.sz(20)).clamp(80.0, double.infinity),
            searchQuery: searchQuery,
            theme:       theme,
            cs:          cs,
          ));
        }
      } else {
        addScalar(e.key, v);
      }
    }

    return widgets;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Collapsible entry (used for font typefaces) — same animated style as
// _GpuSection in displays_view.dart
// ─────────────────────────────────────────────────────────────────────────────

class _CollapsibleEntry extends StatefulWidget {
  final String name;
  final Map<String, dynamic> data;
  final String Function(String key) labelFn;
  final String Function(String key, dynamic value) valueFmt;
  final double keyWidth;
  final String searchQuery;
  final UiScaleProvider sp;
  final ThemeData theme;
  final ColorScheme cs;

  const _CollapsibleEntry({
    required this.name,
    required this.data,
    required this.labelFn,
    required this.valueFmt,
    required this.keyWidth,
    this.searchQuery = '',
    required this.sp,
    required this.theme,
    required this.cs,
  });

  @override
  State<_CollapsibleEntry> createState() => _CollapsibleEntryState();
}

class _CollapsibleEntryState extends State<_CollapsibleEntry>
    with SingleTickerProviderStateMixin {
  bool _expanded = true;

  late final AnimationController _animCtrl;
  late final Animation<double> _sizeFactor;
  late final Animation<double> _chevronTurns;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
      value: 1.0,
    );
    _sizeFactor = CurvedAnimation(parent: _animCtrl, curve: Curves.easeInOut);
    _chevronTurns = Tween<double>(begin: -0.25, end: 0.0).animate(
      CurvedAnimation(parent: _animCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() => _expanded = !_expanded);
    _expanded ? _animCtrl.forward() : _animCtrl.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final sp    = widget.sp;
    final theme = widget.theme;
    final cs    = widget.cs;

    // Collect leaf rows (scalar, non-internal, non-name entries).
    final entries = widget.data.entries
        .where((e) =>
            !isInternalKey(e.key) &&
            e.key != '_name' &&
            e.value is! Map &&
            e.value is! List)
        .toList();

    final fieldCount = entries.length;

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Animated collapsible header ────────────────────────────────
          InkWell(
            onTap: _toggle,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
              child: Row(
                children: [
                  RotationTransition(
                    turns: _chevronTurns,
                    child: Icon(
                      Icons.expand_more,
                      size: sp.sz(20),
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      widget.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: cs.onSurface,
                      ),
                    ),
                  ),
                  if (!_expanded)
                    Text(
                      '$fieldCount ${fieldCount == 1 ? 'field' : 'fields'}',
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: cs.onSurfaceVariant),
                    ),
                ],
              ),
            ),
          ),

          // ── Animated content ───────────────────────────────────────────
          SizeTransition(
            sizeFactor: _sizeFactor,
            child: Padding(
              padding: const EdgeInsets.only(left: 26),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: entries.map((e) {
                  final val = widget.valueFmt(e.key, e.value);
                  return _DetailRow(
                    label:       widget.labelFn(e.key),
                    value:       val.isEmpty ? e.value.toString() : val,
                    indent:      0,
                    keyWidth:    (widget.keyWidth - 26).clamp(80.0, double.infinity),
                    searchQuery: widget.searchQuery,
                    theme:       theme,
                    cs:          cs,
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Detail row
// ─────────────────────────────────────────────────────────────────────────────

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final double indent;
  final double keyWidth;
  final String searchQuery;
  final ThemeData theme;
  final ColorScheme cs;

  const _DetailRow({
    required this.label,
    required this.value,
    required this.indent,
    required this.keyWidth,
    this.searchQuery = '',
    required this.theme,
    required this.cs,
  });

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.only(left: indent, top: 4, bottom: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: keyWidth,
              child: HighlightText(
                text:  label,
                query: searchQuery,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color:      cs.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: HighlightText(
                text:  value,
                query: searchQuery,
                style: theme.textTheme.bodyMedium,
              ),
            ),
          ],
        ),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Sub-section header
// ─────────────────────────────────────────────────────────────────────────────

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
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.only(left: indent, top: 10, bottom: 2),
        child: Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            color:      cs.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
}
