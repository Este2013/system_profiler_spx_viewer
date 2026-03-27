import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/ui_scale_provider.dart';
import '../../utils/key_formatter.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Label helpers
// ─────────────────────────────────────────────────────────────────────────────

const _kAppLabels = <String, String>{
  'spxcode_app':        'Xcode',
  'spinstruments_app':  'Instruments',
  'spib_app':           'Interface Builder',
  'spdashcode_app':     'Dashcode',
};

/// Preferred display order for known application keys.
const _kAppKeyOrder = <String>[
  'spxcode_app',
  'spib_app',
  'spinstruments_app',
  'spdashcode_app',
];

String _appLabel(String key) {
  if (_kAppLabels.containsKey(key)) return _kAppLabels[key]!;
  // Generic: strip sp prefix and _app suffix, then title-case.
  String k = key.startsWith('sp') ? key.substring(2) : key;
  if (k.endsWith('_app')) k = k.substring(0, k.length - 4);
  return formatKey(k);
}

// ─────────────────────────────────────────────────────────────────────────────
// Public widget
// ─────────────────────────────────────────────────────────────────────────────

class DeveloperToolsView extends StatefulWidget {
  final Map<String, dynamic> item;
  final String searchQuery;

  const DeveloperToolsView({
    super.key,
    required this.item,
    this.searchQuery = '',
  });

  @override
  State<DeveloperToolsView> createState() => _DeveloperToolsViewState();
}

class _DeveloperToolsViewState extends State<DeveloperToolsView> {
  final _filterCtrl = TextEditingController();
  String _filter = '';

  String get _q => _filter.isNotEmpty ? _filter : widget.searchQuery;

  static const double _step  = 20.0;
  static const double _keyW  = 200.0;

  @override
  void dispose() {
    _filterCtrl.dispose();
    super.dispose();
  }

  // ── Row building ───────────────────────────────────────────────────────────

  List<Widget> _buildRows(
    BuildContext context,
    UiScaleProvider sp,
    ThemeData theme,
    ColorScheme cs,
  ) {
    final q    = _q.toLowerCase();
    final item = widget.item;

    final i1 = sp.sz(_step);
    final i2 = sp.sz(_step * 2);
    final i3 = sp.sz(_step * 3);

    double kw(double indent) =>
        (sp.sz(_keyW) - indent).clamp(60.0, double.infinity);

    bool hit(String label, String value) =>
        label.toLowerCase().contains(q) || value.toLowerCase().contains(q);

    final rows = <Widget>[];

    // ── Version ──────────────────────────────────────────────────────────────
    final version = item['spdevtools_version']?.toString() ?? '—';
    if (q.isEmpty || hit('version', version)) {
      rows.add(_KvRow(
        label: 'Version', value: version,
        indent: i1, keyWidth: kw(i1), query: q, theme: theme, cs: cs,
      ));
    }

    // ── Location ─────────────────────────────────────────────────────────────
    final path = item['spdevtools_path']?.toString() ?? '—';
    if (q.isEmpty || hit('location', path)) {
      rows.add(_KvRow(
        label: 'Location', value: path,
        indent: i1, keyWidth: kw(i1), query: q, theme: theme, cs: cs,
      ));
    }

    // ── Applications ──────────────────────────────────────────────────────────
    final rawApps = item['spdevtools_apps'];
    if (rawApps is Map) {
      final appMap = rawApps.map((k, v) => MapEntry(k.toString(), v?.toString() ?? ''));
      final appRows = _buildAppRows(appMap, q, i2, kw, theme, cs);
      final sectionMatch = q.isEmpty || 'applications'.contains(q);
      if (sectionMatch || appRows.isNotEmpty) {
        rows.add(_SectionHeader(
          label: 'Applications', indent: i1, theme: theme, cs: cs));
        rows.addAll(appRows);
      }
    }

    // ── SDKs ─────────────────────────────────────────────────────────────────
    final rawSdks = item['spdevtools_sdks'];
    if (rawSdks is Map) {
      final sdkRows = _buildSdkRows(rawSdks, q, i2, i3, kw, theme, cs);
      final sectionMatch = q.isEmpty || 'sdks'.contains(q);
      if (sectionMatch || sdkRows.isNotEmpty) {
        rows.add(_SectionHeader(
          label: 'SDKs', indent: i1, theme: theme, cs: cs));
        rows.addAll(sdkRows);
      }
    }

    return rows;
  }

