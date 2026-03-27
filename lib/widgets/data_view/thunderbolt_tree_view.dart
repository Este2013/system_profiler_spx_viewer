import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/ui_scale_provider.dart';
import '../../utils/key_formatter.dart';
import '../resizable_split.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Label overrides — covers both bare keys and their _key-suffixed variants
// ─────────────────────────────────────────────────────────────────────────────

const _kLabels = <String, String>{
  // Top-level bus / device fields
  'vendor_name_key':   'Vendor Name',   'vendor_name':   'Vendor Name',
  'device_name_key':   'Device Name',   'device_name':   'Device Name',
  'switch_uid_key':    'UID',           'switch_uid':    'UID',
  'route_string_key':  'Route String',  'route_string':  'Route String',
  'domain_uuid_key':   'Domain UUID',   'domain_uuid':   'Domain UUID',
  // Port (receptacle) sub-fields
  'receptacle_status_key': 'Status',        'receptacle_status': 'Status',
  'link_status_key':       'Link Status',   'link_status':       'Link Status',
  'current_speed_key':     'Speed',         'current_speed':     'Speed',
  'receptacle_id_key':     'Receptacle',    'receptacle_id':     'Receptacle',
};

/// Preferred display order for the top-level fields in the detail panel.
const _kDetailOrder = [
  'vendor_name_key', 'vendor_name',
  'device_name_key', 'device_name',
  'switch_uid_key',  'switch_uid',
  'route_string_key','route_string',
  'domain_uuid_key', 'domain_uuid',
];

/// Preferred order for Port (receptacle) sub-fields.
const _kPortOrder = [
  'receptacle_status_key', 'receptacle_status',
  'link_status_key',       'link_status',
  'current_speed_key',     'current_speed',
  'receptacle_id_key',     'receptacle_id',
];

// ─────────────────────────────────────────────────────────────────────────────
// Label helper
// ─────────────────────────────────────────────────────────────────────────────

String _tbLabel(String key) {
  if (_kLabels.containsKey(key)) return _kLabels[key]!;
  // Strip _key suffix and look up again.
  if (key.endsWith('_key')) {
    final bare = key.substring(0, key.length - 4);
    if (_kLabels.containsKey(bare)) return _kLabels[bare]!;
    return formatKey(bare);
  }
  return formatKey(key);
}

// ─────────────────────────────────────────────────────────────────────────────
// Value helper
// ─────────────────────────────────────────────────────────────────────────────

String _tbVal(dynamic v) {
  if (v == null) return '—';
  if (v is bool) return v ? 'Yes' : 'No';
  if (v is String) {
    switch (v) {
      case 'receptacle_no_devices_connected': return 'No device connected';
      case 'receptacle_connected':            return 'Connected';
      case 'receptacle_xdomain':              return 'XDomain Connection';
    }
    final f = formatSpxValue(v);
    return f.isEmpty ? '—' : f;
  }
  if (v is List) {
    if (v.isEmpty) return '—';
    if (v.every((e) => e is! Map && e is! List)) {
      return v.map((e) => _tbVal(e)).join(', ');
    }
    return '${v.length} item${v.length == 1 ? '' : 's'}';
  }
  if (v is Map) return '{${v.length} fields}';
  return v.toString();
}

// ─────────────────────────────────────────────────────────────────────────────
// Node helpers
// ─────────────────────────────────────────────────────────────────────────────

/// Formats the raw `_name` value into a readable bus / device name.
String _nodeName(Map<String, dynamic> node) {
  final raw = node['_name']?.toString() ?? 'Unknown Device';
  // thunderboltusb4_bus_N → "Thunderbolt/USB4 Bus N"
  final tbUsb4 = RegExp(r'^thunderboltusb4_bus_(\d+)$').firstMatch(raw);
  if (tbUsb4 != null) return 'Thunderbolt/USB4 Bus ${tbUsb4[1]}';
  // thunderbolt_bus_N → "Thunderbolt Bus N"
  final tb = RegExp(r'^thunderbolt_bus_(\d+)$').firstMatch(raw);
  if (tb != null) return 'Thunderbolt Bus ${tb[1]}';
  // usb4_bus_N → "USB4 Bus N"
  final usb4 = RegExp(r'^usb4_bus_(\d+)$').firstMatch(raw);
  if (usb4 != null) return 'USB4 Bus ${usb4[1]}';
  return formatKey(raw);
}

