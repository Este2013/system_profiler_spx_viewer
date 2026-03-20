import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/ui_scale_provider.dart';
import '../../utils/key_formatter.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Label overrides for SPHardwareDataType keys
// ─────────────────────────────────────────────────────────────────────────────

const _kLabels = <String, String>{
  // Machine identity
  'machine_name':           'Model Name',
  'machine_model':          'Model Identifier',
  'model_number':           'Model Number',
  // Processor (Apple Silicon)
  'chip_type':              'Chip',
  'number_processors':      'Total Number of Cores',
  // Processor (Intel / AMD legacy)
  'cpu_type':               'Processor Name',
  'current_processor_speed':'Processor Speed',
  'number_cpus':            'Number of Processors',
  'cores_per_package':      'Total Number of Cores',
  'packages':               'Packages',
  'l2_cache':               'L2 Cache',
  'l2_cache_core':          'L2 Cache (per core)',
  'l2_cache_share':         'L2 Cache (shared)',
  'l2_cache_size':          'L2 Cache',
  'l3_cache':               'L3 Cache',
  'l3_cache_processor':     'L3 Cache (per processor)',
  'l3_cache_size':          'L3 Cache',
  'maximum_processor_speed':'Maximum Processor Speed',
  'minimum_processor_speed':'Minimum Processor Speed',
  'cpu_interconnect_speed': 'Processor Interconnect Speed',
  'bus_speed':              'Bus Speed',
  'platform_cpu_vendor':    'Processor Vendor',
  'platform_cpu_htt':       'Hyper-Threading',
  'platform_cpu_features':  'CPU Features',
  // Memory
  'physical_memory':        'Memory',
  // Firmware
  'boot_rom_version':       'System Firmware Version',
  'boot_rom_release_date':  'Firmware Release Date',
  'boot_rom_vendor':        'Firmware Vendor',
  'apple_rom_info':         'ROM Information',
  'os_loader_version':      'OS Loader Version',
  // Identity / serial
  'serial_number':          'Serial Number (system)',
  'riser_serial_number':    'Riser Serial Number',
  'sales_order_number':     'Order Number',
  // UUIDs  — platform_UUID → "Hardware UUID" as shown in macOS
  'platform_UUID':          'Hardware UUID',
  'provisioning_UDID':      'Provisioning UDID',
  // Misc
  'activation_lock_status': 'Activation Lock Status',
  'enclosure':              'Enclosure',
  'platform_manufacturer':  'Manufacturer',
  'platform_product_name':  'Product Name',
  'platform_version':       'Platform Version',
};

/// Preferred display order (macOS System Information order).
const _kOrder = [
  'machine_name',
  'machine_model',
  'model_number',
  // Apple Silicon path
  'chip_type',
  'number_processors',
  // Intel / AMD path
  'cpu_type',
  'current_processor_speed',
  'minimum_processor_speed',
  'maximum_processor_speed',
  'number_cpus',
  'cores_per_package',
  'packages',
  'l2_cache', 'l2_cache_core', 'l2_cache_share', 'l2_cache_size',
  'l3_cache', 'l3_cache_processor', 'l3_cache_size',
  'cpu_interconnect_speed',
  'bus_speed',
  'platform_cpu_vendor',
  'platform_cpu_htt',
  'platform_cpu_features',
  // Memory
  'physical_memory',
  // Firmware
  'boot_rom_version',
  'boot_rom_release_date',
  'boot_rom_vendor',
  'apple_rom_info',
  'os_loader_version',
  // Serial / identity
  'serial_number',
  'riser_serial_number',
  'sales_order_number',
  'platform_UUID',
  'provisioning_UDID',
  'activation_lock_status',
  // Low-priority misc
  'enclosure',
  'platform_manufacturer',
  'platform_product_name',
  'platform_version',
];

// ─────────────────────────────────────────────────────────────────────────────
// Label + value helpers
// ─────────────────────────────────────────────────────────────────────────────

String _labelFor(String key) {
  if (_kLabels.containsKey(key)) return _kLabels[key]!;
  return formatKey(key);
}

