import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/ui_scale_provider.dart';
import '../../utils/key_formatter.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Label overrides  (verified against actual SPX XML)
// ─────────────────────────────────────────────────────────────────────────────

const _kLabels = <String, String>{
  // Top-level keys
  'spairport_airport_interfaces':                  'Interfaces',
  'spairport_software_information':                'Software Versions',
  // Software version keys inside spairport_software_information
  'spairport_corewlan_version':                    'CoreWLAN',
  'spairport_corewlankit_version':                 'CoreWLANKit',
  'spairport_extra_version':                       'Menu Extra',
  'spairport_profiler_version':                    'System Information',
  'spairport_family_version':                      'IO80211 Family',
  'spairport_diagnostics_version':                 'Diagnostics',
  'spairport_utility_version':                     'AirPort Utility',
  'spairport_net_prefs_version':                   'Network Preferences',
  // Interface scalar keys
  'spairport_wireless_card_type':                  'Card Type',
  'spairport_wireless_firmware_version':           'Firmware Version',
  'spairport_wireless_locale':                     'Locale',
  'spairport_wireless_country_code':               'Country Code',
  'spairport_wireless_mac_address':                'MAC Address',
  'spairport_supported_phymodes':                  'Supported PHY Modes',
  'spairport_supported_channels':                  'Supported Channels',
  'spairport_caps_wow':                            'Wake On Wireless',
  'spairport_caps_airdrop':                        'AirDrop',
  'spairport_caps_autounlock':                     'Auto Unlock',
  'spairport_caps_awdl':                           'AWDL',
  'spairport_status_information':                  'Status',
  // Sub-section header keys
  'spairport_current_network_information':         'Current Network Information',
  'spairport_airport_other_local_wireless_networks': 'Other Local Wi-Fi Networks',
  'spairport_airport_local_wireless_networks':     'Local Wi-Fi Networks',
  // Network detail keys (inside current/other network dicts)
  'spairport_network_phymode':                     'PHY Mode',
  'spairport_network_channel':                     'Channel',
  'spairport_network_bssid':                       'BSSID',
  'spairport_signal_noise':                        'Signal / Noise',
  'spairport_network_rate':                        'Transmit Rate',
  'spairport_network_mcs':                         'MCS Index',
  'spairport_network_type':                        'Network Type',
  'spairport_security_mode':                       'Security',
  'spairport_network_country_code':                'Country Code',
};

/// Human-readable security mode strings.
const _kSecurityModes = <String, String>{
  'spairport_security_mode_wpa2_personal':         'WPA2 Personal',
  'spairport_security_mode_wpa2_personal_mixed':   'WPA/WPA2 Personal',
  'spairport_security_mode_wpa2_enterprise':       'WPA2 Enterprise',
  'spairport_security_mode_wpa2_enterprise_mixed': 'WPA/WPA2 Enterprise',
  'spairport_security_mode_wpa3_personal':         'WPA3 Personal',
  'spairport_security_mode_wpa3_enterprise':       'WPA3 Enterprise',
  'spairport_security_mode_wpa_personal':          'WPA Personal',
  'spairport_security_mode_wpa_enterprise':        'WPA Enterprise',
  'spairport_security_mode_none':                  'None',
};

String _wLabel(String key) {
  if (key == '_name') return 'Name';
  if (_kLabels.containsKey(key)) return _kLabels[key]!;
  if (key.startsWith('spairport_')) {
    return formatKey(key.substring('spairport_'.length));
  }
  return formatKey(key);
}

String _wVal(dynamic v) {
  if (v == null) return '—';
  if (v is bool) return v ? 'Yes' : 'No';
  if (v is num) return v.toString();
  if (v is List) {
    if (v.isEmpty) return '—';
    if (v.every((e) => e is! Map)) {
      return v.map((e) => e?.toString() ?? '').where((s) => s.isNotEmpty).join(', ');
    }
    return '—';
  }
  if (v is String) {
    if (v.toLowerCase() == 'yes') return 'Yes';
    if (v.toLowerCase() == 'no') return 'No';
    // Card type: "spairport_wireless_card_type_wifi (0x14E4, 0x4378)" → "Wi-Fi (0x14E4, 0x4378)"
    if (v.startsWith('spairport_wireless_card_type_wifi')) {
      return 'Wi-Fi${v.substring('spairport_wireless_card_type_wifi'.length)}';
    }
    if (v.startsWith('spairport_wireless_card_type_')) {
      return formatKey(v.substring('spairport_wireless_card_type_'.length));
    }
    // Caps: spairport_caps_supported → "Supported"
    if (v == 'spairport_caps_supported')     return 'Supported';
    if (v == 'spairport_caps_not_supported') return 'Not Supported';
    if (v.startsWith('spairport_caps_')) {
      return formatKey(v.substring('spairport_caps_'.length));
    }
    // Status: spairport_status_connected → "Connected"
    if (v.startsWith('spairport_status_')) {
      return formatKey(v.substring('spairport_status_'.length));
    }
    // Network type: spairport_network_type_station → "Infrastructure"
    if (v == 'spairport_network_type_station') return 'Infrastructure';
    if (v.startsWith('spairport_network_type_')) {
      return formatKey(v.substring('spairport_network_type_'.length));
    }
    // Security modes
    if (_kSecurityModes.containsKey(v)) return _kSecurityModes[v]!;
    if (v.startsWith('spairport_security_mode_')) {
      return formatKey(v.substring('spairport_security_mode_'.length));
    }
    // Generic spairport_ catch-all → strip prefix and title-case
    if (v.startsWith('spairport_')) {
      return formatKey(v.substring('spairport_'.length));
    }
    final t = formatSpxValue(v);
    return t.isEmpty ? v : t;
  }
  return v.toString();
}

