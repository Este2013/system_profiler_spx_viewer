import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../providers/ui_scale_provider.dart';
import '../resizable_split.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Label helpers
// ─────────────────────────────────────────────────────────────────────────────

final _dateFmt = DateFormat('dd.MM.yy, HH:mm');

const _kGroupLabels = <String, String>{
  'summary_tree_name': 'Sync Summary',
  'log_tree_name':     'Sync Logs',
};

const _kFieldLabels = <String, String>{
  'summary_os_version':    'OS Version',
  'summary_of_sync_log':   'Sync Log Summary',
  'contents':              'Contents',
  'description':           'Description',
  'lastModified':          'Last Modified',
  'size':                  'Size',
};

String _groupLabel(String raw) =>
    _kGroupLabels[raw] ?? _titleCase(raw.replaceAll('_', ' '));

String _fieldLabel(String key) =>
    _kFieldLabels[key] ?? _titleCase(key.replaceAll('_', ' '));

String _titleCase(String s) => s.isEmpty
    ? s
    : s.split(' ').map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}').join(' ');

String _fmtValue(String key, dynamic v) {
  if (v == null) return '—';
  if (v is DateTime) return _dateFmt.format(v.toLocal());
  final s = v.toString();
  if (s.isEmpty) return '—';
  // Humanise localisation-style keys: "system_log_description" → "System Log Description"
  if (RegExp(r'^[a-z][a-z0-9_]+$').hasMatch(s) && s.contains('_')) {
    return _titleCase(s.replaceAll('_', ' '));
  }
  return s;
}

// ─────────────────────────────────────────────────────────────────────────────
// Node helpers
// ─────────────────────────────────────────────────────────────────────────────

enum _NodeLevel { group, leaf }

String _nodeName(Map<String, dynamic> node) =>
    node['_name']?.toString() ?? 'Unknown';

List<Map<String, dynamic>> _leafChildren(Map<String, dynamic> group) {
  final raw = group['_items'];
  if (raw is List) return raw.whereType<Map<String, dynamic>>().toList();
  return [];
}

/// Returns the display-worthy scalar fields on a node (excludes _ keys and
/// keys whose values are non-scalar).
List<MapEntry<String, dynamic>> _scalarFields(Map<String, dynamic> node) {
  return node.entries.where((e) {
    if (e.key.startsWith('_')) return false;
    final v = e.value;
    return v is String || v is num || v is bool || v is DateTime;
  }).toList();
}

// ─────────────────────────────────────────────────────────────────────────────
// Public widget
// ─────────────────────────────────────────────────────────────────────────────

/// Two-pane Sync Services viewer.
/// Left: group → leaf tree.  Right: detail panel for the selected node.
class SyncServicesView extends StatefulWidget {
  final List<Map<String, dynamic>> items;

  const SyncServicesView({super.key, required this.items});

  @override
  State<SyncServicesView> createState() => _SyncServicesViewState();
}

class _SyncServicesViewState extends State<SyncServicesView> {
  Map<String, dynamic>? _selected;
  _NodeLevel _selectedLevel = _NodeLevel.group;

  final Set<int> _expanded = {};

  @override
  void initState() {
    super.initState();
    for (int i = 0; i < widget.items.length; i++) {
      _expanded.add(i);
    }
    if (widget.items.isNotEmpty) {
      _selected = widget.items.first;
      _selectedLevel = _NodeLevel.group;
    }
  }

  void _selectGroup(Map<String, dynamic> node) => setState(() {
        _selected = node;
        _selectedLevel = _NodeLevel.group;
      });

  void _selectLeaf(Map<String, dynamic> node) => setState(() {
        _selected = node;
        _selectedLevel = _NodeLevel.leaf;
      });

