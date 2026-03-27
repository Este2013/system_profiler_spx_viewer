import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/ui_scale_provider.dart';
import '../../utils/key_formatter.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Label overrides
// ─────────────────────────────────────────────────────────────────────────────

const _kLocationLabels = <String, String>{
  'spnetworklocation_is_active': 'Active Location',
  'spnetworklocation_services':  'Services',
};

/// Labels for scalar keys directly on a service dict.
const _kServiceLabels = <String, String>{
  'Type':                   'Type',
  'Bsd Device Name':        'BSD Device Name',
  'BSD Device Name':        'BSD Device Name',
  'Hardware Address':       'Hardware (MAC) Address',
  'Hardware (MAC) Address': 'Hardware (MAC) Address',
  'spnetworklocation_services_type': 'Type',
};

/// Labels for keys inside IPv4 / IPv6 / Proxies / IEEE80211 sub-dicts.
const _kSubLabels = <String, String>{
  'ConfigMethod':         'Configuration Method',
  'ExceptionsList':       'Exceptions List',
  'FTPPassive':           'FTP Passive Mode',
  'FTPEnabled':           'FTP Proxy',
  'JoinMode':             'Join Mode',
  'JoinModeFallback':     'Join Mode Fallback',
  'AuthMode':             'Authentication Mode',
  'NetworkName':          'Network Name',
  'SSID_STR':             'SSID',
  'SecurityType':         'Security Type',
  'PHYMode':              'PHY Mode',
  'NetworkNameVisible':   'Network Name Visible',
  'PowerEnabled':         'Power Enabled',
  'ChannelNumber':        'Channel Number',
  'AutoJoinDisabled':     'Auto-Join Disabled',
};

/// Keys whose value is a sub-dict rendered as an indented block.
const _kSubSectionKeys = {'IPv4', 'IPv6', 'Proxies', 'IEEE80211'};

/// Preferred render order for scalar service fields.
const _kServiceOrder = [
  'Type',
  'spnetworklocation_services_type',
  'Bsd Device Name',
  'BSD Device Name',
  'Hardware Address',
  'Hardware (MAC) Address',
];

/// Render order for sub-sections within each service.
const _kSubOrder = ['IPv4', 'IPv6', 'Proxies', 'IEEE80211'];

// ─────────────────────────────────────────────────────────────────────────────
// Formatters
// ─────────────────────────────────────────────────────────────────────────────

String _locLabel(String key) {
  if (_kLocationLabels.containsKey(key)) return _kLocationLabels[key]!;
  if (key.startsWith('spnetworklocation_')) {
    return formatKey(key.substring('spnetworklocation_'.length));
  }
  return formatKey(key);
}

String _svcLabel(String key) => _kServiceLabels[key] ?? formatKey(key);

String _subLabel(String key) => _kSubLabels[key] ?? formatKey(key);

String _val(dynamic v) {
  if (v == null) return '—';
  if (v is bool) return v ? 'Yes' : 'No';
  if (v is List) {
    if (v.isEmpty) return '—';
    return v
        .map((e) => e?.toString() ?? '')
        .where((s) => s.isNotEmpty)
        .join(', ');
  }
  if (v is String) {
    final l = v.toLowerCase();
    if (l == 'yes') return 'Yes';
    if (l == 'no') return 'No';
    final t = formatSpxValue(v);
    return t.isEmpty ? '—' : t;
  }
  return v.toString();
}

Map<String, dynamic> _asMap(dynamic m) => m is Map
    ? Map<String, dynamic>.fromEntries(
        m.entries.map((e) => MapEntry(e.key.toString(), e.value)))
    : <String, dynamic>{};

// ─────────────────────────────────────────────────────────────────────────────
// Public widget
// ─────────────────────────────────────────────────────────────────────────────

/// Renders [SPNetworkLocationDataType] as a hierarchical indented view
/// matching macOS System Information:
///
///   Automatic
///     Active Location   Yes
///     Services
///       ▾ Ethernet
///           Type                  Ethernet
///           BSD Device Name       en0
///           Hardware (MAC) Address 14:98:…
///           IPv4
///             Configuration Method  DHCP
///           IPv6
///             Configuration Method  Automatic
///           Proxies
///             Exceptions List   *.local, 169.254/16
///             FTP Passive Mode  Yes
///       ▾ Wi-Fi
///           …
class LocationsView extends StatefulWidget {
  final List<Map<String, dynamic>> items;
  final String searchQuery;

