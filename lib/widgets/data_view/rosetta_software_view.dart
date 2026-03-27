import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../providers/ui_scale_provider.dart';
import '../resizable_split.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Value formatting helpers
// ─────────────────────────────────────────────────────────────────────────────

final _dateFmt = DateFormat('dd.MM.yy, HH:mm');

String _fmtHasNative(String raw) {
  if (raw == 'has_native_version_yes') return 'Yes';
  if (raw == 'has_native_version_no')  return 'No';
  // Generic: strip leading prefix, replace underscores, title-case.
  final stripped = raw.startsWith('has_native_version_')
      ? raw.substring('has_native_version_'.length)
      : raw;
  return _titleCase(stripped.replaceAll('_', ' '));
}

String _fmtReason(String raw) {
  if (raw == 'reason_x86_only') return 'No native version on the system.';
  final stripped = raw.startsWith('reason_')
      ? raw.substring('reason_'.length)
      : raw;
  return _titleCase(stripped.replaceAll('_', ' '));
}

String _titleCase(String s) {
  if (s.isEmpty) return s;
  return s.split(' ').map((w) {
    if (w.isEmpty) return w;
    return w[0].toUpperCase() + w.substring(1);
  }).join(' ');
}

String _fmtDate(dynamic v) {
  if (v is DateTime) return _dateFmt.format(v.toLocal());
  return v?.toString() ?? '—';
}

String _fmtValue(String key, dynamic v) {
  if (v == null) return '—';
  if (v is bool) return v ? 'Yes' : 'No';
  if (v is DateTime) return _fmtDate(v);
  final s = v.toString();
  if (key == 'has_native_version') return _fmtHasNative(s);
  if (key == 'reason') return _fmtReason(s);
  return s;
}

// ─────────────────────────────────────────────────────────────────────────────
// Label maps
// ─────────────────────────────────────────────────────────────────────────────

const _kProcessInfoLabels = <String, String>{
  'process_bundle_id':      'Bundle ID',
  'process_bundle_version': 'Bundle Version',
  'process_developer_name': 'Developer',
  'process_name':           'Process Name',
  'process_path':           'Path',
  'process_team_id':        'Team ID',
};

const _kProcessInfoOrder = <String>[
  'process_name',
  'process_developer_name',
  'process_bundle_id',
  'process_bundle_version',
  'process_team_id',
  'process_path',
];

const _kAppDetailOrder = <String>[
  'reason',
  'has_native_version',
  'number_of_times_launched',
  'previously_launched_date',
  'process_info',
];

const _kAppLabels = <String, String>{
  'reason':                   'Rosetta Fallback Reason',
  'has_native_version':       'Has Native Version',
  'number_of_times_launched': 'Times Launched',
  'previously_launched_date': 'Last Used Date',
  'process_info':             'Primary Process Information',
};

String _appLabel(String key) => _kAppLabels[key] ?? _titleCase(key.replaceAll('_', ' '));
String _processInfoLabel(String key) => _kProcessInfoLabels[key] ?? _titleCase(key.replaceAll('_', ' '));

// ─────────────────────────────────────────────────────────────────────────────
// Node helpers
// ─────────────────────────────────────────────────────────────────────────────

enum _NodeLevel { developer, app }

String _nodeName(Map<String, dynamic> node) =>
    node['_name']?.toString() ?? 'Unknown';

List<Map<String, dynamic>> _appChildren(Map<String, dynamic> devNode) {
  final raw = devNode['_items'];
  if (raw is List) {
    return raw.whereType<Map<String, dynamic>>().toList();
  }
  return [];
}

// ─────────────────────────────────────────────────────────────────────────────
// Public widget
// ─────────────────────────────────────────────────────────────────────────────

/// Two-pane Rosetta Software viewer.
/// Left: developer → app tree. Right: detail panel for the selected node.
class RosettaSoftwareView extends StatefulWidget {
  final List<Map<String, dynamic>> items;

  const RosettaSoftwareView({super.key, required this.items});

  @override
  State<RosettaSoftwareView> createState() => _RosettaSoftwareViewState();
}

class _RosettaSoftwareViewState extends State<RosettaSoftwareView> {
  Map<String, dynamic>? _selected;
  _NodeLevel _selectedLevel = _NodeLevel.developer;

  /// Keys of currently expanded developer nodes.
  final Set<int> _expanded = {};

  @override
  void initState() {
    super.initState();
    // Expand all developer nodes by default.
    for (int i = 0; i < widget.items.length; i++) {
      _expanded.add(i);
    }
    // Pre-select the first developer so the detail panel is never blank.
    if (widget.items.isNotEmpty) {
      _selected = widget.items.first;
      _selectedLevel = _NodeLevel.developer;
    }
  }

  void _selectDev(Map<String, dynamic> node) => setState(() {
        _selected = node;
        _selectedLevel = _NodeLevel.developer;
      });

  void _selectApp(Map<String, dynamic> node) => setState(() {
        _selected = node;
        _selectedLevel = _NodeLevel.app;
      });