/// Stable identity key for expansion-state tracking.
String _nodeKey(Map<String, dynamic> node) {
  final uid = node['switch_uid_key'] ?? node['switch_uid'] ??
              node['uid_key']        ?? node['uid'] ??
              node['UID'];
  if (uid != null) return uid.toString();
  final route = node['route_string_key'] ?? node['route_string'];
  if (route != null) return '${_nodeName(node)}_$route';
  return '${_nodeName(node)}_${identityHashCode(node)}';
}

List<Map<String, dynamic>> _children(Map<String, dynamic> node) {
  final items = node['_items'];
  if (items is List) return items.whereType<Map<String, dynamic>>().toList();
  return [];
}

/// Returns the receptacle sub-entries sorted by receptacle number.
/// Keys have the form  receptacle_N_tag  (N ≥ 1).
List<MapEntry<String, dynamic>> _receptacleEntries(
    Map<String, dynamic> node) {
  final entries = node.entries
      .where((e) => RegExp(r'^receptacle_\d+_tag$').hasMatch(e.key))
      .toList()
    ..sort((a, b) {
        final na = int.tryParse(
            RegExp(r'\d+').firstMatch(a.key)?[0] ?? '0') ?? 0;
        final nb = int.tryParse(
            RegExp(r'\d+').firstMatch(b.key)?[0] ?? '0') ?? 0;
        return na.compareTo(nb);
      });
  return entries;
}

// ─────────────────────────────────────────────────────────────────────────────
// Public widget
// ─────────────────────────────────────────────────────────────────────────────

class ThunderboltTreeView extends StatefulWidget {
  final List<Map<String, dynamic>> items;
  const ThunderboltTreeView({super.key, required this.items});

  @override
  State<ThunderboltTreeView> createState() => _ThunderboltTreeViewState();
}

class _ThunderboltTreeViewState extends State<ThunderboltTreeView> {
  Map<String, dynamic>? _selected;
  final Set<String> _expanded = {};

  @override
  void initState() {
    super.initState();
    for (final item in widget.items) {
      _expanded.add(_nodeKey(item));
    }
    if (widget.items.isNotEmpty) _selected = widget.items.first;
  }

  void _select(Map<String, dynamic> node) =>
      setState(() => _selected = node);

  void _toggle(Map<String, dynamic> node) => setState(() {
        final k = _nodeKey(node);
        if (_expanded.contains(k)) {
          _expanded.remove(k);
        } else {
          _expanded.add(k);
        }
      });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ResizableSplit(
      left: _TreePanel(
        items: widget.items,
        selected: _selected,
        expanded: _expanded,
        onSelect: _select,
        onToggle: _toggle,
      ),
      right: _selected == null
          ? Center(
              child: Text(
                'Select a device',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: cs.onSurface.withAlpha(100),
                    ),
              ),
            )
          : _DetailPanel(node: _selected!),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tree panel
// ─────────────────────────────────────────────────────────────────────────────

class _TreePanel extends StatelessWidget {
  final List<Map<String, dynamic>> items;
  final Map<String, dynamic>? selected;
  final Set<String> expanded;
  final ValueChanged<Map<String, dynamic>> onSelect;
  final ValueChanged<Map<String, dynamic>> onToggle;

