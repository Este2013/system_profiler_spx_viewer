import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../providers/ui_scale_provider.dart';
import '../../utils/key_formatter.dart';

// ─────────────────────────────────────────────────────────────────────────────
// GPU field labels & display order  (sppci_* keys)
// ─────────────────────────────────────────────────────────────────────────────

const _kGpuLabels = <String, String>{
  'sppci_model':       'Chipset Model',
  'sppci_device_type': 'Type',
  'sppci_bus':         'Bus',
  'sppci_cores':       'Total Number of Cores',
  'sppci_vendor':      'Vendor',
  'sppci_metal':       'Metal Support',
  'sppci_vram_shared': 'VRAM (Dynamic, Max)',
  'sppci_vram':        'VRAM',
  'sppci_vram_total':  'VRAM (Total)',
};

const _kGpuOrder = [
  'sppci_model',
  'sppci_device_type',
  'sppci_bus',
  'sppci_cores',
  'sppci_vendor',
  'sppci_metal',
  'sppci_vram_shared',
  'sppci_vram',
  'sppci_vram_total',
];

// ─────────────────────────────────────────────────────────────────────────────
// Display field labels & display order  (_spdisplays_* keys)
// ─────────────────────────────────────────────────────────────────────────────

const _kDisplayLabels = <String, String>{
  '_spdisplays_resolution':          'Resolution',
  '_spdisplays_ui_resolution':       'UI Looks Like',
  '_spdisplays_main':                'Main Display',
  '_spdisplays_mirror':              'Mirror',
  '_spdisplays_online':              'Online',
  '_spdisplays_rotation':            'Rotation',
  '_spdisplays_connection_type':     'Connection Type',
  '_spdisplays_ambient_brightness':  'Automatically Adjust Brightness',
  '_spdisplays_display_type':        'Display Type',
  '_spdisplays_depth':               'Color Depth',
  '_spdisplays_asleep':              'Asleep',
  '_spdisplays_serial_number':       'Serial Number',
  '_spdisplays_year_of_manufacture': 'Year',
  '_spdisplays_week_of_manufacture': 'Week',
  '_spdisplays_display-product-id':  'Display Product ID',
  '_spdisplays_displayID':           'Display ID',
  '_spdisplays_pixels':              'Pixels',
};

const _kDisplayOrder = [
  '_spdisplays_resolution',
  '_spdisplays_ui_resolution',
  '_spdisplays_main',
  '_spdisplays_mirror',
  '_spdisplays_online',
  '_spdisplays_rotation',
  '_spdisplays_connection_type',
  '_spdisplays_ambient_brightness',
  '_spdisplays_display_type',
  '_spdisplays_depth',
  '_spdisplays_asleep',
  '_spdisplays_serial_number',
  '_spdisplays_year_of_manufacture',
  '_spdisplays_week_of_manufacture',
  '_spdisplays_display-product-id',
  '_spdisplays_displayID',
  '_spdisplays_pixels',
];

// ─────────────────────────────────────────────────────────────────────────────
// Label helpers
// ─────────────────────────────────────────────────────────────────────────────

String _gpuLabelFor(String key) {
  if (_kGpuLabels.containsKey(key)) return _kGpuLabels[key]!;
  if (key.startsWith('sppci_')) return formatKey(key.substring('sppci_'.length));
  return formatKey(key);
}

String _displayLabelFor(String key) {
  if (_kDisplayLabels.containsKey(key)) return _kDisplayLabels[key]!;
  if (key.startsWith('_spdisplays_')) return formatKey(key.substring('_spdisplays_'.length));
  if (key.startsWith('spdisplays_')) return formatKey(key.substring('spdisplays_'.length));
  return formatKey(key);
}

// ─────────────────────────────────────────────────────────────────────────────
// Value formatter
// ─────────────────────────────────────────────────────────────────────────────

