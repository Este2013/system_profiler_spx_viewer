import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../providers/ui_scale_provider.dart';
import '../../utils/key_formatter.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Section-name overrides — maps raw `_name` values to human-readable headers
// ─────────────────────────────────────────────────────────────────────────────

const _kSectionNames = <String, String>{
  // System power settings (desktop / portable)
  'sppower_information':                  'System Power Settings',
  'sppower_power_settings':               'System Power Settings',
  'sppower_battery_model_info':           'Battery Information',
  'sppower_battery_charge_info':          'Battery Charge Information',
  'sppower_battery_health_info':          'Battery Health Information',
  'sppower_battery_cycle_count_info':     'Battery Cycle Count',
  'sppower_charge_info':                  'Charge Information',
  'sppower_health_info':                  'Condition Information',
  'sppower_hw_data':                      'Hardware Configuration',
  'sppower_hardware_configuration':       'Hardware Configuration',
  'sppower_hwconfig_information':         'Hardware Configuration',
  'sppower_ac_charger_information':       'AC Charger Information',
  'sppower_accharger_information':        'AC Charger Information',
  'sppower_ups_information':              'UPS Information',
  'sppower_ups_data':                     'UPS',
};

String _formatSectionName(String raw) =>
    _kSectionNames[raw] ?? formatKey(raw);

// ─────────────────────────────────────────────────────────────────────────────
// Key-label overrides — for coded sppower_* keys
// ─────────────────────────────────────────────────────────────────────────────

const _kKeyLabels = <String, String>{
  // System sleep settings
  'sppower_sleep_timer':                      'System Sleep Timer (Minutes)',
  'sppower_disk_sleep_timer':                 'Disk Sleep Timer (Minutes)',
  'sppower_display_sleep_timer':              'Display Sleep Timer (Minutes)',
  'sppower_sleep_button':                     'Sleep on Power Button',
  'sppower_restart_on_power_loss':            'Automatic Restart on Power Loss',
  'sppower_wake_on_lan':                      'Wake on LAN',
  'sppower_current_power_source':             'Current Power Source',
  'sppower_reduce_brightness':                'Reduce Brightness',
  'sppower_network_access_over_sleep':        'Prioritise Network Reachability Over Sleep',
  'sppower_hibernate_mode':                   'Hibernate Mode',
  'sppower_standby_delay':                    'Standby Delay',
  'sppower_standby':                          'Standby',
  'sppower_autopoweroff':                     'Auto Power Off',
  'sppower_autopoweroff_delay':               'Auto Power Off Delay',
  // Hardware configuration
  'sppower_ups_installed':                    'UPS Installed',
  // AC charger — both prefix variants (sppower_charger_* and sppower_ac_charger_*)
  'sppower_charger_connected':                'Connected',
  'sppower_charger_id':                       'ID',
  'sppower_charger_wattage':                  'Wattage (W)',
  'sppower_charger_family':                   'Family',
  'sppower_charger_manufacturer':             'Manufacturer',
  'sppower_charger_serial':                   'Serial Number',
  'sppower_ac_charger_connected':             'Connected',
  'sppower_ac_charger_id':                    'ID',
  'sppower_ac_charger_wattage':               'Wattage (W)',
  'sppower_ac_charger_family':                'Family',
  'sppower_ac_charger_manufacturer':          'Manufacturer',
  'sppower_ac_charger_serial':                'Serial Number',
  // Battery
  'sppower_battery_remaining_capacity':       'Remaining Capacity (mAh)',
  'sppower_battery_full_charge_capacity':     'Full Charge Capacity (mAh)',
  'sppower_battery_design_capacity':          'Design Capacity (mAh)',
  'sppower_battery_cell_disconnect_count':    'Cell Disconnect Count',
  'sppower_battery_cycle_count':              'Cycle Count',
  'sppower_battery_status':                   'Condition',
  'sppower_battery_charging':                 'Charging',
  'sppower_battery_permanent_failure':        'Permanent Failure',
  'sppower_battery_serial_number':            'Serial Number',
  'sppower_battery_manufacturer':             'Manufacturer',
  'sppower_device_name':                      'Device Name',
  'sppower_battery_current_capacity':         'State of Charge (%)',
  'sppower_is_charged':                       'Fully Charged',
  'sppower_is_charging':                      'Charging',
  'sppower_external_connected':               'AC Charger Connected',
  'sppower_external_charge_capable':          'Charge Capable',
};