  void _toggleGroup(int idx) => setState(() {
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
        groups:        widget.items,
        selected:      _selected,
        expanded:      _expanded,
        onSelectGroup: _selectGroup,
        onSelectLeaf:  _selectLeaf,
        onToggleGroup: _toggleGroup,
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
          : _DetailPanel(node: _selected!, level: _selectedLevel),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tree panel
// ─────────────────────────────────────────────────────────────────────────────

class _TreePanel extends StatelessWidget {
  final List<Map<String, dynamic>> groups;
  final Map<String, dynamic>? selected;
  final Set<int> expanded;
  final ValueChanged<Map<String, dynamic>> onSelectGroup;
  final ValueChanged<Map<String, dynamic>> onSelectLeaf;
  final ValueChanged<int> onToggleGroup;

  const _TreePanel({
    required this.groups,
    required this.selected,
    required this.expanded,
    required this.onSelectGroup,
    required this.onSelectLeaf,
    required this.onToggleGroup,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      color: cs.surfaceContainerLow,
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: 6),
        children: [
          for (int i = 0; i < groups.length; i++)
            _GroupTile(
              groupIdx:      i,
              group:         groups[i],
              selected:      selected,
              isExpanded:    expanded.contains(i),
              onSelectGroup: onSelectGroup,
              onSelectLeaf:  onSelectLeaf,
              onToggle:      onToggleGroup,
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Group tile
// ─────────────────────────────────────────────────────────────────────────────

class _GroupTile extends StatelessWidget {
  final int groupIdx;
  final Map<String, dynamic> group;
  final Map<String, dynamic>? selected;
  final bool isExpanded;
  final ValueChanged<Map<String, dynamic>> onSelectGroup;
  final ValueChanged<Map<String, dynamic>> onSelectLeaf;
  final ValueChanged<int> onToggle;

  static const double _baseIndent  = 8.0;
  static const double _childIndent = 28.0;

  const _GroupTile({
    required this.groupIdx,
    required this.group,
    required this.selected,
    required this.isExpanded,
    required this.onSelectGroup,
    required this.onSelectLeaf,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs    = theme.colorScheme;
    final sp    = context.watch<UiScaleProvider>();

    final leaves     = _leafChildren(group);
    final isSelected = selected == group;
    final rowColor   = isSelected ? cs.primaryContainer : Colors.transparent;
    final labelColor = isSelected ? cs.onPrimaryContainer : cs.onSurface;
    final mutedColor = isSelected ? cs.onPrimaryContainer.withAlpha(180) : cs.onSurfaceVariant;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Group row ─────────────────────────────────────────────────────
        Material(
          color: rowColor,
          child: InkWell(
            onTap: () => onSelectGroup(group),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(_baseIndent, 4, 8, 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Chevron toggle.
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: leaves.isNotEmpty ? () => onToggle(groupIdx) : null,
                    child: SizedBox(
                      width: 20,
                      height: 28,
                      child: leaves.isNotEmpty
                          ? Icon(
                              isExpanded ? Icons.expand_more : Icons.chevron_right,
                              size: sp.sz(16),
                              color: mutedColor,
                            )
                          : null,
                    ),
                  ),

                  Icon(
                    Icons.folder_outlined,
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
                            _groupLabel(_nodeName(group)),
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                              color: labelColor,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (leaves.isNotEmpty)
                            Text(
                              '${leaves.length} item${leaves.length == 1 ? '' : 's'}',
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

        // ── Leaf children ─────────────────────────────────────────────────
        if (isExpanded)
          for (final leaf in leaves)
            _LeafTile(
              leaf:     leaf,
              selected: selected,
              onSelect: onSelectLeaf,
              indent:   _childIndent,
            ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Leaf tile
// ─────────────────────────────────────────────────────────────────────────────

class _LeafTile extends StatelessWidget {
  final Map<String, dynamic> leaf;
  final Map<String, dynamic>? selected;
  final ValueChanged<Map<String, dynamic>> onSelect;
  final double indent;

  const _LeafTile({
    required this.leaf,
    required this.selected,
    required this.onSelect,
    required this.indent,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs    = theme.colorScheme;
    final sp    = context.watch<UiScaleProvider>();

    final isSelected = selected == leaf;
    final rowColor   = isSelected ? cs.primaryContainer : Colors.transparent;
    final labelColor = isSelected ? cs.onPrimaryContainer : cs.onSurface;
    final mutedColor = isSelected ? cs.onPrimaryContainer.withAlpha(180) : cs.onSurfaceVariant;

    // Show size or last-modified as subtitle if available.
    String? subtitle;
    final size = leaf['size']?.toString();
    if (size != null && size.isNotEmpty) {
      subtitle = size;
    } else {
      final lm = leaf['lastModified'];
      if (lm is DateTime) subtitle = _dateFmt.format(lm.toLocal());
    }

    return Material(
      color: rowColor,
      child: InkWell(
        onTap: () => onSelect(leaf),
        child: Padding(
          padding: EdgeInsets.fromLTRB(indent, 3, 8, 3),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(width: 20),
              Icon(
                Icons.description_outlined,
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
                        _nodeName(leaf),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                          color: labelColor,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (subtitle != null)
                        Text(
                          subtitle,
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
    final cs    = theme.colorScheme;
    final sp    = context.watch<UiScaleProvider>();

    final rawName = _nodeName(node);
    final name    = level == _NodeLevel.group ? _groupLabel(rawName) : rawName;
    final icon    = level == _NodeLevel.group
        ? Icons.folder_outlined
        : Icons.description_outlined;

    // Separate "contents" (long text block) from scalar fields.
    final contentsRaw = node['contents'];
    final contents    = contentsRaw is String && contentsRaw.isNotEmpty
        ? contentsRaw
        : null;

    // Scalar fields, preferred order.
    const scalarOrder = <String>[
      'summary_os_version',
      'description',
      'lastModified',
      'size',
      'summary_of_sync_log',
    ];

    final fields = _scalarFields(node)
        .where((e) => e.key != 'contents')
        .toList();

    // Sort by preferred order; anything not listed goes at the end.
    fields.sort((a, b) {
      final ai = scalarOrder.indexOf(a.key);
      final bi = scalarOrder.indexOf(b.key);
      if (ai != -1 && bi != -1) return ai.compareTo(bi);
      if (ai != -1) return -1;
      if (bi != -1) return 1;
      return a.key.compareTo(b.key);
    });

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

        // ── Scalar fields ───────────────────────────────────────────────────
        if (fields.isNotEmpty)
          ...fields.map(
            (e) => _FieldRow(
              label: _fieldLabel(e.key),
              value: _fmtValue(e.key, e.value),
              theme: theme,
              cs:    cs,
            ),
          ),

        // ── Contents block ─────────────────────────────────────────────────
        if (contents != null) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
            child: Text(
              'Contents',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: cs.onSurface,
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
              child: Container(
                decoration: BoxDecoration(
                  color:        cs.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(6),
                  border:       Border.all(color: cs.outlineVariant),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(12),
                  child: SelectableText(
                    contents,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontFamily: 'monospace',
                      color:      cs.onSurface,
                      height:     1.5,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ] else
          const Spacer(),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Field row
// ─────────────────────────────────────────────────────────────────────────────

class _FieldRow extends StatelessWidget {
  final String label;
  final String value;
  final ThemeData theme;
  final ColorScheme cs;

  const _FieldRow({
    required this.label,
    required this.value,
    required this.theme,
    required this.cs,
  });

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 7, 20, 7),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 200,
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
