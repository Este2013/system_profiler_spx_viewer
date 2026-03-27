import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/ui_scale_provider.dart';
import '../../utils/key_formatter.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Label overrides
// ─────────────────────────────────────────────────────────────────────────────

const _kLabels = <String, String>{
  'os_version':        'System Version',
  'kernel_version':    'Kernel Version',
  'boot_volume':       'Boot Volume',
  'boot_mode':         'Boot Mode',
  'local_host_name':   'Computer Name',
  'user_name':         'Username',
  'secure_vm':         'Secure Virtual Memory',
  'system_integrity':  'System Integrity Protection',
  'uptime':            'Time since boot',
};

// Preferred display order (only these keys are shown, in this order).
const _kOrder = <String>[
  'os_version',
  'kernel_version',
  'boot_volume',
  'boot_mode',
  'local_host_name',
  'user_name',
  'secure_vm',
  'system_integrity',
  'uptime',
];

// ─────────────────────────────────────────────────────────────────────────────
// Value formatters
// ─────────────────────────────────────────────────────────────────────────────

String _label(String key) => _kLabels[key] ?? formatKey(key);

String _formatValue(String key, dynamic raw) {
  if (raw == null) return '—';
  final v = raw.toString();

  switch (key) {
    // "normal_boot" → strip _boot suffix and title-case remainder.
    case 'boot_mode':
      final stripped = v.endsWith('_boot')
          ? v.substring(0, v.length - '_boot'.length)
          : v;
      return formatKey(stripped);

    // "secure_vm_enabled" / "secure_vm_disabled" → "Enabled" / "Disabled".
    case 'secure_vm':
      if (v.endsWith('_enabled'))  return 'Enabled';
      if (v.endsWith('_disabled')) return 'Disabled';
      return formatKey(v.replaceFirst('secure_vm_', ''));

    // "integrity_enabled" / "integrity_disabled" → "Enabled" / "Disabled".
    case 'system_integrity':
      if (v.endsWith('_enabled'))  return 'Enabled';
      if (v.endsWith('_disabled')) return 'Disabled';
      return formatKey(v.replaceFirst('integrity_', ''));

    // "up 2:21:2:14"  →  "2 days, 21 hours, 2 minutes, 14 seconds"
    case 'uptime':
      return _formatUptime(v);
  }

  // Generic: run through the standard SPX value cleaner.
  final cleaned = formatSpxValue(v);
  return cleaned.isEmpty ? v : cleaned;
}

/// Parses the uptime string produced by system_profiler.
///
/// Known formats:
///   "up 2:21:02:14"   → d:h:m:s
///   "up 0:04:12"      → h:m:s   (< 1 day)
///   "up 12 minutes"   → plain English fallback
String _formatUptime(String raw) {
  // Strip leading "up " if present.
  var s = raw.trim();
  if (s.startsWith('up ')) s = s.substring(3).trim();

  final parts = s.split(':');

  int d = 0, h = 0, m = 0, sec = 0;
  if (parts.length == 4) {
    d   = int.tryParse(parts[0].trim()) ?? 0;
    h   = int.tryParse(parts[1].trim()) ?? 0;
    m   = int.tryParse(parts[2].trim()) ?? 0;
    sec = int.tryParse(parts[3].trim()) ?? 0;
  } else if (parts.length == 3) {
    h   = int.tryParse(parts[0].trim()) ?? 0;
    m   = int.tryParse(parts[1].trim()) ?? 0;
    sec = int.tryParse(parts[2].trim()) ?? 0;
  } else if (parts.length == 2) {
    m   = int.tryParse(parts[0].trim()) ?? 0;
    sec = int.tryParse(parts[1].trim()) ?? 0;
  } else {
    // Cannot parse — return cleaned string.
    return s;
  }

  final segments = <String>[];
  if (d > 0)   segments.add('$d ${d   == 1 ? 'day'    : 'days'}');
  if (h > 0)   segments.add('$h ${h   == 1 ? 'hour'   : 'hours'}');
  if (m > 0)   segments.add('$m ${m   == 1 ? 'minute' : 'minutes'}');
  if (sec > 0) segments.add('$sec ${sec == 1 ? 'second' : 'seconds'}');

  return segments.isEmpty ? '0 seconds' : segments.join(', ');
}

// ─────────────────────────────────────────────────────────────────────────────
// Public widget
// ─────────────────────────────────────────────────────────────────────────────

class SoftwareView extends StatefulWidget {
  final Map<String, dynamic> item;
  final String searchQuery;

  const SoftwareView({
    super.key,
    required this.item,
    this.searchQuery = '',
  });

  @override
  State<SoftwareView> createState() => _SoftwareViewState();
}

class _SoftwareViewState extends State<SoftwareView> {
  final _filterCtrl = TextEditingController();
  String _filter = '';

  String get _q => _filter.isNotEmpty ? _filter : widget.searchQuery;

  @override
  void dispose() {
    _filterCtrl.dispose();
    super.dispose();
  }

  List<({String key, String label, String value})> get _rows {
    final q = _q.toLowerCase();
    final result = <({String key, String label, String value})>[];

    for (final key in _kOrder) {
      if (!widget.item.containsKey(key)) continue;
      final label = _label(key);
      final value = _formatValue(key, widget.item[key]);
      if (q.isNotEmpty &&
          !label.toLowerCase().contains(q) &&
          !value.toLowerCase().contains(q)) {
        continue;
      }
      result.add((key: key, label: label, value: value));
    }

    return result;
  }

  @override
  Widget build(BuildContext context) {
    final sp    = context.watch<UiScaleProvider>();
    final theme = Theme.of(context);
    final cs    = theme.colorScheme;
    final rows  = _rows;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Filter bar ──────────────────────────────────────────────────────
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

        // ── Rows ────────────────────────────────────────────────────────────
        Expanded(
          child: rows.isEmpty
              ? Center(
                  child: Text(
                    'No matching fields',
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: cs.onSurfaceVariant),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                  itemCount: rows.length,
                  separatorBuilder: (context, index) => Divider(
                    height: 1,
                    color: cs.outlineVariant.withAlpha(80),
                  ),
                  itemBuilder: (context, i) => _Row(
                    label:       rows[i].label,
                    value:       rows[i].value,
                    searchQuery: _q,
                    keyWidth:    sp.sz(260),
                    theme:       theme,
                    cs:          cs,
                  ),
                ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Single key-value row with optional search highlight
// ─────────────────────────────────────────────────────────────────────────────

class _Row extends StatelessWidget {
  final String label;
  final String value;
  final String searchQuery;
  final double keyWidth;
  final ThemeData theme;
  final ColorScheme cs;

  const _Row({
    required this.label,
    required this.value,
    required this.searchQuery,
    required this.keyWidth,
    required this.theme,
    required this.cs,
  });

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 7),
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
              child: searchQuery.isNotEmpty
                  ? _Highlight(
                      text: value, query: searchQuery, theme: theme, cs: cs)
                  : SelectableText(value, style: theme.textTheme.bodyMedium),
            ),
          ],
        ),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Search highlight
// ─────────────────────────────────────────────────────────────────────────────

class _Highlight extends StatelessWidget {
  final String text;
  final String query;
  final ThemeData theme;
  final ColorScheme cs;

  const _Highlight({
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
    return SelectableText.rich(
        TextSpan(style: theme.textTheme.bodyMedium, children: spans));
  }
}