String _fmtKey(String key) =>
    _kKeyLabels[key] ?? formatKey(key);

// ─────────────────────────────────────────────────────────────────────────────
// Value formatter
// ─────────────────────────────────────────────────────────────────────────────

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

// ─────────────────────────────────────────────────────────────────────────────
// Filter helpers
// ─────────────────────────────────────────────────────────────────────────────

bool _scalarMatchesQ(String q, String label, dynamic value) {
  final lower = q.toLowerCase();
  if (label.toLowerCase().contains(lower)) return true;
  if (value is! Map && value is! List) {
    return _fmtVal(value).toLowerCase().contains(lower);
  }
  return false;
}

bool _itemMatchesQ(String q, Map<String, dynamic> item) {
  final name = _formatSectionName(item['_name']?.toString() ?? '');
  if (name.toLowerCase().contains(q.toLowerCase())) return true;
  for (final e in item.entries) {
    if (isInternalKey(e.key)) continue;
    if (e.value is Map) {
      final sub = (e.value as Map).cast<String, dynamic>();
      final subHeader = _fmtKey(e.key);
      if (subHeader.toLowerCase().contains(q.toLowerCase())) return true;
      for (final se in sub.entries) {
        if (isInternalKey(se.key)) continue;
        if (_scalarMatchesQ(q, _fmtKey(se.key), se.value)) return true;
      }
    } else {
      if (_scalarMatchesQ(q, _fmtKey(e.key), e.value)) return true;
    }
  }
  return false;
}

// ─────────────────────────────────────────────────────────────────────────────
// Public widget
// ─────────────────────────────────────────────────────────────────────────────

/// Renders [SPPowerDataType] matching the macOS System Information layout:
///
///   System Power Settings
///     AC Power
///       System Sleep Timer (Minutes)   1
///       …
///   Hardware Configuration
///     UPS Installed                    No
///   AC Charger Information
///     Family                           0x0000
///
/// Each top-level item is a collapsible section. Map-valued entries within an
/// item are rendered as a non-collapsible sub-section header.
class PowerView extends StatefulWidget {
  final List<Map<String, dynamic>> items;
  final String searchQuery;

  const PowerView({
    super.key,
    required this.items,
    this.searchQuery = '',
  });

  @override
  State<PowerView> createState() => _PowerViewState();
}

class _PowerViewState extends State<PowerView> {
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
    final q = _q;

    final visibleItems = widget.items
        .where((item) => q.isEmpty || _itemMatchesQ(q, item))
        .toList();

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