  void _toggleDev(int idx) => setState(() {
        if (_expanded.contains(idx)) {
          _expanded.remove(idx);
        } else {
          _expanded.add(idx);
        }
      });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ResizableSplit(
      left: _TreePanel(
        developers: widget.items,
        selected: _selected,
        expanded: _expanded,
        onSelectDev: _selectDev,
        onSelectApp: _selectApp,
        onToggleDev: _toggleDev,
      ),
      right: _selected == null
          ? Center(
              child: Text(
                'Select an item',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: cs.onSurface.withAlpha(100),
                    ),
              ),
            )
          : _DetailPanel(
              node: _selected!,
              level: _selectedLevel,
            ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tree panel
// ─────────────────────────────────────────────────────────────────────────────

class _TreePanel extends StatelessWidget {
  final List<Map<String, dynamic>> developers;
  final Map<String, dynamic>? selected;
  final Set<int> expanded;
  final ValueChanged<Map<String, dynamic>> onSelectDev;
  final ValueChanged<Map<String, dynamic>> onSelectApp;
  final ValueChanged<int> onToggleDev;

  const _TreePanel({
    required this.developers,
    required this.selected,
    required this.expanded,
    required this.onSelectDev,
    required this.onSelectApp,
    required this.onToggleDev,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      color: cs.surfaceContainerLow,
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: 6),
        children: [
          for (int i = 0; i < developers.length; i++)
            _DevTile(
              devIdx: i,
              dev: developers[i],
              selected: selected,
              isExpanded: expanded.contains(i),
              onSelectDev: onSelectDev,
              onSelectApp: onSelectApp,
              onToggle: onToggleDev,
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Developer tile
// ─────────────────────────────────────────────────────────────────────────────

class _DevTile extends StatelessWidget {
  final int devIdx;
  final Map<String, dynamic> dev;
  final Map<String, dynamic>? selected;
  final bool isExpanded;
  final ValueChanged<Map<String, dynamic>> onSelectDev;
  final ValueChanged<Map<String, dynamic>> onSelectApp;
  final ValueChanged<int> onToggle;

  static const double _baseIndent = 8.0;
  static const double _childIndent = 28.0;

  const _DevTile({
    required this.devIdx,
    required this.dev,
    required this.selected,
    required this.isExpanded,
    required this.onSelectDev,
    required this.onSelectApp,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final sp = context.watch<UiScaleProvider>();

    final apps = _appChildren(dev);
    final isSelected = selected == dev;
    final rowColor = isSelected ? cs.primaryContainer : Colors.transparent;
    final labelColor = isSelected ? cs.onPrimaryContainer : cs.onSurface;
    final mutedColor = isSelected ? cs.onPrimaryContainer.withAlpha(180) : cs.onSurfaceVariant;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Developer row ─────────────────────────────────────────────────
        Material(
          color: rowColor,
          child: InkWell(
            onTap: () => onSelectDev(dev),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(_baseIndent, 4, 8, 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Chevron toggle.
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: apps.isNotEmpty ? () => onToggle(devIdx) : null,
                    child: SizedBox(
                      width: 20,
                      height: 28,
                      child: apps.isNotEmpty
                          ? Icon(
                              isExpanded
                                  ? Icons.expand_more
                                  : Icons.chevron_right,
                              size: sp.sz(16),
                              color: mutedColor,
                            )
                          : null,
                    ),
                  ),

                  Icon(
                    Icons.person_outline,
                    size: sp.sz(15),
                    color: isSelected ? cs.primary : cs.onSurfaceVariant,
                  ),
                  const SizedBox(width: 7),

                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _nodeName(dev),
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                              color: labelColor,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (apps.isNotEmpty)
                            Text(
                              '${apps.length} app${apps.length == 1 ? '' : 's'}',
                              style: theme.textTheme.bodySmall?.copyWith(color: mutedColor),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // ── App children ──────────────────────────────────────────────────
        if (isExpanded)
          for (final app in apps)
            _AppTile(
              app: app,
              selected: selected,
              onSelect: onSelectApp,
              indent: _childIndent,
            ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// App tile (leaf)
// ─────────────────────────────────────────────────────────────────────────────

class _AppTile extends StatelessWidget {
  final Map<String, dynamic> app;
  final Map<String, dynamic>? selected;
  final ValueChanged<Map<String, dynamic>> onSelect;
  final double indent;

  const _AppTile({
    required this.app,
    required this.selected,
    required this.onSelect,
    required this.indent,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final sp = context.watch<UiScaleProvider>();

    final isSelected = selected == app;
    final rowColor = isSelected ? cs.primaryContainer : Colors.transparent;
    final labelColor = isSelected ? cs.onPrimaryContainer : cs.onSurface;
    final mutedColor = isSelected ? cs.onPrimaryContainer.withAlpha(180) : cs.onSurfaceVariant;

    final hasNative = app['has_native_version']?.toString() ?? '';
    final hasNativeStr = hasNative.isNotEmpty ? _fmtHasNative(hasNative) : null;

    return Material(
      color: rowColor,
      child: InkWell(
        onTap: () => onSelect(app),
        child: Padding(
          padding: EdgeInsets.fromLTRB(indent, 3, 8, 3),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Spacer where chevron would be.
              const SizedBox(width: 20),

              Icon(
                Icons.apps_outlined,
                size: sp.sz(14),
                color: isSelected ? cs.primary : cs.onSurfaceVariant,
              ),
              const SizedBox(width: 7),

              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _nodeName(app),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                          color: labelColor,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (hasNativeStr != null)
                        Text(
                          'Native: $hasNativeStr',
                          style: theme.textTheme.bodySmall?.copyWith(color: mutedColor),
                        ),
                    ],
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
// Detail panel
// ─────────────────────────────────────────────────────────────────────────────

class _DetailPanel extends StatelessWidget {
  final Map<String, dynamic> node;
  final _NodeLevel level;

  const _DetailPanel({required this.node, required this.level});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final sp = context.watch<UiScaleProvider>();

    final name = _nodeName(node);
    final icon = level == _NodeLevel.developer
        ? Icons.person_outline
        : Icons.apps_outlined;

    final rows = level == _NodeLevel.developer
        ? _buildDevRows(theme, cs)
        : _buildAppRows(theme, cs);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Header ─────────────────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 10),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: cs.outlineVariant, width: 0.5)),
          ),
          child: Row(
            children: [
              Icon(icon, size: sp.sz(22), color: cs.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  name,
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),

        // ── Field list ─────────────────────────────────────────────────────
        Expanded(
          child: rows.isEmpty
              ? Center(
                  child: Text(
                    'No details available',
                    style: theme.textTheme.bodyMedium?.copyWith(color: cs.onSurface.withAlpha(100)),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  itemCount: rows.length,
                  separatorBuilder: (context2, i2) => Divider(
                    height: 1,
                    color: cs.outlineVariant.withAlpha(80),
                    indent: 20,
                    endIndent: 20,
                  ),
                  itemBuilder: (_, i) => rows[i],
                ),
        ),
      ],
    );
  }

  List<Widget> _buildDevRows(ThemeData theme, ColorScheme cs) {
    final rows = <Widget>[];

    // All Child Processes.
    final processNames = node['process_names'];
    if (processNames is List && processNames.isNotEmpty) {
      final joined = processNames.map((e) => e.toString()).join(', ');
      rows.add(_FieldRow(label: 'All Child Processes', value: joined, theme: theme, cs: cs));
    }

    return rows;
  }

  List<Widget> _buildAppRows(ThemeData theme, ColorScheme cs) {
    final rows = <Widget>[];

    // Emit in preferred order.
    for (final key in _kAppDetailOrder) {
      final v = node[key];
      if (v == null) continue;

      if (key == 'process_info' && v is Map) {
        // Sub-section header.
        rows.add(_SectionLabel(label: _appLabel(key), theme: theme, cs: cs));
        // Emit process info fields in order.
        for (final infoKey in _kProcessInfoOrder) {
          final iv = v[infoKey];
          if (iv == null) continue;
          rows.add(_FieldRow(
            label: _processInfoLabel(infoKey),
            value: iv.toString(),
            theme: theme,
            cs: cs,
            indent: 16,
          ));
        }
        // Any remaining process_info keys not in the order list.
        for (final e in v.entries) {
          if (_kProcessInfoOrder.contains(e.key.toString())) continue;
          if (e.value == null) continue;
          rows.add(_FieldRow(
            label: _processInfoLabel(e.key.toString()),
            value: e.value.toString(),
            theme: theme,
            cs: cs,
            indent: 16,
          ));
        }
        continue;
      }

      rows.add(_FieldRow(
        label: _appLabel(key),
        value: _fmtValue(key, v),
        theme: theme,
        cs: cs,
      ));
    }

    // Any extra keys not in the order list.
    for (final e in node.entries) {
      final k = e.key;
      if (k.startsWith('_')) continue;
      if (_kAppDetailOrder.contains(k)) continue;
      if (e.value == null) continue;
      rows.add(_FieldRow(
        label: _appLabel(k),
        value: _fmtValue(k, e.value),
        theme: theme,
        cs: cs,
      ));
    }

    return rows;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Section label (sub-heading in detail panel)
// ─────────────────────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  final ThemeData theme;
  final ColorScheme cs;

  const _SectionLabel({required this.label, required this.theme, required this.cs});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 2),
        child: Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: cs.onSurface,
          ),
        ),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Field row
// ─────────────────────────────────────────────────────────────────────────────

class _FieldRow extends StatelessWidget {
  final String label;
  final String value;
  final ThemeData theme;
  final ColorScheme cs;
  final double indent;

  const _FieldRow({
    required this.label,
    required this.value,
    required this.theme,
    required this.cs,
    this.indent = 0,
  });

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.fromLTRB(20 + indent, 6, 20, 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 210,
              child: Text(
                label,
                style: theme.textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: SelectableText(value, style: theme.textTheme.bodyMedium),
            ),
          ],
        ),
      );
}