Map<String, dynamic> _asMap(dynamic m) => m is Map
    ? Map<String, dynamic>.fromEntries(
        m.entries.map((e) => MapEntry(e.key.toString(), e.value)))
    : <String, dynamic>{};

// ─────────────────────────────────────────────────────────────────────────────
// Preferred sub-section key ordering within an interface
// ─────────────────────────────────────────────────────────────────────────────

const _kSubOrder = [
  'spairport_current_network_information',
  'spairport_airport_other_local_wireless_networks',
  'spairport_airport_local_wireless_networks',
];

// ─────────────────────────────────────────────────────────────────────────────
// Public widget
// ─────────────────────────────────────────────────────────────────────────────

class WifiView extends StatefulWidget {
  final List<Map<String, dynamic>> items;
  final String searchQuery;

  const WifiView({
    super.key,
    required this.items,
    this.searchQuery = '',
  });

  @override
  State<WifiView> createState() => _WifiViewState();
}

class _WifiViewState extends State<WifiView> {
  final _filterCtrl = TextEditingController();
  String _filter = '';

  /// Expanded interface keys: "$itemIndex::$interfaceName".
  final Set<String> _expanded = {};

  String get _q => _filter.isNotEmpty ? _filter : widget.searchQuery;

  static const double _step    = 20.0;
  static const double _keyBase = 260.0;

  @override
  void initState() {
    super.initState();
    _initExpanded();
  }

  @override
  void didUpdateWidget(WifiView old) {
    super.didUpdateWidget(old);
    if (old.items != widget.items) {
      _expanded.clear();
      _initExpanded();
    }
  }

  void _initExpanded() {
    for (int i = 0; i < widget.items.length; i++) {
      for (final iface in _interfaces(widget.items[i])) {
        _expanded.add(_ifaceKey(i, iface));
      }
    }
  }

