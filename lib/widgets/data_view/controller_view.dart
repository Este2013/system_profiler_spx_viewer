import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../providers/ui_scale_provider.dart';
import '../../utils/key_formatter.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Label overrides for known ibridge_* keys
// ─────────────────────────────────────────────────────────────────────────────

const _kLabels = <String, String>{
  // Top-level fields
  'ibridge_model_identifier_top': 'Model Identifier',
  'ibridge_build':                'Firmware Version',
  'ibridge_boot_uuid':            'Boot UUID',

  // Boot-policy group header
  'ibridge_extra_boot_policies':  'Boot Policy',

  // Secure Boot (sub-header with a value)
  'ibridge_secure_boot':          'Secure Boot',

  // Secure Boot sub-properties (ibridge_sb_*)
  'ibridge_sb_sip':        'System Integrity Protection',
  'ibridge_sb_ssv':        'Signed System Volume',
  'ibridge_sb_ctrr':       'Kernel CTRR',
  'ibridge_sb_boot_args':  'Boot Arguments Filtering',
  'ibridge_sb_other_kext': 'Allow All Kernel Extensions',
  'ibridge_sb_manual_mdm': 'User Approved Privileged MDM Operations',
  'ibridge_sb_device_mdm': 'DEP Approved Privileged MDM Operations',
};

/// Returns a human-readable label for an ibridge key.
/// Falls back to stripping ibridge_sb_ / ibridge_ prefix then [formatKey].
String _labelFor(String key) {
  if (_kLabels.containsKey(key)) return _kLabels[key]!;
  for (final prefix in ['ibridge_sb_', 'ibridge_']) {
    if (key.startsWith(prefix)) {
      return formatKey(key.substring(prefix.length));
    }
  }
  return formatKey(key);
}

/// True when [item] contains flat ibridge_* keys (the common case for
/// SPiBridgeDataType on Apple-Silicon / T2 Macs).
bool _isFlatiBridge(Map<String, dynamic> item) =>
    item.keys.any((k) => k.startsWith('ibridge_'));

// ─────────────────────────────────────────────────────────────────────────────
// Public widget
// ─────────────────────────────────────────────────────────────────────────────

/// Renders [SPiBridgeDataType] (Hardware › Controller) as a hierarchical
/// indented property tree matching macOS System Information:
///
///   Model Identifier     Macmini9,1
///   Firmware Version     iBoot-13822.81.10
///   Boot UUID            EFBDB640-…
///   ──────────────────────────────────────
///   Boot Policy
///     Secure Boot                Full Security
///       System Integrity Protection   Enabled
///       Signed System Volume          Enabled
///       …
class ControllerView extends StatefulWidget {
  final Map<String, dynamic> item;
  final String searchQuery;

  const ControllerView({
    super.key,
    required this.item,
    this.searchQuery = '',
  });

  @override
  State<ControllerView> createState() => _ControllerViewState();
}

class _ControllerViewState extends State<ControllerView> {
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

        // ── Content ──────────────────────────────────────────────────────────
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
            children: _isFlatiBridge(widget.item)
                ? _buildFlat(context, widget.item, sp)
                : _buildGeneric(context, widget.item, 0, sp),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Layout constants
  // ---------------------------------------------------------------------------

  /// Pixels of left indent per depth level (at scale 1.0).
  static const double _indentStep = 20.0;

  /// Key-column base width at depth 0 (at scale 1.0).
  /// Wide enough to fit long labels like "User Approved Privileged MDM
  /// Operations" (≈37 chars) at depth 2 without wrapping too badly.
  static const double _keyBase = 260.0;

  // ---------------------------------------------------------------------------
  // Flat iBridge renderer  (the common case)
  // ---------------------------------------------------------------------------

  /// Known ordering for top-level non-boot-policy fields.
  static const _kTopOrder = [
    'ibridge_model_identifier_top',
    'ibridge_build',
    'ibridge_boot_uuid',
  ];

  /// Keys that belong inside the Boot Policy / Secure Boot section.
  static bool _isBootPolicyKey(String k) =>
      k == 'ibridge_extra_boot_policies' ||
      k == 'ibridge_secure_boot' ||
      k.startsWith('ibridge_sb_');

