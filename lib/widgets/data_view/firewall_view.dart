import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/ui_scale_provider.dart';
import '../../utils/key_formatter.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Label overrides and display order
// ─────────────────────────────────────────────────────────────────────────────

const _kLabels = <String, String>{
  'spfirewall_globalstate':    'Firewall',
  'spfirewall_stealthenabled': 'Stealth Mode',
  'spfirewall_loggingenabled': 'Logging Enabled',
  'spfirewall_loggingoption':  'Log Mode',
  'spfirewall_applications':   'Applications',
};

/// Preferred top-level field order.  Globalstate first, applications last.
const _kOrder = [
  'spfirewall_globalstate',
  'spfirewall_stealthenabled',
  'spfirewall_loggingenabled',
  'spfirewall_loggingoption',
  'spfirewall_applications',
];

String _fwLabel(String key) {
  if (_kLabels.containsKey(key)) return _kLabels[key]!;
  if (key.startsWith('spfirewall_')) {
    return formatKey(key.substring('spfirewall_'.length));
  }
  return formatKey(key);
}

String _fwValue(dynamic v) {
  if (v == null) return '—';
  if (v is bool) return v ? 'Yes' : 'No';
  if (v is String) {
    final t = formatSpxValue(v);
    return t.isEmpty ? '—' : t;
  }
  return v.toString();
}

// ─────────────────────────────────────────────────────────────────────────────
// Public widget
// ─────────────────────────────────────────────────────────────────────────────

/// Renders [SPFirewallDataType] as a hierarchical property view matching
/// macOS System Information style:
///
///   Firewall                Allow all incoming connections
///   Stealth Mode            No
///   Logging Enabled         No
///   ─────────────────────────────────────────────────
///   Applications
///     Com.apple.cupsd       Allow all connections
///     Com.apple.smbd        Allow all connections
///     …
class FirewallView extends StatefulWidget {
  final Map<String, dynamic> item;
  final String searchQuery;

  const FirewallView({
    super.key,
    required this.item,
    this.searchQuery = '',
  });

  @override
  State<FirewallView> createState() => _FirewallViewState();
}

class _FirewallViewState extends State<FirewallView> {
  final _filterCtrl = TextEditingController();
  String _filter = '';

  String get _q => _filter.isNotEmpty ? _filter : widget.searchQuery;

  @override
  void dispose() {
    _filterCtrl.dispose();
    super.dispose();
  }

  // ── Layout constants ────────────────────────────────────────────────────────
  static const double _indentStep = 20.0;
  static const double _keyBase    = 260.0;