  @override
  void dispose() {
    _filterCtrl.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> _interfaces(Map<String, dynamic> item) {
    // Actual key in the SPX plist is spairport_airport_interfaces
    for (final key in ['spairport_airport_interfaces', 'spairport_interfaces', '_items']) {
      final raw = item[key];
      if (raw is List) return raw.whereType<Map>().map(_asMap).toList();
    }
    return [];
  }

  String _ifaceKey(int idx, Map<String, dynamic> iface) =>
      '$idx::${iface['_name'] ?? identityHashCode(iface)}';

  void _toggle(String key) => setState(() {
        if (_expanded.contains(key)) {
          _expanded.remove(key);
        } else {
          _expanded.add(key);
        }
      });

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final sp = context.watch<UiScaleProvider>();
    final cs = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
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
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
            children: [
              for (int i = 0; i < widget.items.length; i++) ...[
                if (i > 0)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Divider(color: cs.outlineVariant.withAlpha(80), height: 1),
                  ),
                ..._buildItem(i, widget.items[i], context, sp),
              ],
            ],
          ),
        ),
      ],
    );
  }

  // ── Item renderer ──────────────────────────────────────────────────────────

  List<Widget> _buildItem(
    int itemIdx,
    Map<String, dynamic> item,
    BuildContext context,
    UiScaleProvider sp,
  ) {
    final theme = Theme.of(context);
    final cs    = theme.colorScheme;
    final q     = _q;
    final kw    = sp.sz(_keyBase);

    double keyW(double indent) => (kw - indent).clamp(60.0, double.infinity);

    final i1 = sp.sz(_step);
    final i2 = sp.sz(_step * 2);
    final i3 = sp.sz(_step * 3);
    final i4 = sp.sz(_step * 4);
    final i5 = sp.sz(_step * 5);

    final rows = <Widget>[];

    // ── Item title (e.g. "Wi-Fi") ─────────────────────────────────────────
    final title = item['_name']?.toString() ?? 'Wi-Fi';
    rows.add(Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 4),
      child: Text(
        title,
        style: theme.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w600,
          color: cs.onSurface,
        ),
      ),
    ));

    // ── Software Versions ─────────────────────────────────────────────────
    // spairport_software_information is a flat dict:
    //   spairport_corewlan_version → "16.0 (1657)"
    //   spairport_extra_version    → "1.0 (19140.10)"   etc.
    final swRaw = item['spairport_software_information'];
    if (swRaw is Map) {
      final sw = _asMap(swRaw);
      final anyMatch = q.isEmpty || _mapScalarMatch(q, sw);
      if (sw.isNotEmpty && anyMatch) {
        rows.add(_SectionLabel(
          label: 'Software Versions',
          indent: i1, theme: theme, cs: cs, primary: false,
        ));
        for (final e in sw.entries) {
          if (isInternalKey(e.key) || e.key == '_name') continue;
          if (e.value is Map || e.value is List) continue;
          final label = _wLabel(e.key);
          final val   = _wVal(e.value);
          if (q.isNotEmpty && !_hit(q, label, val)) continue;
          rows.add(_KvRow(
            label: label, value: val, indent: i2,
            keyWidth: keyW(i2), searchQuery: q, theme: theme, cs: cs,
          ));
        }
      }
    }

    // ── Interfaces ────────────────────────────────────────────────────────
    final ifaces = _interfaces(item);
    if (ifaces.isEmpty) return rows;
    if (q.isNotEmpty && !_ifacesMatch(q, ifaces)) return rows;

    rows.add(_SectionLabel(
      label: 'Interfaces',
      indent: i1, theme: theme, cs: cs, primary: false,
    ));

    for (final iface in ifaces) {
      final key       = _ifaceKey(itemIdx, iface);
      final ifaceName = iface['_name']?.toString() ?? 'Interface';
      if (q.isNotEmpty && !_ifaceMatch(q, iface)) continue;

      final expanded = _expanded.contains(key);

      // Collapsible interface header
      rows.add(Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _toggle(key),
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
                  ifaceName,
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

      // ── Scalar + simple-list fields ──────────────────────────────────────
      for (final e in iface.entries) {
        if (isInternalKey(e.key) || e.key == '_name') continue;
        if (e.value is Map) continue;           // rendered as sub-section below
        if (e.value is List) {
          // Skip lists of dicts — rendered as sub-section below
          final list = e.value as List;
          if (list.isNotEmpty && list.first is Map) continue;
        }
        final label = _wLabel(e.key);
        final val   = _wVal(e.value);
        if (q.isNotEmpty && !_hit(q, label, val)) continue;
        rows.add(_KvRow(
          label: label, value: val, indent: i3,
          keyWidth: keyW(i3), searchQuery: q, theme: theme, cs: cs,
        ));
      }

      // ── Sub-sections (Map and List-of-dict values) ───────────────────────
      // Emit preferred-order first, then any remaining.
      final seenSub = <String>{};
      final subKeys = [
        ..._kSubOrder.where(iface.containsKey),
        ...iface.keys.where((k) {
          if (seenSub.contains(k)) return false;
          if (isInternalKey(k) || k == '_name') return false;
          if (_kSubOrder.contains(k)) return false;
          final v = iface[k];
          if (v is Map) return true;
          if (v is List) {
            return v.isNotEmpty && v.first is Map;
          }
          return false;
        }),
      ];

      for (final subKey in subKeys) {
        if (seenSub.contains(subKey)) continue;
        seenSub.add(subKey);

        final raw      = iface[subKey];
        final secLabel = _wLabel(subKey);

        if (raw is Map) {
          // ── Single network info dict (e.g. spairport_current_network_information)
          final sub = _asMap(raw);
          if (sub.isEmpty) continue;
          if (q.isNotEmpty && !_networkDictMatch(q, secLabel, sub)) continue;

          // SSID stored as _name inside the dict
          final ssid = sub['_name']?.toString();
          final header = (ssid != null && ssid.isNotEmpty)
              ? '$secLabel: $ssid'
              : secLabel;

          rows.add(_SectionLabel(
            label: header,
            indent: i3, theme: theme, cs: cs, primary: true,
          ));

          for (final e in sub.entries) {
            if (isInternalKey(e.key) || e.key == '_name') continue;
            if (e.value is Map || e.value is List) continue;
            final label = _wLabel(e.key);
            final val   = _wVal(e.value);
            if (q.isNotEmpty && !_hit(q, label, val)) continue;
            rows.add(_KvRow(
              label: label, value: val, indent: i4,
              keyWidth: keyW(i4), searchQuery: q, theme: theme, cs: cs,
            ));
          }
        } else if (raw is List) {
          // ── List of network dicts (e.g. spairport_airport_other_local_wireless_networks)
          final nets = raw.whereType<Map>().map(_asMap).toList();
          if (nets.isEmpty) continue;
          if (q.isNotEmpty && !_networkListMatch(q, secLabel, nets)) continue;

          rows.add(_SectionLabel(
            label: secLabel,
            indent: i3, theme: theme, cs: cs, primary: true,
          ));

          for (final net in nets) {
            final ssid = net['_name']?.toString() ?? '—';
            if (q.isNotEmpty && !_networkEntryMatch(q, ssid, net)) continue;

            rows.add(_SectionLabel(
              label: ssid,
              indent: i4, theme: theme, cs: cs, primary: false,
            ));

            for (final e in net.entries) {
              if (isInternalKey(e.key) || e.key == '_name') continue;
              if (e.value is Map || e.value is List) continue;
              final label = _wLabel(e.key);
              final val   = _wVal(e.value);
              if (q.isNotEmpty && !_hit(q, label, val)) continue;
              rows.add(_KvRow(
                label: label, value: val, indent: i5,
                keyWidth: keyW(i5), searchQuery: q, theme: theme, cs: cs,
              ));
            }
          }
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

  bool _mapScalarMatch(String q, Map<String, dynamic> m) {
    for (final e in m.entries) {
      if (isInternalKey(e.key)) continue;
      if (e.value is Map || e.value is List) continue;
      if (_hit(q, _wLabel(e.key), _wVal(e.value))) return true;
    }
    return false;
  }

  bool _networkDictMatch(String q, String label, Map<String, dynamic> sub) {
    if (label.toLowerCase().contains(q.toLowerCase())) return true;
    final ssid = sub['_name']?.toString() ?? '';
    if (ssid.toLowerCase().contains(q.toLowerCase())) return true;
    return _mapScalarMatch(q, sub);
  }

  bool _networkEntryMatch(String q, String ssid, Map<String, dynamic> net) {
    if (ssid.toLowerCase().contains(q.toLowerCase())) return true;
    return _mapScalarMatch(q, net);
  }

  bool _networkListMatch(
      String q, String label, List<Map<String, dynamic>> nets) {
    if (label.toLowerCase().contains(q.toLowerCase())) return true;
    return nets.any((n) => _networkEntryMatch(q, n['_name']?.toString() ?? '', n));
  }

  bool _ifaceMatch(String q, Map<String, dynamic> iface) {
    final name = iface['_name']?.toString() ?? '';
    if (name.toLowerCase().contains(q.toLowerCase())) return true;
    for (final e in iface.entries) {
      if (isInternalKey(e.key) || e.key == '_name') continue;
      if (e.value is Map) {
        if (_networkDictMatch(q, e.key, _asMap(e.value as Map))) return true;
      } else if (e.value is List) {
        final list = e.value as List;
        if (list.isNotEmpty && list.first is Map) {
          final nets = list.whereType<Map>().map(_asMap).toList();
          if (_networkListMatch(q, e.key, nets)) return true;
        } else {
          if (_hit(q, _wLabel(e.key), _wVal(e.value))) return true;
        }
      } else {
        if (_hit(q, _wLabel(e.key), _wVal(e.value))) return true;
      }
    }
    return false;
  }

  bool _ifacesMatch(String q, List<Map<String, dynamic>> ifaces) {
    if ('interfaces'.contains(q.toLowerCase())) return true;
    return ifaces.any((i) => _ifaceMatch(q, i));
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Section label
// ─────────────────────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  final double indent;
  final ThemeData theme;
  final ColorScheme cs;
  final bool primary;

  const _SectionLabel({
    required this.label,
    required this.indent,
    required this.theme,
    required this.cs,
    required this.primary,
  });

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.only(left: indent, top: 6, bottom: 2),
        child: Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: primary ? cs.primary : cs.onSurface,
          ),
        ),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Key-value row with optional highlight
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
                  color: cs.onSurfaceVariant,
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
      if (idx > start) spans.add(TextSpan(text: text.substring(start, idx)));
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
    if (start < text.length) spans.add(TextSpan(text: text.substring(start)));
    return SelectableText.rich(
        TextSpan(style: theme.textTheme.bodyMedium, children: spans));
  }
}
