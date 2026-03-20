import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/ui_scale_provider.dart';
import '../../utils/key_formatter.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Label overrides
// ─────────────────────────────────────────────────────────────────────────────

/// Labels for the Secure Element (se_*) keys.
const _kSeLabels = <String, String>{
  'se_plt':              'Platform ID',
  'se_id':               'SEID',
  'se_os_id':            'OS ID',
  'se_device':           'Device',
  'se_prod_signed':      'Production Signed',
  'se_in_restricted_mode': 'Restricted Mode',
  'se_hw':               'Hardware',
  'se_fw':               'Firmware',
  'se_os_version':       'JCOP OS',
};

/// Labels for the Controller (ctl_*) keys.
const _kCtlLabels = <String, String>{
  'ctl_hw': 'Hardware',
  'ctl_fw': 'Firmware',
  'ctl_mw': 'Middleware',
};

/// Preferred display order — SE group.
const _kSeOrder = [
  'se_plt',
  'se_id',
  'se_os_id',
  'se_device',
  'se_prod_signed',
  'se_in_restricted_mode',
  'se_hw',
  'se_fw',
  'se_os_version',
];

/// Preferred display order — Controller group.
const _kCtlOrder = [
  'ctl_hw',
  'ctl_fw',
  'ctl_mw',
];

// ─────────────────────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────────────────────

String _seLabelFor(String key) =>
    _kSeLabels[key] ?? formatKey(key.startsWith('se_') ? key.substring(3) : key);

String _ctlLabelFor(String key) =>
    _kCtlLabels[key] ?? formatKey(key.startsWith('ctl_') ? key.substring(4) : key);

String _fmtVal(dynamic v) {
  if (v == null) return '—';
  if (v is bool) return v ? 'Yes' : 'No';
  if (v is String) {
    final trimmed = v.trim();
    if (trimmed.isEmpty) return '—';
    final f = formatSpxValue(trimmed);
    return f.isEmpty ? '—' : f;
  }
  return v.toString();
}

/// Returns true if key is a whitespace-only marker (se_info / ctl_info).
bool _isMarkerKey(String key) => key == 'se_info' || key == 'ctl_info';

// ─────────────────────────────────────────────────────────────────────────────
// Public widget
// ─────────────────────────────────────────────────────────────────────────────

/// Renders [SPSecureElementDataType] matching the macOS "Apple Pay" layout:
///
///   Apple Pay Information
///     Platform ID      N5B2M004C7ED0000
///     SEID             04233CCB…
///     …
///
///   Controller Information
///     Hardware         b2.2 ()
///     Firmware         1.ba rev 170350
///     Middleware       5.1.4.10
class ApplePayView extends StatefulWidget {
  final Map<String, dynamic> item;
  final String searchQuery;

  const ApplePayView({
    super.key,
    required this.item,
    this.searchQuery = '',
  });

  @override
  State<ApplePayView> createState() => _ApplePayViewState();
}

class _ApplePayViewState extends State<ApplePayView> {
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
    final q     = _q;

    final seRows  = _buildGroup(widget.item, _kSeOrder,  _seLabelFor,  q, sp, theme, cs);
    final ctlRows = _buildGroup(widget.item, _kCtlOrder, _ctlLabelFor, q, sp, theme, cs);

    // If filter hides everything in a section, omit that section header too.
    final showSe  = seRows.isNotEmpty  || q.isEmpty;
    final showCtl = ctlRows.isNotEmpty || q.isEmpty;

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
            children: [
              if (showSe) ...[
                _SectionHeader(title: 'Apple Pay Information', theme: theme, cs: cs),
                ...seRows,
              ],
              if (showSe && showCtl) ...[
                const SizedBox(height: 8),
                Divider(color: cs.outlineVariant.withAlpha(120)),
                const SizedBox(height: 4),
              ],
              if (showCtl) ...[
                _SectionHeader(title: 'Controller Information', theme: theme, cs: cs),
                ...ctlRows,
              ],
            ],
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------

  static const double _keyWidth = 200.0;

  /// Builds KV rows for [keys] from [item], using [labelFn] for display names.
  /// Appends any unknown keys with the matching prefix after the ordered ones.
  List<Widget> _buildGroup(
    Map<String, dynamic> item,
    List<String> orderedKeys,
    String Function(String) labelFn,
    String q,
    UiScaleProvider sp,
    ThemeData theme,
    ColorScheme cs,
  ) {
    final rows = <Widget>[];
    final seen = <String>{};
    final keyW = sp.sz(_keyWidth);

    // Determine the prefix shared by this group's ordered keys.
    final prefix = orderedKeys.isNotEmpty
        ? orderedKeys.first.substring(0, orderedKeys.first.indexOf('_') + 1)
        : '';

    void addRow(String key, dynamic value) {
      if (isInternalKey(key)) return;
      if (_isMarkerKey(key)) return;        // se_info / ctl_info — whitespace markers
      if (key == '_name') return;
      final label = labelFn(key);
      final val   = _fmtVal(value);
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

    // 1. Ordered known keys
    for (final key in orderedKeys) {
      if (!item.containsKey(key)) continue;
      if (seen.contains(key)) continue;
      seen.add(key);
      addRow(key, item[key]);
    }

    // 2. Remaining keys with this group's prefix
    if (prefix.isNotEmpty) {
      for (final e in item.entries) {
        if (!e.key.startsWith(prefix)) continue;
        if (seen.contains(e.key)) continue;
        seen.add(e.key);
        addRow(e.key, e.value);
      }
    }

    return rows;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Section header  (non-collapsible bold label)
// ─────────────────────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final ThemeData theme;
  final ColorScheme cs;

  const _SectionHeader({
    required this.title,
    required this.theme,
    required this.cs,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6, bottom: 6),
      child: Text(
        title,
        style: theme.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w700,
          color: cs.onSurface,
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