String _fmtVal(dynamic v) {
  if (v == null) return '—';
  if (v is bool) return v ? 'Yes' : 'No';
  if (v is DateTime) return DateFormat('yyyy-MM-dd  HH:mm:ss').format(v.toLocal());
  if (v is List) {
    if (v.every((e) => e is! Map && e is! List)) {
      return v.map((e) => formatSpxValue(e.toString())).join(', ');
    }
    return '${v.length} item${v.length == 1 ? '' : 's'}';
  }
  if (v is String) {
    final f = formatSpxValue(v);
    return f.isEmpty ? '—' : f;
  }
  return v.toString();
}

// ─────────────────────────────────────────────────────────────────────────────
// Search match helpers
// ─────────────────────────────────────────────────────────────────────────────

bool _gpuMatchesQuery(Map<String, dynamic> item, String q) {
  final lower = q.toLowerCase();
  final name = item['_name']?.toString() ?? '';
  if (name.toLowerCase().contains(lower)) return true;
  for (final e in item.entries) {
    if (e.key == 'spdisplays_ndrvs') continue; // checked separately
    if (isInternalKey(e.key)) continue;
    if (_gpuLabelFor(e.key).toLowerCase().contains(lower)) return true;
    if (_fmtVal(e.value).toLowerCase().contains(lower)) return true;
  }
  final displays = item['spdisplays_ndrvs'];
  if (displays is List) {
    for (final d in displays) {
      if (d is Map && _displayMatchesQuery(Map<String, dynamic>.from(d as Map), q)) {
        return true;
      }
    }
  }
  return false;
}

bool _displayMatchesQuery(Map<String, dynamic> display, String q) {
  final lower = q.toLowerCase();
  final name = display['_name']?.toString() ?? '';
  if (name.toLowerCase().contains(lower)) return true;
  for (final e in display.entries) {
    if (isInternalKey(e.key)) continue;
    if (e.key == '_name') continue;
    if (_displayLabelFor(e.key).toLowerCase().contains(lower)) return true;
    if (_fmtVal(e.value).toLowerCase().contains(lower)) return true;
  }
  return false;
}

// ─────────────────────────────────────────────────────────────────────────────
// Public widget
// ─────────────────────────────────────────────────────────────────────────────

/// Renders [SPDisplaysDataType] as collapsible GPU sections, each containing
/// GPU properties and a nested "Displays" sub-section with collapsible
/// per-display entries — matching the macOS System Information layout.
class DisplaysView extends StatefulWidget {
  final List<Map<String, dynamic>> items;
  final String searchQuery;

  const DisplaysView({
    super.key,
    required this.items,
    this.searchQuery = '',
  });

  @override
  State<DisplaysView> createState() => _DisplaysViewState();
}

class _DisplaysViewState extends State<DisplaysView> {
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
    final sp = context.watch<UiScaleProvider>();
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Filter bar ───────────────────────────────────────────────────────
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

