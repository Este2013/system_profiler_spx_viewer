import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../providers/ui_scale_provider.dart';
import '../../utils/key_formatter.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Label overrides & display order for spethernet_* keys
// ─────────────────────────────────────────────────────────────────────────────

const _kLabels = <String, String>{
  'spethernet_bus':                   'Bus',
  'spethernet_vendor-id':             'Vendor ID',
  'spethernet_device-id':             'Device ID',
  'spethernet_subsystem-vendor-id':   'Subsystem Vendor ID',
  'spethernet_subsystem-id':          'Subsystem ID',
  'spethernet_revision-id':           'Revision ID',
  'spethernet_pcie-link-speed':       'PCIe Link Speed',
  'spethernet_pcie-link-width':       'PCIe Link Width',
  'spethernet_driver':                'Driver',
  'spethernet_bsd-device-name':       'BSD Device Name',
  'spethernet_mac-address':           'MAC Address',
  'spethernet_avb-support':           'AVB Support',
  'spethernet_max-link-speed':        'Maximum Link Speed',
  // Underscore variants (defensive)
  'spethernet_vendor_id':             'Vendor ID',
  'spethernet_device_id':             'Device ID',
  'spethernet_subsystem_vendor_id':   'Subsystem Vendor ID',
  'spethernet_subsystem_id':          'Subsystem ID',
  'spethernet_revision_id':           'Revision ID',
  'spethernet_pcie_link_speed':       'PCIe Link Speed',
  'spethernet_pcie_link_width':       'PCIe Link Width',
  'spethernet_bsd_device_name':       'BSD Device Name',
  'spethernet_mac_address':           'MAC Address',
  'spethernet_avb_support':           'AVB Support',
  'spethernet_max_link_speed':        'Maximum Link Speed',
  // Mixed underscore/hyphen variants (actual keys observed in SPX files)
  'spethernet_pcie_link-speed':       'PCIe Link Speed',
  'spethernet_pcie_link-width':       'PCIe Link Width',
  // Mixed-case variant (actual key observed in SPX files)
  'spethernet_BSD_Device_Name':       'BSD Device Name',
};

/// Preferred field order (raw key names).
const _kOrder = [
  'spethernet_bus',
  'spethernet_vendor-id',             'spethernet_vendor_id',
  'spethernet_device-id',             'spethernet_device_id',
  'spethernet_subsystem-vendor-id',   'spethernet_subsystem_vendor_id',
  'spethernet_subsystem-id',          'spethernet_subsystem_id',
  'spethernet_revision-id',           'spethernet_revision_id',
  'spethernet_pcie-link-speed',       'spethernet_pcie_link_speed',       'spethernet_pcie_link-speed',
  'spethernet_pcie-link-width',       'spethernet_pcie_link_width',       'spethernet_pcie_link-width',
  'spethernet_bsd-device-name',       'spethernet_bsd_device_name',       'spethernet_BSD_Device_Name',
  'spethernet_mac-address',           'spethernet_mac_address',
  'spethernet_avb-support',           'spethernet_avb_support',
  'spethernet_max-link-speed',        'spethernet_max_link_speed',
  'spethernet_driver',
];

/// Human-readable label for an Ethernet key.
/// Falls back to stripping the spethernet_ prefix and cleaning up hyphens.
String _labelFor(String key) {
  if (_kLabels.containsKey(key)) return _kLabels[key]!;
  const prefix = 'spethernet_';
  if (key.startsWith(prefix)) {
    return key
        .substring(prefix.length)
        .replaceAll('-', ' ')
        .replaceAll('_', ' ')
        .split(' ')
        .where((w) => w.isNotEmpty)
        .map((w) => w[0].toUpperCase() + w.substring(1))
        .join(' ');
  }
  return formatKey(key);
}

// ─────────────────────────────────────────────────────────────────────────────
// Public widget
// ─────────────────────────────────────────────────────────────────────────────

/// Renders [SPEthernetDataType] items matching the macOS layout:
///
///   Broadcom 57762-A0
///     Bus                  PCI
///     Vendor ID            0x14e4
///     …
///
/// Supports multiple adapters (each shown as a collapsible named section).
class EthernetView extends StatefulWidget {
  final List<Map<String, dynamic>> items;
  final String searchQuery;

  const EthernetView({
    super.key,
    required this.items,
    this.searchQuery = '',
  });

  @override
  State<EthernetView> createState() => _EthernetViewState();
}

class _EthernetViewState extends State<EthernetView> {
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

        // ── Device list ──────────────────────────────────────────────────────
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            itemCount: widget.items.length,
            itemBuilder: (context, i) => _EthernetDeviceSection(
              item: widget.items[i],
              searchQuery: _q,
              showDivider: i < widget.items.length - 1,
              startExpanded: true,
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Per-device collapsible section
// ─────────────────────────────────────────────────────────────────────────────

class _EthernetDeviceSection extends StatefulWidget {
  final Map<String, dynamic> item;
  final String searchQuery;
  final bool showDivider;
  final bool startExpanded;

  const _EthernetDeviceSection({
    required this.item,
    required this.searchQuery,
    required this.showDivider,
    required this.startExpanded,
  });

  @override
  State<_EthernetDeviceSection> createState() =>
      _EthernetDeviceSectionState();
}

class _EthernetDeviceSectionState extends State<_EthernetDeviceSection>
    with SingleTickerProviderStateMixin {
  bool _expanded = true;

  late final AnimationController _animCtrl;
  late final Animation<double> _sizeFactor;
  late final Animation<double> _chevronTurns;

  @override
  void initState() {
    super.initState();
    _expanded = widget.startExpanded;
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
      value: _expanded ? 1.0 : 0.0,
    );
    _sizeFactor =
        CurvedAnimation(parent: _animCtrl, curve: Curves.easeInOut);
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
  void didUpdateWidget(_EthernetDeviceSection old) {
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

    final deviceName =
        widget.item['_name']?.toString() ?? 'Ethernet Adapter';

    // Build ordered + filtered property rows
    final rows = _buildRows(context, widget.item, widget.searchQuery, sp,
        theme, cs);

    // Hide entirely if filter matches nothing
    if (widget.searchQuery.isNotEmpty && rows.isEmpty &&
        !deviceName.toLowerCase()
            .contains(widget.searchQuery.toLowerCase())) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Header ─────────────────────────────────────────────────────────
          InkWell(
            onTap: _toggle,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
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
                      deviceName,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: cs.onSurface,
                      ),
                    ),
                  ),
                  if (!_expanded)
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
          SizeTransition(
            sizeFactor: _sizeFactor,
            child: Padding(
              padding: const EdgeInsets.only(left: 0, bottom: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: rows,
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

  List<Widget> _buildRows(
    BuildContext context,
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
      if (key == '_name') return; // shown as section header
      final label = _labelFor(key);
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

    // 1. Render fields in preferred order
    for (final key in _kOrder) {
      if (!item.containsKey(key)) continue;
      if (seen.contains(key)) continue;
      seen.add(key);
      addRow(key, item[key]);
    }

    // 2. Append any remaining unknown / future fields
    for (final e in item.entries) {
      if (seen.contains(e.key)) continue;
      seen.add(e.key);
      addRow(e.key, e.value);
    }

    return rows;
  }

  String _fmtVal(dynamic v) {
    if (v == null) return '—';
    if (v is bool) return v ? 'Yes' : 'No';
    if (v is DateTime) {
      return DateFormat('yyyy-MM-dd  HH:mm:ss').format(v.toLocal());
    }
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
// Search highlight text
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