/// Formats the `number_processors` value from Apple Silicon SPX format.
///
/// Only handles the `"proc X:Y:Z"` / `"proc X:Y:Z:O"` encoding emitted by
/// system_profiler for Apple Silicon Macs.  Zero counts are omitted.
///
///   "proc 8:4:4"     → "8 (4 Performance and 4 Efficiency)"
///   "proc 12:8:4"    → "12 (8 Performance and 4 Efficiency)"
///   "proc 24:16:4:4" → "24 (16 Performance, 4 Efficiency and 4 Other)"
///   "proc 4"         → "4"           (Intel: plain total, no split)
///   8  (int)         → "8"           (Intel XML integer value)
///   "8 (4 Performance and 4 Efficiency)" → passed through unchanged
///
/// Any string that doesn't start with "proc " is returned as-is so that
/// already-formatted values (some macOS versions emit these directly) and
/// any future formats survive without garbling.
String _formatProcessors(dynamic raw) {
  // Integer (Intel XML) → plain string
  if (raw is int) return raw.toString();

  final input = raw.toString();

  // Only attempt parsing if the value starts with "proc "
  if (!input.startsWith('proc ')) return input;

  final s     = input.substring(5).trim(); // drop "proc "
  final parts = s.split(':').map((p) => int.tryParse(p.trim())).toList();

  // Need at least total + one segment; all parts must be valid integers
  if (parts.length < 2 || parts.any((p) => p == null)) return input;

  final total = parts[0]!;

  // Build a list of "(count Label)" strings, skipping zeros
  final labels = ['Performance', 'Efficiency', 'Other'];
  final segments = <String>[];
  for (int i = 1; i < parts.length && i - 1 < labels.length; i++) {
    final count = parts[i]!;
    if (count > 0) segments.add('$count ${labels[i - 1]}');
  }

  if (segments.isEmpty) return '$total';

  // Oxford-style join: "A and B"  or  "A, B and C"
  final joined = segments.length == 1
      ? segments.first
      : '${segments.sublist(0, segments.length - 1).join(', ')} and ${segments.last}';

  return '$total ($joined)';
}

String _fmtVal(String key, dynamic v) {
  if (v == null) return '—';
  if (v is bool) return v ? 'Yes' : 'No';
  if (key == 'number_processors') return _formatProcessors(v);
  if (v is String) {
    final f = formatSpxValue(v);
    return f.isEmpty ? '—' : f;
  }
  return v.toString();
}

// ─────────────────────────────────────────────────────────────────────────────
// Public widget
// ─────────────────────────────────────────────────────────────────────────────

/// Renders [SPHardwareDataType] as a flat ordered key-value list matching the
/// macOS System Information "Hardware Overview" layout.
class HardwareView extends StatefulWidget {
  final Map<String, dynamic> item;
  final String searchQuery;

  const HardwareView({
    super.key,
    required this.item,
    this.searchQuery = '',
  });

  @override
  State<HardwareView> createState() => _HardwareViewState();
}

class _HardwareViewState extends State<HardwareView> {
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
    final sp    = context.watch<UiScaleProvider>();
    final theme = Theme.of(context);
    final cs    = theme.colorScheme;

    final rows  = _buildRows(widget.item, _q, sp, theme, cs);

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

        // ── Rows ─────────────────────────────────────────────────────────────
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            children: rows,
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------

  static const double _keyWidth = 240.0;

  List<Widget> _buildRows(
    Map<String, dynamic> item,
    String q,
    UiScaleProvider sp,
    ThemeData theme,
    ColorScheme cs,
  ) {
    final rows  = <Widget>[];
    final seen  = <String>{};
    final keyW  = sp.sz(_keyWidth);

    void addRow(String key, dynamic value) {
      if (isInternalKey(key)) return;
      if (key == '_name') return;            // "hardware_overview" — not useful
      final label = _labelFor(key);
      final val   = _fmtVal(key, value);
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
    for (final key in _kOrder) {
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
    final q     = query.toLowerCase();
    final spans = <TextSpan>[];
    int start   = 0;
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
