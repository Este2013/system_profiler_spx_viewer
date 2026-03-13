import 'package:flutter/material.dart';
import '../../utils/key_formatter.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Node-type helpers
// ─────────────────────────────────────────────────────────────────────────────

enum _NodeType { bus, hub, device }

/// Derives the node type.
/// Top-level items are buses; nodes with non-empty `_items` are hubs;
/// everything else is a leaf device.
_NodeType _detectType(Map<String, dynamic> node, {bool topLevel = false}) {
  if (topLevel) return _NodeType.bus;
  final items = node['_items'];
  if (items is List && items.isNotEmpty) return _NodeType.hub;
  return _NodeType.device;
}

/// Stable identity key for a node — prefers the USB location ID.
String _nodeKey(Map<String, dynamic> node) {
  final loc = node['USBDeviceKeyLocationID'] ??
      node['USBKeyLocationID'] ??
      node['_name'];
  return loc?.toString() ?? identityHashCode(node).toString();
}

String _nodeName(Map<String, dynamic> node) =>
    node['_name']?.toString() ?? 'Unknown Device';

/// Returns the direct children of a node (the `_items` list).
List<Map<String, dynamic>> _children(Map<String, dynamic> node) {
  final items = node['_items'];
  if (items is List) {
    return items.whereType<Map<String, dynamic>>().toList();
  }
  return [];
}

// ─────────────────────────────────────────────────────────────────────────────
// Public widget
// ─────────────────────────────────────────────────────────────────────────────

/// Two-pane USB tree viewer.
/// Left: collapsible device tree; Right: detail panel for the selected node.
class UsbTreeView extends StatefulWidget {
  /// The top-level USB controller/bus items from the section.
  final List<Map<String, dynamic>> buses;

  const UsbTreeView({super.key, required this.buses});

  @override
  State<UsbTreeView> createState() => _UsbTreeViewState();
}

class _UsbTreeViewState extends State<UsbTreeView> {
  Map<String, dynamic>? _selected;

  /// Keys of currently expanded nodes.
  final Set<String> _expanded = {};