  @override
  Widget build(BuildContext context) {
    final sp    = context.watch<UiScaleProvider>();
    final theme = Theme.of(context);
    final cs    = theme.colorScheme;

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

        // ── Content ──────────────────────────────────────────────────────────
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
            children: _buildRows(context, sp),
          ),
        ),
      ],
    );
  }

  /// Measures all label strings with [TextPainter] and returns a key-column
  /// width wide enough that no label needs to wrap, while keeping all rows
  /// aligned at the same column boundary.
  double _computeKeyWidth(BuildContext context, UiScaleProvider sp) {
    final labelStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
      fontWeight: FontWeight.w500,
    );
    final painter = TextPainter(
      textDirection: TextDirection.ltr,
      textScaler: TextScaler.linear(sp.scale),
    );

    double maxTopW = 0;
    double maxIndentedW = 0;

    for (final key in widget.item.keys) {
      if (isInternalKey(key) || key == '_name') continue;
      final value = widget.item[key];

      if (value is Map) {
        for (final k in (value as Map).keys) {
          painter.text = TextSpan(text: k.toString(), style: labelStyle);
          painter.layout();
          if (painter.width > maxIndentedW) maxIndentedW = painter.width;
        }
      } else if (value is List) {
        for (final raw in (value as List).whereType<Map>()) {
          final name = raw['_name']?.toString() ?? '';
          if (name.isEmpty) continue;
          painter.text = TextSpan(text: name, style: labelStyle);
          painter.layout();
          if (painter.width > maxIndentedW) maxIndentedW = painter.width;
        }
      } else {
        final label = _fwLabel(key);
        painter.text = TextSpan(text: label, style: labelStyle);
        painter.layout();
        if (painter.width > maxTopW) maxTopW = painter.width;
      }
    }

    painter.dispose();

    final indent1 = sp.sz(_indentStep);
    // keyW0 must accommodate top-level labels AND indented labels (offset by indent1).
    final fromIndented = maxIndentedW + indent1 + 24.0;
    final fromTop = maxTopW + 24.0;
    return (fromIndented > fromTop ? fromIndented : fromTop).clamp(120.0, 560.0);
  }

  // ── Row builder ─────────────────────────────────────────────────────────────

  List<Widget> _buildRows(BuildContext context, UiScaleProvider sp) {
    final theme  = Theme.of(context);
    final cs     = theme.colorScheme;
    final q      = _q;
    final keyW0  = _computeKeyWidth(context, sp);
    final indent1 = sp.sz(_indentStep);
    final keyW1  = (keyW0 - indent1).clamp(60.0, double.infinity);
    final rows   = <Widget>[];
    final seen   = <String>{};

    // Walk in preferred order, then any remaining keys.
    final orderedKeys = [
      ..._kOrder.where((k) => widget.item.containsKey(k)),
      ...widget.item.keys.where((k) => !_kOrder.contains(k)),
    ];

    for (final key in orderedKeys) {
      if (isInternalKey(key)) continue;
      if (key == '_name') continue;
      if (seen.contains(key)) continue;
      seen.add(key);

      final value = widget.item[key];
      final label = _fwLabel(key);

      // Applications — can be a Map<bundleId, rule> OR a List of Maps.
      if (value is Map || value is List) {
        // Normalise to a flat list of (label, translatedValue) pairs.
        final entries = <(String, String)>[];

        if (value is Map) {
          // Most common: { 'com.apple.cupsd': 'spfirewall_allow_all', … }
          for (final e in (value as Map).entries) {
            entries.add((e.key.toString(), _fwValue(e.value)));
          }
        } else {
          // Fallback: list of dicts with _name + rule key.
          for (final raw in (value as List).whereType<Map>()) {
            final app = raw.map((k, v) => MapEntry(k.toString(), v));
            final name = app['_name']?.toString() ?? '—';
            entries.add((name, _resolveAppRule(app)));
          }
        }

        if (entries.isEmpty) continue;

        // Filter: skip section if nothing matches.
        if (q.isNotEmpty) {
          final hit = label.toLowerCase().contains(q.toLowerCase()) ||
              entries.any((p) =>
                  _matches(q, p.$1, p.$2));
          if (!hit) continue;
        }

        if (rows.isNotEmpty) rows.add(_divider(cs));
        rows.add(_SectionHeader(
            label: label, depth: 0, indent: 0, theme: theme, cs: cs));

        for (final (appName, appValue) in entries) {
          if (q.isNotEmpty && !_matches(q, appName, appValue)) continue;
          rows.add(_LeafRow(
            label:       appName,
            value:       appValue,
            indent:      indent1,
            keyWidth:    keyW1,
            searchQuery: q,
            theme:       theme,
            cs:          cs,
          ));
        }
        continue;
      }

      // Scalar / bool field.
      final val = _fwValue(value);
      if (q.isNotEmpty && !_matches(q, label, val)) continue;
      rows.add(_LeafRow(
        label:       label,
        value:       val,
        indent:      0,
        keyWidth:    keyW0,
        searchQuery: q,
        theme:       theme,
        cs:          cs,
      ));
    }

    return rows;
  }

  /// Extracts the rule value from a list-style application entry map.
  /// Looks for the first non-internal, non-`_name` key and returns its
  /// translated value.
  String _resolveAppRule(Map<String, dynamic> app) {
    for (final e in app.entries) {
      if (isInternalKey(e.key)) continue;
      if (e.key == '_name') continue;
      return _fwValue(e.value);
    }
    return '—';
  }

  // ── Filter helpers ───────────────────────────────────────────────────────────

  bool _matches(String q, String label, String val) {
    final lower = q.toLowerCase();
    return label.toLowerCase().contains(lower) ||
        val.toLowerCase().contains(lower);
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────

  Widget _divider(ColorScheme cs) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Divider(color: cs.outlineVariant.withAlpha(80), height: 1),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Section header (reuses the same visual style as ControllerView)
// ─────────────────────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String label;
  final int depth;
  final double indent;
  final ThemeData theme;
  final ColorScheme cs;

  const _SectionHeader({
    required this.label,
    required this.depth,
    required this.indent,
    required this.theme,
    required this.cs,
  });

  @override
  Widget build(BuildContext context) {
    final isTop = depth == 0;
    return Padding(
      padding: EdgeInsets.only(left: indent, top: isTop ? 4 : 8, bottom: 4),
      child: Text(
        label,
        style: (isTop ? theme.textTheme.titleSmall : theme.textTheme.bodyMedium)
            ?.copyWith(
          color: isTop ? cs.onSurface : cs.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Leaf key-value row
// ─────────────────────────────────────────────────────────────────────────────

class _LeafRow extends StatelessWidget {
  final String label;
  final String value;
  final double indent;
  final double keyWidth;
  final String searchQuery;
  final ThemeData theme;
  final ColorScheme cs;

  const _LeafRow({
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
                    text: value, query: searchQuery, theme: theme, cs: cs)
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
    final q     = query.toLowerCase();
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