  List<Widget> _buildAppRows(
    Map<String, String> apps,
    String q,
    double indent,
    double Function(double) kw,
    ThemeData theme,
    ColorScheme cs,
  ) {
    final rows = <Widget>[];
    // Emit in preferred order, then any remaining unknown keys.
    final ordered = [
      ..._kAppKeyOrder.where(apps.containsKey),
      ...apps.keys.where((k) => !_kAppKeyOrder.contains(k)),
    ];
    for (final key in ordered) {
      final label = _appLabel(key);
      final value = apps[key] ?? '—';
      if (q.isNotEmpty &&
          !label.toLowerCase().contains(q) &&
          !value.toLowerCase().contains(q)) { continue; }
      rows.add(_KvRow(
        label: label, value: value,
        indent: indent, keyWidth: kw(indent), query: q, theme: theme, cs: cs,
      ));
    }
    return rows;
  }

  List<Widget> _buildSdkRows(
    Map rawSdks,
    String q,
    double indent2,
    double indent3,
    double Function(double) kw,
    ThemeData theme,
    ColorScheme cs,
  ) {
    final rows = <Widget>[];
    // Sort SDK names alphabetically (case-insensitive).
    final sdkNames = rawSdks.keys.map((k) => k.toString()).toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

    for (final sdkName in sdkNames) {
      final versions = rawSdks[sdkName];
      if (versions is! Map) continue;

      // Build version rows for this SDK.
      final vRows = <Widget>[];
      for (final ve in versions.entries) {
        final vLabel = ve.key.toString();
        final vValue = ve.value?.toString() ?? '';
        if (q.isNotEmpty &&
            !sdkName.toLowerCase().contains(q) &&
            !vLabel.toLowerCase().contains(q) &&
            !vValue.toLowerCase().contains(q)) { continue; }
        vRows.add(_KvRow(
          label: vLabel, value: vValue,
          indent: indent3, keyWidth: kw(indent3), query: q,
          theme: theme, cs: cs,
        ));
      }

      // If filtering, skip SDK entirely when nothing matched.
      if (q.isNotEmpty && vRows.isEmpty && !sdkName.toLowerCase().contains(q)) {
        continue;
      }

      rows.add(_SectionHeader(
        label: sdkName, indent: indent2, theme: theme, cs: cs));
      rows.addAll(vRows);
    }
    return rows;
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final sp    = context.watch<UiScaleProvider>();
    final theme = Theme.of(context);
    final cs    = theme.colorScheme;

    final rows = _buildRows(context, sp, theme, cs);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Filter bar ─────────────────────────────────────────────────────
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

        // ── Content ────────────────────────────────────────────────────────
        Expanded(
          child: rows.isEmpty
              ? Center(
                  child: Text(
                    'No matching fields',
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: cs.onSurfaceVariant),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                  children: rows,
                ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Section header ("Applications", "SDKs", individual SDK names)
// ─────────────────────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String label;
  final double indent;
  final ThemeData theme;
  final ColorScheme cs;

  const _SectionHeader({
    required this.label,
    required this.indent,
    required this.theme,
    required this.cs,
  });

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.only(left: indent, top: 8, bottom: 2),
        child: Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: cs.onSurface,
          ),
        ),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Key-value row with optional search highlight
// ─────────────────────────────────────────────────────────────────────────────

class _KvRow extends StatelessWidget {
  final String label;
  final String value;
  final double indent;
  final double keyWidth;
  final String query;
  final ThemeData theme;
  final ColorScheme cs;

  const _KvRow({
    required this.label,
    required this.value,
    required this.indent,
    required this.keyWidth,
    required this.query,
    required this.theme,
    required this.cs,
  });

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.only(left: indent, top: 4, bottom: 4),
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
              child: query.isNotEmpty
                  ? _Highlight(text: value, query: query, theme: theme, cs: cs)
                  : SelectableText(value, style: theme.textTheme.bodyMedium),
            ),
          ],
        ),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Highlight
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