  /// Preferred order for Secure Boot sub-properties.
  static const _kSbOrder = [
    'ibridge_sb_sip',
    'ibridge_sb_ssv',
    'ibridge_sb_ctrr',
    'ibridge_sb_boot_args',
    'ibridge_sb_other_kext',
    'ibridge_sb_manual_mdm',
    'ibridge_sb_device_mdm',
  ];

  List<Widget> _buildFlat(
    BuildContext context,
    Map<String, dynamic> item,
    UiScaleProvider sp,
  ) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final q = _q;
    final rows = <Widget>[];

    // ── 1. Top-level properties ─────────────────────────────────────────────
    final keyW0 = sp.sz(_keyBase);
    final seen = <String>{};

    // Priority-ordered known fields first
    for (final key in _kTopOrder) {
      if (!item.containsKey(key)) continue;
      seen.add(key);
      final label = _labelFor(key);
      final val = _fmtVal(item[key]);
      if (q.isNotEmpty && !_matches(q, label, val)) continue;
      rows.add(_LeafRow(label: label, value: val, indent: 0, keyWidth: keyW0,
          searchQuery: q, theme: theme, cs: cs));
    }

    // Remaining top-level fields (not boot-policy, not already shown)
    for (final e in item.entries) {
      if (isInternalKey(e.key)) continue;
      if (seen.contains(e.key)) continue;
      if (_isBootPolicyKey(e.key)) continue;
      seen.add(e.key);

      final label = _labelFor(e.key);

      if (e.value is Map) {
        final sub = (e.value as Map).cast<String, dynamic>();
        if (q.isNotEmpty && !_branchMatchesQ(q, label, sub)) continue;
        if (rows.isNotEmpty) rows.add(_divider(cs));
        rows.add(_SectionHeader(label: label, depth: 0, indent: 0, theme: theme, cs: cs));
        rows.addAll(_buildGeneric(context, sub, 1, sp));
      } else {
        final val = _fmtVal(e.value);
        if (q.isNotEmpty && !_matches(q, label, val)) continue;
        rows.add(_LeafRow(label: label, value: val, indent: 0, keyWidth: keyW0,
            searchQuery: q, theme: theme, cs: cs));
      }
    }

    // ── 2. Boot Policy section ──────────────────────────────────────────────
    final hasBootPolicy = item.keys.any(_isBootPolicyKey);
    if (!hasBootPolicy) return rows;

    // Check if anything in the boot policy section matches the filter
    if (q.isNotEmpty && !_bootPolicyMatchesQ(q, item)) return rows;

    if (rows.isNotEmpty) rows.add(_divider(cs));
    rows.add(_SectionHeader(label: 'Boot Policy', depth: 0, indent: 0, theme: theme, cs: cs));

    // "Secure Boot: <value>" — KV row at depth 1
    final indent1 = sp.sz(_indentStep);
    final keyW1 = (sp.sz(_keyBase) - indent1).clamp(60.0, double.infinity);
    final secureBootVal = item['ibridge_secure_boot'];
    if (secureBootVal != null) {
      final label = 'Secure Boot';
      final val = _fmtVal(secureBootVal);
      if (q.isEmpty || _matches(q, label, val)) {
        rows.add(_LeafRow(label: label, value: val, indent: indent1,
            keyWidth: keyW1, searchQuery: q, theme: theme, cs: cs));
      }
    }

    // Secure Boot sub-properties at depth 2
    final indent2 = sp.sz(_indentStep * 2);
    final keyW2 = (sp.sz(_keyBase) - indent2).clamp(60.0, double.infinity);

    // Known order first
    for (final key in _kSbOrder) {
      if (!item.containsKey(key)) continue;
      final label = _labelFor(key);
      final val = _fmtVal(item[key]);
      if (q.isNotEmpty && !_matches(q, label, val)) continue;
      rows.add(_LeafRow(label: label, value: val, indent: indent2,
          keyWidth: keyW2, searchQuery: q, theme: theme, cs: cs));
    }