  @override
  void initState() {
    super.initState();
    // Expand all top-level buses by default.
    for (final bus in widget.buses) {
      _expanded.add(_nodeKey(bus));
    }
    // Pre-select the first bus so the detail panel is never blank.
    if (widget.buses.isNotEmpty) _selected = widget.buses.first;
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
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Tree panel ────────────────────────────────────────────────────
        SizedBox(
          width: 310,
          child: _TreePanel(
            buses: widget.buses,
            selected: _selected,
            expanded: _expanded,
            onSelect: _select,
            onToggle: _toggle,
          ),
        ),

        VerticalDivider(
          width: 1,
          thickness: 1,
          color: cs.outlineVariant,
        ),

        // ── Detail panel ──────────────────────────────────────────────────
        Expanded(
          child: _selected == null
              ? Center(
                  child: Text(
                    'Select a device',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: cs.onSurface.withAlpha(100),
                        ),
                  ),
                )
              : _DetailPanel(node: _selected!),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tree panel
// ─────────────────────────────────────────────────────────────────────────────

class _TreePanel extends StatelessWidget {
  final List<Map<String, dynamic>> buses;
  final Map<String, dynamic>? selected;
  final Set<String> expanded;
  final ValueChanged<Map<String, dynamic>> onSelect;
  final ValueChanged<Map<String, dynamic>> onToggle;

  const _TreePanel({
    required this.buses,
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
          for (final bus in buses)
            _NodeTile(
              node: bus,
              type: _NodeType.bus,
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
  final _NodeType type;
  final int depth;
  final Map<String, dynamic>? selected;
  final Set<String> expanded;
  final ValueChanged<Map<String, dynamic>> onSelect;
  final ValueChanged<Map<String, dynamic>> onToggle;

  const _NodeTile({
    required this.node,
    required this.type,
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
    final isSelected = selected == node;
    final isExpanded = expanded.contains(_nodeKey(node));
    final kids = _children(node);
    final hasKids = kids.isNotEmpty;

    // Build a subtitle from USB metadata keys.
    final speed = node['USBDeviceKeyLinkSpeed']?.toString() ??
        node['USBKeyLinkSpeed']?.toString();
    final vendor = node['USBDeviceKeyVendorName']?.toString() ??
        node['USBDeviceKeyManufacturerStringIndex']?.toString();
    final subtitle = [if (vendor != null) vendor, if (speed != null) speed]
        .join(' · ')
        .nullIfEmpty();

    final rowColor = isSelected ? cs.primaryContainer : Colors.transparent;
    final labelColor =
        isSelected ? cs.onPrimaryContainer : cs.onSurface;
    final mutedColor =
        isSelected ? cs.onPrimaryContainer.withAlpha(180) : cs.onSurfaceVariant;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Row ────────────────────────────────────────────────────────────
        Material(
          color: rowColor,
          child: InkWell(
            // Tapping the row body selects the node.
            onTap: () => onSelect(node),
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                _baseIndent + depth * _indent,
                4,
                8,
                4,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Chevron – separate tap area that ONLY toggles.
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
                              size: 16,
                              color: mutedColor,
                            )
                          : null,
                    ),
                  ),

                  // Node icon.
                  Icon(
                    _iconFor(type),
                    size: 15,
                    color: isSelected ? cs.primary : cs.onSurfaceVariant,
                  ),
                  const SizedBox(width: 7),

                  // Name + subtitle.
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
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: mutedColor,
                              ),
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

        // ── Children (recursive) ───────────────────────────────────────────
        if (isExpanded && hasKids)
          for (final child in kids)
            _NodeTile(
              node: child,
              type: _detectType(child),
              depth: depth + 1,
              selected: selected,
              expanded: expanded,
              onSelect: onSelect,
              onToggle: onToggle,
            ),
      ],
    );
  }

  static IconData _iconFor(_NodeType t) {
    switch (t) {
      case _NodeType.bus:
        return Icons.device_hub;
      case _NodeType.hub:
        return Icons.hub_outlined;
      case _NodeType.device:
        return Icons.usb;
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Detail panel
// ─────────────────────────────────────────────────────────────────────────────

class _DetailPanel extends StatelessWidget {
  final Map<String, dynamic> node;
  const _DetailPanel({required this.node});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    // Collect displayable fields – skip internal/metadata keys and _items.
    final fields = node.entries
        .where((e) => !isInternalKey(e.key))
        .toList();

    // Determine node icon based on whether it has children.
    final kids = _children(node);
    final nodeType = kids.isNotEmpty ? _NodeType.hub : _NodeType.device;
    final icon = nodeType == _NodeType.hub
        ? Icons.hub_outlined
        : Icons.usb;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Header ─────────────────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 10),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: cs.outlineVariant, width: 0.5),
            ),
          ),
          child: Row(
            children: [
              Icon(icon, size: 22, color: cs.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _nodeName(node),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (kids.isNotEmpty)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
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

        // ── Field list ─────────────────────────────────────────────────────
        Expanded(
          child: fields.isEmpty
              ? Center(
                  child: Text(
                    'No details available',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: cs.onSurface.withAlpha(100),
                    ),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  itemCount: fields.length,
                  separatorBuilder: (_, __) => Divider(
                    height: 1,
                    color: cs.outlineVariant.withAlpha(80),
                    indent: 20,
                    endIndent: 20,
                  ),
                  itemBuilder: (context, i) {
                    final e = fields[i];
                    return _FieldRow(
                      label: formatUsbKey(e.key),
                      value: _renderValue(e.value),
                    );
                  },
                ),
        ),
      ],
    );
  }

  /// Converts a dynamic value to a human-readable string for the detail panel.
  String _renderValue(dynamic v) {
    if (v == null) return '—';
    if (v is bool) return v ? 'Yes' : 'No';
    if (v is List) {
      if (v.isEmpty) return '—';
      return v.map(_renderValue).join(', ');
    }
    if (v is Map) {
      // Flatten small maps into "Key: Value; …" form.
      if (v.isEmpty) return '—';
      return v.entries
          .take(4)
          .map((e) => '${formatUsbKey(e.key.toString())}: ${_renderValue(e.value)}')
          .join('; ');
    }
    return v.toString();
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _FieldRow extends StatelessWidget {
  final String label;
  final String value;

  const _FieldRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 190,
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: cs.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(width: 12),
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

// ─────────────────────────────────────────────────────────────────────────────
// Small String extension helper
// ─────────────────────────────────────────────────────────────────────────────

extension _StringX on String {
  String? nullIfEmpty() => isEmpty ? null : this;
}