        // ── GPU sections ─────────────────────────────────────────────────────
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            itemCount: widget.items.length,
            itemBuilder: (context, i) => _GpuSection(
              item: widget.items[i],
              searchQuery: _q,
              showDivider: i < widget.items.length - 1,
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// GPU collapsible section
// ─────────────────────────────────────────────────────────────────────────────

class _GpuSection extends StatefulWidget {
  final Map<String, dynamic> item;
  final String searchQuery;
  final bool showDivider;

  const _GpuSection({
    required this.item,
    required this.searchQuery,
    required this.showDivider,
  });

  @override
  State<_GpuSection> createState() => _GpuSectionState();
}

class _GpuSectionState extends State<_GpuSection>
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
  void didUpdateWidget(_GpuSection old) {
    super.didUpdateWidget(old);
    if (widget.searchQuery.isNotEmpty && !_expanded) {
      setState(() => _expanded = true);
      _animCtrl.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    final sp = context.watch<UiScaleProvider>();
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final item = widget.item;
    final q = widget.searchQuery;

    // Hide entirely when search matches nothing in this GPU.
    if (q.isNotEmpty && !_gpuMatchesQuery(item, q)) {
      return const SizedBox.shrink();
    }

    final gpuName = item['_name']?.toString()
        ?? item['sppci_model']?.toString()
        ?? 'GPU';

    // Extract nested displays array.
    final displaysRaw = item['spdisplays_ndrvs'];
    final displays = displaysRaw is List
        ? displaysRaw
            .whereType<Map>()
            .map((m) => Map<String, dynamic>.from(m))
            .toList()
        : <Map<String, dynamic>>[];

    final gpuRows = _buildGpuRows(item, q, sp, theme, cs);
    final totalBadge = gpuRows.length + displays.length;

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── GPU header ────────────────────────────────────────────────────
          InkWell(
            onTap: _toggle,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
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
                      gpuName,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: cs.onSurface,
                      ),
                    ),
                  ),
                  if (!_expanded)
                    Text(
                      '$totalBadge ${totalBadge == 1 ? 'item' : 'items'}',
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: cs.onSurfaceVariant),
                    ),
                ],
              ),
            ),
          ),

          // ── Animated content ──────────────────────────────────────────────
          SizeTransition(
            sizeFactor: _sizeFactor,
            child: Padding(
              padding: const EdgeInsets.only(left: 26),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // GPU property rows
                  ...gpuRows,

                  // "Displays:" sub-header + per-display sections
                  if (displays.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    _DisplaysSubHeader(theme: theme, cs: cs),
                    const SizedBox(height: 4),
                    ...List.generate(
                      displays.length,
                      (i) => _DisplaySection(
                        display: displays[i],
                        searchQuery: q,
                        showDivider: i < displays.length - 1,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          if (widget.showDivider) ...[
            const SizedBox(height: 6),
            Divider(color: cs.outlineVariant.withAlpha(120)),
            const SizedBox(height: 2),
          ],
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------

  static const double _keyWidth = 220.0;

  List<Widget> _buildGpuRows(
    Map<String, dynamic> item,
    String q,
    UiScaleProvider sp,
    ThemeData theme,
    ColorScheme cs,
  ) {
    final rows = <Widget>[];
    final seen = <String>{};
    final keyW = sp.sz(_keyWidth);

    void addRow(String key, dynamic value) {
      if (isInternalKey(key)) return;
      if (key == '_name') return;            // shown as section header
      if (key == 'spdisplays_ndrvs') return; // rendered separately
      final label = _gpuLabelFor(key);
      final val = _fmtVal(value);
      if (q.isNotEmpty) {
        final lower = q.toLowerCase();
        if (!label.toLowerCase().contains(lower) &&
            !val.toLowerCase().contains(lower)) return;
      }
      rows.add(_KvRow(
        label: label,
        value: val,
        keyWidth: keyW,
        searchQuery: q,
        theme: theme,
        cs: cs,
      ));
    }

    // 1. Preferred order
    for (final key in _kGpuOrder) {
      if (!item.containsKey(key)) continue;
      if (seen.contains(key)) continue;
      seen.add(key);
      addRow(key, item[key]);
    }
    // 2. Any remaining / future keys
    for (final e in item.entries) {
      if (seen.contains(e.key)) continue;
      seen.add(e.key);
      addRow(e.key, e.value);
    }

    return rows;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// "Displays:" sub-section header
// ─────────────────────────────────────────────────────────────────────────────

class _DisplaysSubHeader extends StatelessWidget {
  final ThemeData theme;
  final ColorScheme cs;

  const _DisplaysSubHeader({required this.theme, required this.cs});

  @override
  Widget build(BuildContext context) {
    return Text(
      'Displays:',
      style: theme.textTheme.titleSmall?.copyWith(
        fontWeight: FontWeight.w700,
        color: cs.onSurface,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Per-display collapsible section
// ─────────────────────────────────────────────────────────────────────────────

class _DisplaySection extends StatefulWidget {
  final Map<String, dynamic> display;
  final String searchQuery;
  final bool showDivider;

  const _DisplaySection({
    required this.display,
    required this.searchQuery,
    required this.showDivider,
  });

  @override
  State<_DisplaySection> createState() => _DisplaySectionState();
}

class _DisplaySectionState extends State<_DisplaySection>
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
  void didUpdateWidget(_DisplaySection old) {
    super.didUpdateWidget(old);
    if (widget.searchQuery.isNotEmpty && !_expanded) {
      setState(() => _expanded = true);
      _animCtrl.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    final sp = context.watch<UiScaleProvider>();
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final display = widget.display;
    final q = widget.searchQuery;

    if (q.isNotEmpty && !_displayMatchesQuery(display, q)) {
      return const SizedBox.shrink();
    }

    final displayName = display['_name']?.toString() ?? 'Display';
    final rows = _buildDisplayRows(display, q, sp, theme, cs);

    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Display header ──────────────────────────────────────────────────
          InkWell(
            onTap: rows.isNotEmpty ? _toggle : null,
            borderRadius: BorderRadius.circular(6),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 4),
              child: Row(
                children: [
                  if (rows.isNotEmpty)
                    RotationTransition(
                      turns: _chevronTurns,
                      child: Icon(
                        Icons.expand_more,
                        size: sp.sz(18),
                        color: cs.primary,
                      ),
                    )
                  else
                    Icon(
                      Icons.monitor_outlined,
                      size: sp.sz(18),
                      color: cs.primary,
                    ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      displayName,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: cs.onSurface,
                      ),
                    ),
                  ),
                  if (!_expanded && rows.isNotEmpty)
                    Text(
                      '${rows.length} field${rows.length == 1 ? '' : 's'}',
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: cs.onSurfaceVariant),
                    ),
                ],
              ),
            ),
          ),

          // ── Animated property rows ──────────────────────────────────────────
          if (rows.isNotEmpty)
            SizeTransition(
              sizeFactor: _sizeFactor,
              child: Padding(
                padding: const EdgeInsets.only(left: 24, bottom: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: rows,
                ),
              ),
            ),

          if (widget.showDivider)
            Divider(
              color: cs.outlineVariant.withAlpha(80),
            ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------

  static const double _keyWidth = 220.0;

  List<Widget> _buildDisplayRows(
    Map<String, dynamic> display,
    String q,
    UiScaleProvider sp,
    ThemeData theme,
    ColorScheme cs,
  ) {
    final rows = <Widget>[];
    final seen = <String>{};
    final keyW = sp.sz(_keyWidth);

    void addRow(String key, dynamic value) {
      if (isInternalKey(key)) return;
      if (key == '_name') return; // shown as section header
      final label = _displayLabelFor(key);
      final val = _fmtVal(value);
      if (q.isNotEmpty) {
        final lower = q.toLowerCase();
        if (!label.toLowerCase().contains(lower) &&
            !val.toLowerCase().contains(lower)) return;
      }
      rows.add(_KvRow(
        label: label,
        value: val,
        keyWidth: keyW,
        searchQuery: q,
        theme: theme,
        cs: cs,
      ));
    }

    // 1. Preferred order
    for (final key in _kDisplayOrder) {
      if (!display.containsKey(key)) continue;
      if (seen.contains(key)) continue;
      seen.add(key);
      addRow(key, display[key]);
    }
    // 2. Any remaining / future keys
    for (final e in display.entries) {
      if (seen.contains(e.key)) continue;
      seen.add(e.key);
      addRow(e.key, e.value);
    }

    return rows;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Key-value row
// ─────────────────────────────────────────────────────────────────────────────

class _KvRow extends StatelessWidget {
  final String label;
  final String value;
  final double keyWidth;
  final String searchQuery;
  final ThemeData theme;
  final ColorScheme cs;

  const _KvRow({
    required this.label,
    required this.value,
    required this.keyWidth,
    required this.searchQuery,
    required this.theme,
    required this.cs,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
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
            child: searchQuery.isNotEmpty
                ? _HighlightText(
                    text: value,
                    query: searchQuery,
                    theme: theme,
                    cs: cs,
                  )
                : SelectableText(value, style: theme.textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Search highlight
// ─────────────────────────────────────────────────────────────────────────────

class _HighlightText extends StatelessWidget {
  final String text;
  final String query;
  final ThemeData theme;
  final ColorScheme cs;

  const _HighlightText({
    required this.text,
    required this.query,
    required this.theme,
    required this.cs,
  });

  @override
  Widget build(BuildContext context) {
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
      TextSpan(style: theme.textTheme.bodyMedium, children: spans),
    );
  }
}