  const _TreePanel({
    required this.items,
    required this.selected,
    required this.expanded,
    required this.onSelect,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      color: cs.surfaceContainerLow,
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: 6),
        children: [
          for (final item in items)
            _NodeTile(
              node: item,
              isBus: true,
              depth: 0,
              selected: selected,
              expanded: expanded,
              onSelect: onSelect,
              onToggle: onToggle,
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Recursive node tile
// ─────────────────────────────────────────────────────────────────────────────

class _NodeTile extends StatelessWidget {
  final Map<String, dynamic> node;
  final bool isBus;
  final int depth;
  final Map<String, dynamic>? selected;
  final Set<String> expanded;
  final ValueChanged<Map<String, dynamic>> onSelect;
  final ValueChanged<Map<String, dynamic>> onToggle;

  const _NodeTile({
    required this.node,
    required this.isBus,
    required this.depth,
    required this.selected,
    required this.expanded,
    required this.onSelect,
    required this.onToggle,
  });

  static const double _indent = 14.0;
  static const double _baseIndent = 8.0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final sp = context.watch<UiScaleProvider>();

    final isSelected = selected == node;
    final isExpanded = expanded.contains(_nodeKey(node));
    final kids = _children(node);
    final hasKids = kids.isNotEmpty;

    // Subtitle: "Vendor · Device Name" or truncated UID.
    final vendor = (node['vendor_name_key'] ?? node['vendor_name'])?.toString();
    final devName = (node['device_name_key'] ?? node['device_name'])?.toString();
    final uid = (node['switch_uid_key'] ?? node['switch_uid'] ??
                 node['uid_key'] ?? node['uid'])?.toString();
    String? subtitle;
    final nm = _nodeName(node);
    if (vendor != null && devName != null &&
        vendor != nm && devName != nm) {
      subtitle = '$vendor · $devName';
    } else if (vendor != null && vendor != nm) {
      subtitle = vendor;
    } else if (uid != null) {
      subtitle = uid.length > 18 ? '${uid.substring(0, 18)}…' : uid;
    }

    final rowColor = isSelected ? cs.primaryContainer : Colors.transparent;
    final labelColor = isSelected ? cs.onPrimaryContainer : cs.onSurface;
    final mutedColor = isSelected
        ? cs.onPrimaryContainer.withAlpha(180)
        : cs.onSurfaceVariant;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Material(
          color: rowColor,
          child: InkWell(
            onTap: () => onSelect(node),
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                  _baseIndent + depth * _indent, 4, 8, 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: hasKids ? () => onToggle(node) : null,
                    child: SizedBox(
                      width: 20,
                      height: 28,
                      child: hasKids
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
                    isBus
                        ? Icons.device_hub
                        : hasKids
                            ? Icons.hub_outlined
                            : Icons.bolt,
                    size: sp.sz(15),
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
                            _nodeName(node),
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                              color: labelColor,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (subtitle != null)
                            Text(
                              subtitle,
                              style: theme.textTheme.bodySmall
                                  ?.copyWith(color: mutedColor),
                              overflow: TextOverflow.ellipsis,
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
        if (isExpanded && hasKids)
          for (final child in kids)
            _NodeTile(
              node: child,
              isBus: false,
              depth: depth + 1,
              selected: selected,
              expanded: expanded,
              onSelect: onSelect,
              onToggle: onToggle,
            ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Detail panel
// ─────────────────────────────────────────────────────────────────────────────

class _DetailPanel extends StatelessWidget {
  final Map<String, dynamic> node;
  const _DetailPanel({required this.node});

  static const double _keyW = 200.0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final sp = context.watch<UiScaleProvider>();
    final kids = _children(node);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Header ───────────────────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 10),
          decoration: BoxDecoration(
            border: Border(
                bottom: BorderSide(color: cs.outlineVariant, width: 0.5)),
          ),
          child: Row(
            children: [
              Icon(Icons.bolt, size: sp.sz(22), color: cs.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _nodeName(node),
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (kids.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: cs.secondaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${kids.length} ${kids.length == 1 ? 'device' : 'devices'}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: cs.onSecondaryContainer,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),
        ),

        // ── Fields ───────────────────────────────────────────────────────────
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            children: _buildRows(theme, cs),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildRows(ThemeData theme, ColorScheme cs) {
    final widgets = <Widget>[];
    final seen = <String>{};

    void addKv(String key, dynamic value) {
      widgets.add(_KvRow(
        label: _tbLabel(key),
        value: _tbVal(value),
        keyWidth: _keyW,
        theme: theme,
        cs: cs,
      ));
      widgets.add(Divider(height: 1, color: cs.outlineVariant.withAlpha(80)));
    }

    // 1. Preferred-order scalar fields.
    for (final key in _kDetailOrder) {
      if (!node.containsKey(key)) continue;
      if (seen.contains(key)) continue;
      seen.add(key);
      final v = node[key];
      if (v is! Map && v is! List) addKv(key, v);
    }

    // 2. Any remaining scalar fields not in the preferred order
    //    (skip receptacle_N_tag — handled below).
    for (final e in node.entries) {
      if (seen.contains(e.key)) continue;
      if (isInternalKey(e.key) || e.key == '_name') continue;
      if (RegExp(r'^receptacle_\d+_tag$').hasMatch(e.key)) continue;
      if (e.value is Map || e.value is List) continue;
      seen.add(e.key);
      addKv(e.key, e.value);
    }

    // Remove trailing divider before the port sections.
    if (widgets.isNotEmpty && widgets.last is Divider) {
      widgets.removeLast();
    }

    // 3. Receptacle / Port sub-sections (sorted by number).
    final receptacles = _receptacleEntries(node);
    final multiPort = receptacles.length > 1;
    for (final entry in receptacles) {
      // Port header — "Port" for a single port, "Port N" for multiple.
      final portNum = RegExp(r'\d+').firstMatch(entry.key)?[0] ?? '';
      final headerLabel = multiPort ? 'Port $portNum' : 'Port';

      if (widgets.isNotEmpty) widgets.add(const SizedBox(height: 4));
      widgets.add(_SubHeader(label: headerLabel, theme: theme, cs: cs));

      if (entry.value is Map) {
        final portMap = (entry.value as Map).cast<String, dynamic>();
        final portSeen = <String>{};

        // Preferred port field order.
        for (final key in _kPortOrder) {
          if (!portMap.containsKey(key)) continue;
          if (portSeen.contains(key)) continue;
          portSeen.add(key);
          widgets.add(_IndentKvRow(
            label: _tbLabel(key),
            value: _tbVal(portMap[key]),
            keyWidth: _keyW - 16,
            theme: theme,
            cs: cs,
          ));
        }
        // Remaining port fields.
        for (final pe in portMap.entries) {
          if (portSeen.contains(pe.key)) continue;
          if (isInternalKey(pe.key) || pe.key == '_name') continue;
          portSeen.add(pe.key);
          widgets.add(_IndentKvRow(
            label: _tbLabel(pe.key),
            value: _tbVal(pe.value),
            keyWidth: _keyW - 16,
            theme: theme,
            cs: cs,
          ));
        }
      }
    }

    return widgets;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// KV row widgets
// ─────────────────────────────────────────────────────────────────────────────

class _KvRow extends StatelessWidget {
  final String label;
  final String value;
  final double keyWidth;
  final ThemeData theme;
  final ColorScheme cs;

  const _KvRow({
    required this.label,
    required this.value,
    required this.keyWidth,
    required this.theme,
    required this.cs,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
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
            child: SelectableText(value,
                style: theme.textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}

class _IndentKvRow extends StatelessWidget {
  final String label;
  final String value;
  final double keyWidth;
  final ThemeData theme;
  final ColorScheme cs;

  const _IndentKvRow({
    required this.label,
    required this.value,
    required this.keyWidth,
    required this.theme,
    required this.cs,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, top: 4, bottom: 4),
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
            child: SelectableText(value,
                style: theme.textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}

class _SubHeader extends StatelessWidget {
  final String label;
  final ThemeData theme;
  final ColorScheme cs;

  const _SubHeader({
    required this.label,
    required this.theme,
    required this.cs,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 4),
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