    // Any remaining ibridge_sb_* not in known order
    for (final e in item.entries) {
      if (!e.key.startsWith('ibridge_sb_')) continue;
      if (_kSbOrder.contains(e.key)) continue;
      final label = _labelFor(e.key);
      final val = _fmtVal(e.value);
      if (q.isNotEmpty && !_matches(q, label, val)) continue;
      rows.add(_LeafRow(label: label, value: val, indent: indent2,
          keyWidth: keyW2, searchQuery: q, theme: theme, cs: cs));
    }

    return rows;
  }

  // ---------------------------------------------------------------------------
  // Generic recursive renderer  (fallback for non-flat / unknown structures)
  // ---------------------------------------------------------------------------

  List<Widget> _buildGeneric(
    BuildContext context,
    Map<String, dynamic> map,
    int depth,
    UiScaleProvider sp,
  ) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final q = _q;

    final indent = sp.sz(_indentStep * depth);
    final keyWidth = (sp.sz(_keyBase) - indent).clamp(60.0, double.infinity);
    final rows = <Widget>[];

    for (final e in map.entries) {
      if (isInternalKey(e.key)) continue;

      final label = _labelFor(e.key);
      final value = e.value;

      if (value is Map) {
        final sub = value.cast<String, dynamic>();
        if (q.isNotEmpty && !_branchMatchesQ(q, label, sub)) continue;
        if (depth == 0 && rows.isNotEmpty) rows.add(_divider(cs));
        rows.add(_SectionHeader(label: label, depth: depth, indent: indent,
            theme: theme, cs: cs));
        rows.addAll(_buildGeneric(context, sub, depth + 1, sp));
      } else {
        final val = _fmtVal(value);
        if (q.isNotEmpty && !_matches(q, label, val)) continue;
        rows.add(_LeafRow(label: label, value: val, indent: indent,
            keyWidth: keyWidth, searchQuery: q, theme: theme, cs: cs));
      }
    }

    return rows;
  }

  // ---------------------------------------------------------------------------
  // Filter helpers
  // ---------------------------------------------------------------------------

  bool _matches(String q, String label, String val) {
    final lower = q.toLowerCase();
    return label.toLowerCase().contains(lower) ||
        val.toLowerCase().contains(lower);
  }

  bool _branchMatchesQ(String q, String label, Map<String, dynamic> map) {
    final lower = q.toLowerCase();
    if (label.toLowerCase().contains(lower)) return true;
    for (final e in map.entries) {
      if (isInternalKey(e.key)) continue;
      final k = _labelFor(e.key);
      if (k.toLowerCase().contains(lower)) return true;
      if (e.value is Map) {
        if (_branchMatchesQ(q, k, (e.value as Map).cast<String, dynamic>())) {
          return true;
        }
      } else {
        if (_fmtVal(e.value).toLowerCase().contains(lower)) return true;
      }
    }
    return false;
  }

  bool _bootPolicyMatchesQ(String q, Map<String, dynamic> item) {
    if (_matches(q, 'Boot Policy', '')) return true;
    if (_matches(q, 'Secure Boot', _fmtVal(item['ibridge_secure_boot']))) {
      return true;
    }
    for (final key in [..._kSbOrder, ...item.keys.where((k) => k.startsWith('ibridge_sb_'))]) {
      if (!item.containsKey(key)) continue;
      if (_matches(q, _labelFor(key), _fmtVal(item[key]))) return true;
    }
    return false;
  }

  // ---------------------------------------------------------------------------
  // Value formatting
  // ---------------------------------------------------------------------------

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
      final formatted = formatSpxValue(v);
      return formatted.isEmpty ? '—' : formatted;
    }
    return v.toString();
  }

  // ---------------------------------------------------------------------------
  // Small widget helpers
  // ---------------------------------------------------------------------------

  Widget _divider(ColorScheme cs) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Divider(color: cs.outlineVariant.withAlpha(80), height: 1),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Section header row  (for nested group labels)
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
                ? _HighlightText(text: value, query: searchQuery,
                    theme: theme, cs: cs)
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