        // ── Sections ─────────────────────────────────────────────────────────
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            itemCount: visibleItems.length,
            itemBuilder: (context, i) => _PowerSection(
              item: visibleItems[i],
              searchQuery: q,
              showDivider: i < visibleItems.length - 1,
              startExpanded: true,
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Collapsible section for one power item
// ─────────────────────────────────────────────────────────────────────────────

class _PowerSection extends StatefulWidget {
  final Map<String, dynamic> item;
  final String searchQuery;
  final bool showDivider;
  final bool startExpanded;

  const _PowerSection({
    required this.item,
    required this.searchQuery,
    required this.showDivider,
    required this.startExpanded,
  });

  @override
  State<_PowerSection> createState() => _PowerSectionState();
}

class _PowerSectionState extends State<_PowerSection>
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
  void didUpdateWidget(_PowerSection old) {
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

    final sectionName =
        _formatSectionName(widget.item['_name']?.toString() ?? 'Power');

    final rows = _buildRows(context, widget.item, widget.searchQuery, sp,
        theme, cs);

    // Hide entirely when nothing matches
    if (widget.searchQuery.isNotEmpty && rows.isEmpty &&
        !sectionName.toLowerCase()
            .contains(widget.searchQuery.toLowerCase())) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Section header ────────────────────────────────────────────────
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
                      sectionName,
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

          // ── Animated body ─────────────────────────────────────────────────
          SizeTransition(
            sizeFactor: _sizeFactor,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 4),
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

  /// Indent per level in unscaled logical pixels.
  static const double _indentStep = 20.0;
  /// Key-column width at the top-most content level (no indent).
  static const double _keyBase = 300.0;

  List<Widget> _buildRows(
    BuildContext context,
    Map<String, dynamic> item,
    String q,
    UiScaleProvider sp,
    ThemeData theme,
    ColorScheme cs,
  ) {
    final rows = <Widget>[];
    final keyW0 = sp.sz(_keyBase);

    for (final e in item.entries) {
      if (isInternalKey(e.key)) continue;
      if (e.key == '_name') continue; // already shown as the section header

      final label = _fmtKey(e.key);

      if (e.value is Map) {
        // ── Sub-section (e.g. "AC Power") ────────────────────────────────────
        final sub = (e.value as Map).cast<String, dynamic>();

        // Filter: skip sub-section if nothing inside it matches
        if (q.isNotEmpty) {
          final headerMatches = label.toLowerCase().contains(q.toLowerCase());
          final anyRowMatches = sub.entries.any((se) {
            if (isInternalKey(se.key)) return false;
            if (se.key == '_name') return false;
            return _scalarMatchesQ(q, _fmtKey(se.key), se.value);
          });
          if (!headerMatches && !anyRowMatches) continue;
        }

        // Sub-section header
        rows.add(_SubHeader(label: label, theme: theme, cs: cs));

        // KV rows inside the sub-section
        final indent = sp.sz(_indentStep);
        final keyW = (sp.sz(_keyBase) - indent).clamp(60.0, double.infinity);
        for (final se in sub.entries) {
          if (isInternalKey(se.key)) continue;
          if (se.key == '_name') continue;
          final subLabel = _fmtKey(se.key);
          final subVal = _fmtVal(se.value);
          if (q.isNotEmpty &&
              !_scalarMatchesQ(q, subLabel, se.value)) continue;
          rows.add(_KvRow(
            label: subLabel,
            value: subVal,
            indent: indent,
            keyWidth: keyW,
            searchQuery: q,
            theme: theme,
            cs: cs,
          ));
        }
      } else {
        // ── Scalar KV row ─────────────────────────────────────────────────
        final val = _fmtVal(e.value);
        if (q.isNotEmpty && !_scalarMatchesQ(q, label, e.value)) continue;
        rows.add(_KvRow(
          label: label,
          value: val,
          indent: 0,
          keyWidth: keyW0,
          searchQuery: q,
          theme: theme,
          cs: cs,
        ));
      }
    }

    return rows;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sub-section header  (e.g. "AC Power")
// ─────────────────────────────────────────────────────────────────────────────

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
      padding: const EdgeInsets.fromLTRB(4, 10, 0, 4),
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

// ─────────────────────────────────────────────────────────────────────────────
// Key-value row
// ─────────────────────────────────────────────────────────────────────────────

class _KvRow extends StatelessWidget {
  final String label;
  final String value;
  final double indent;
  final double keyWidth;
  final String searchQuery;
  final ThemeData theme;
  final ColorScheme cs;

  const _KvRow({
    required this.label,
    required this.value,
    required this.indent,
    required this.keyWidth,
    required this.searchQuery,
    required this.theme,
    required this.cs,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: indent, top: 5, bottom: 5),
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