  const LocationsView({
    super.key,
    required this.items,
    this.searchQuery = '',
  });

  @override
  State<LocationsView> createState() => _LocationsViewState();
}

class _LocationsViewState extends State<LocationsView> {
  final _filterCtrl = TextEditingController();
  String _filter = '';

  /// Expanded service keys: "$locationIndex::$serviceName".
  final Set<String> _expanded = {};

  String get _q => _filter.isNotEmpty ? _filter : widget.searchQuery;

  // Layout constants
  static const double _step = 20.0;
  static const double _keyBase = 260.0;

  // ── Lifecycle ──────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _initExpanded();
  }

  @override
  void didUpdateWidget(LocationsView old) {
    super.didUpdateWidget(old);
    if (old.items != widget.items) {
      _expanded.clear();
      _initExpanded();
    }
  }

  void _initExpanded() {
    // Expand every service in every location by default.
    for (int i = 0; i < widget.items.length; i++) {
      for (final svc in _services(widget.items[i])) {
        _expanded.add(_svcKey(i, svc));
      }
    }
  }

  @override
  void dispose() {
    _filterCtrl.dispose();
    super.dispose();
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  List<Map<String, dynamic>> _services(Map<String, dynamic> item) {
    final raw = item['spnetworklocation_services'];
    if (raw is List) return raw.whereType<Map>().map(_asMap).toList();
    return [];
  }

  String _svcKey(int locIdx, Map<String, dynamic> svc) =>
      '$locIdx::${svc['_name'] ?? identityHashCode(svc)}';

  void _toggle(String key) => setState(() {
        if (_expanded.contains(key)) {
          _expanded.remove(key);
        } else {
          _expanded.add(key);
        }
      });

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final sp = context.watch<UiScaleProvider>();
    final cs = Theme.of(context).colorScheme;

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

        // ── Content ─────────────────────────────────────────────────────────
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
            children: [
              for (int i = 0; i < widget.items.length; i++) ...[
                if (i > 0)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child:
                        Divider(color: cs.outlineVariant.withAlpha(80), height: 1),
                  ),
                ..._buildLocation(i, widget.items[i], context, sp),
              ],
            ],
          ),
        ),
      ],
    );
  }

  // ── Location renderer ─────────────────────────────────────────────────────

  List<Widget> _buildLocation(
    int locIdx,
    Map<String, dynamic> item,
    BuildContext context,
    UiScaleProvider sp,
  ) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final q = _q;
    final kw = sp.sz(_keyBase);

    double keyW(double indent) => (kw - indent).clamp(60.0, double.infinity);

    final i1 = sp.sz(_step);
    final i2 = sp.sz(_step * 2);
    final i3 = sp.sz(_step * 3);
    final i4 = sp.sz(_step * 4);

    final rows = <Widget>[];

    // ── Location name (title) ───────────────────────────────────────────────
    final locName = item['_name']?.toString() ?? 'Location $locIdx';
    rows.add(Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 4),
      child: Text(
        locName,
        style: theme.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w600,
          color: cs.onSurface,
        ),
      ),
    ));

    // ── Active Location scalar ──────────────────────────────────────────────
    final active = item['spnetworklocation_is_active'];
    if (active != null) {
      final v = _val(active);
      if (q.isEmpty || _hit(q, 'Active Location', v)) {
        rows.add(_LeafRow(
          label: 'Active Location',
          value: v,
          indent: i1,
          keyWidth: keyW(i1),
          searchQuery: q,
          theme: theme,
          cs: cs,
        ));
      }
    }

    // ── Other location-level scalar fields (besides name / is_active / services) ─
    for (final e in item.entries) {
      if (isInternalKey(e.key)) continue;
      if (e.key == '_name') continue;
      if (e.key == 'spnetworklocation_is_active') continue;
      if (e.key == 'spnetworklocation_services') continue;
      if (e.value is Map || e.value is List) continue;
      final label = _locLabel(e.key);
      final v = _val(e.value);
      if (q.isNotEmpty && !_hit(q, label, v)) continue;
      rows.add(_LeafRow(
        label: label,
        value: v,
        indent: i1,
        keyWidth: keyW(i1),
        searchQuery: q,
        theme: theme,
        cs: cs,
      ));
    }

    // ── Services ────────────────────────────────────────────────────────────
    final svcs = _services(item);
    if (svcs.isEmpty) return rows;
    if (q.isNotEmpty && !_svcsMatch(q, svcs)) return rows;

    rows.add(Padding(
      padding: EdgeInsets.only(left: i1, top: 6, bottom: 2),
      child: Text(
        'Services',
        style: theme.textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w600,
          color: cs.onSurface,
        ),
      ),
    ));

    for (final svc in svcs) {
      final svcKey = _svcKey(locIdx, svc);
      final svcName = svc['_name']?.toString() ?? 'Unknown Service';
      if (q.isNotEmpty && !_svcMatch(q, svc)) continue;

      final expanded = _expanded.contains(svcKey);

      // Collapsible service header
      rows.add(Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _toggle(svcKey),
          borderRadius: BorderRadius.circular(4),
          child: Padding(
            padding: EdgeInsets.only(left: i2, top: 5, bottom: 3, right: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  expanded ? Icons.expand_more : Icons.chevron_right,
                  size: sp.sz(16),
                  color: cs.primary,
                ),
                const SizedBox(width: 4),
                Text(
                  svcName,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: cs.primary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ));

      if (!expanded) continue;

      // ── Scalar service fields ─────────────────────────────────────────────
      final seen = <String>{};

      void addRow(String key) {
        if (!svc.containsKey(key) || seen.contains(key)) return;
        final v = svc[key];
        if (v is Map || v is List) return;
        seen.add(key);
        final label = _svcLabel(key);
        final val = _val(v);
        if (q.isNotEmpty && !_hit(q, label, val)) return;
        rows.add(_LeafRow(
          label: label,
          value: val,
          indent: i3,
          keyWidth: keyW(i3),
          searchQuery: q,
          theme: theme,
          cs: cs,
        ));
      }

      // Ordered fields first
      for (final k in _kServiceOrder) addRow(k);

      // Remaining scalars (not sub-sections)
      for (final e in svc.entries) {
        if (isInternalKey(e.key) || e.key == '_name') continue;
        if (_kSubSectionKeys.contains(e.key)) continue;
        if (e.value is Map || e.value is List) continue;
        addRow(e.key);
      }

      // ── Sub-sections: IPv4, IPv6, Proxies, IEEE80211 ──────────────────────
      for (final subKey in _kSubOrder) {
        final raw = svc[subKey];
        if (raw == null) continue;
        final sub = _asMap(raw is Map ? raw : {});
        if (sub.isEmpty) continue;
        if (q.isNotEmpty && !_subMatch(q, subKey, sub)) continue;

        rows.add(Padding(
          padding: EdgeInsets.only(left: i3, top: 5, bottom: 2),
          child: Text(
            subKey,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: cs.primary,
            ),
          ),
        ));

        for (final e in sub.entries) {
          if (isInternalKey(e.key)) continue;
          final label = _subLabel(e.key);
          final val = _val(e.value);
          if (q.isNotEmpty && !_hit(q, label, val)) continue;
          rows.add(_LeafRow(
            label: label,
            value: val,
            indent: i4,
            keyWidth: keyW(i4),
            searchQuery: q,
            theme: theme,
            cs: cs,
          ));
        }
      }
    }

    return rows;
  }

  // ── Filter helpers ─────────────────────────────────────────────────────────

  bool _hit(String q, String label, String val) {
    final l = q.toLowerCase();
    return label.toLowerCase().contains(l) || val.toLowerCase().contains(l);
  }

  bool _subMatch(String q, String label, Map<String, dynamic> sub) {
    if (label.toLowerCase().contains(q.toLowerCase())) return true;
    for (final e in sub.entries) {
      if (_hit(q, _subLabel(e.key), _val(e.value))) return true;
    }
    return false;
  }

  bool _svcMatch(String q, Map<String, dynamic> svc) {
    final name = svc['_name']?.toString() ?? '';
    if (name.toLowerCase().contains(q.toLowerCase())) return true;
    for (final e in svc.entries) {
      if (isInternalKey(e.key) || e.key == '_name') continue;
      if (_kSubSectionKeys.contains(e.key)) {
        if (e.value is Map && _subMatch(q, e.key, _asMap(e.value))) return true;
      } else if (e.value is! Map && e.value is! List) {
        if (_hit(q, _svcLabel(e.key), _val(e.value))) return true;
      }
    }
    return false;
  }

  bool _svcsMatch(String q, List<Map<String, dynamic>> svcs) {
    if ('services'.contains(q.toLowerCase())) return true;
    return svcs.any((s) => _svcMatch(q, s));
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
      padding: EdgeInsets.only(left: indent, top: 4, bottom: 4),
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
// Search-highlight text
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
