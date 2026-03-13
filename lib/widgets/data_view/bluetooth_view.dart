import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../utils/key_formatter.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Label / value helpers
// ─────────────────────────────────────────────────────────────────────────────

const _kGroupNames = {
  'controller_properties': 'Bluetooth Controller',
  'device_connected': 'Connected Devices',
  'device_not_connected': 'Not Connected Devices',
};

String _formatGroupName(String raw) => _kGroupNames[raw] ?? formatKey(raw);

/// Strips `controller_` or `device_` prefixes, then passes through [formatKey].
String _fmtKey(String key) {
  for (final prefix in ['controller_', 'device_']) {
    if (key.startsWith(prefix)) return formatKey(key.substring(prefix.length));
  }
  return formatKey(key);
}

String _fmtVal(dynamic v) {
  if (v == null) return '—';
  if (v is bool) return v ? 'Yes' : 'No';
  if (v is DateTime) {
    return DateFormat('yyyy-MM-dd  HH:mm').format(v.toLocal());
  }
  if (v is String) return formatSpxValue(v);
  return v.toString();
}

/// Recursively flatten a value to a plain string for filter matching.
String _flatten(dynamic v) {
  if (v is List) return v.map(_flatten).join(' ');
  if (v is Map) return v.values.map(_flatten).join(' ');
  return _fmtVal(v);
}

// ─────────────────────────────────────────────────────────────────────────────
// Public widget
// ─────────────────────────────────────────────────────────────────────────────

/// Renders the SPBluetoothDataType section as stacked named groups (Controller,
/// Connected Devices, Not Connected Devices), each individually collapsible
/// with the same animated header used in Language & Region.
class BluetoothView extends StatefulWidget {
  final List<Map<String, dynamic>> items;
  final String searchQuery;

  const BluetoothView({
    super.key,
    required this.items,
    this.searchQuery = '',
  });

  @override
  State<BluetoothView> createState() => _BluetoothViewState();
}

class _BluetoothViewState extends State<BluetoothView> {
  final _filterCtrl = TextEditingController();
  String _filter = '';

  @override
  void dispose() {
    _filterCtrl.dispose();
    super.dispose();
  }

  String get _effectiveFilter =>
      _filter.isNotEmpty ? _filter : widget.searchQuery;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    // Bluetooth has exactly 1 item whose keys ARE the groups.
    final item =
        widget.items.isNotEmpty ? widget.items.first : <String, dynamic>{};

    // Render in a fixed order; skip keys not present in the data.
    const groupOrder = [
      'controller_properties',
      'device_connected',
      'device_not_connected',
    ];
    final groups = groupOrder.where((k) => item.containsKey(k)).toList();

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
              prefixIcon: const Icon(Icons.search, size: 18),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: cs.outlineVariant),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              suffixIcon: _filter.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.close, size: 16),
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

        // ── Groups ──────────────────────────────────────────────────────────
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            itemCount: groups.length,
            itemBuilder: (context, index) {
              final key = groups[index];
              return _BtGroupSection(
                groupKey: key,
                value: item[key],
                searchQuery: _effectiveFilter,
                showDivider: index < groups.length - 1,
              );
            },
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Top-level collapsible group  (Controller / Connected / Not Connected)
// ─────────────────────────────────────────────────────────────────────────────

class _BtGroupSection extends StatefulWidget {
  final String groupKey;
  final dynamic value;
  final String searchQuery;
  final bool showDivider;

  const _BtGroupSection({
    required this.groupKey,
    required this.value,
    required this.searchQuery,
    required this.showDivider,
  });

  @override
  State<_BtGroupSection> createState() => _BtGroupSectionState();
}

class _BtGroupSectionState extends State<_BtGroupSection>
    with SingleTickerProviderStateMixin {
  bool _expanded = true;

  late final AnimationController _animCtrl;
  late final Animation<double> _sizeFactor;
  late final Animation<double> _chevronTurns;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
      value: 1.0,
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
  void didUpdateWidget(_BtGroupSection old) {
    super.didUpdateWidget(old);
    if (widget.searchQuery.isNotEmpty && !_expanded) {
      setState(() => _expanded = true);
      _animCtrl.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final groupName = _formatGroupName(widget.groupKey);

    // ── Build the inner content and compute a visible item count ────────────
    final Widget content;
    int visibleCount;

    if (widget.value is Map) {
      // Controller properties — render as KV rows.
      final map = (widget.value as Map).cast<String, dynamic>();
      final entries =
          map.entries.where((e) => !isInternalKey(e.key)).toList();
      final visible = widget.searchQuery.isEmpty
          ? entries
          : entries.where((e) {
              final q = widget.searchQuery.toLowerCase();
              return _fmtKey(e.key).toLowerCase().contains(q) ||
                  _flatten(e.value).toLowerCase().contains(q);
            }).toList();

      if (visible.isEmpty && widget.searchQuery.isNotEmpty) {
        return const SizedBox.shrink();
      }

      visibleCount = visible.length;
      content = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: visible
            .map((e) => _BtKvRow(keyName: e.key, value: e.value))
            .toList(),
      );
    } else if (widget.value is List) {
      // Device list — each element is { "DeviceName": { ...props } }.
      final devices = (widget.value as List)
          .whereType<Map>()
          .map((m) => m.cast<String, dynamic>())
          .toList();
      final visible = widget.searchQuery.isEmpty
          ? devices
          : devices.where((d) {
              final q = widget.searchQuery.toLowerCase();
              return d.entries.any((e) {
                if (e.key.toString().toLowerCase().contains(q)) return true;
                return _flatten(e.value).toLowerCase().contains(q);
              });
            }).toList();

      if (visible.isEmpty && widget.searchQuery.isNotEmpty) {
        return const SizedBox.shrink();
      }

      visibleCount = visible.length;
      content = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: List.generate(visible.length, (i) {
          final d = visible[i];
          final name = d.keys.first;
          final props =
              d[name] is Map ? (d[name] as Map).cast<String, dynamic>() : <String, dynamic>{};
          return _BtDeviceSection(
            deviceName: name,
            props: props,
            searchQuery: widget.searchQuery,
            showDivider: i < visible.length - 1,
          );
        }),
      );
    } else {
      return const SizedBox.shrink();
    }

    // ── Render header + animated content ────────────────────────────────────
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
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
                      size: 20,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    groupName,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: cs.onSurface,
                    ),
                  ),
                  if (!_expanded) ...[
                    const SizedBox(width: 8),
                    Text(
                      '$visibleCount ${visibleCount == 1 ? 'item' : 'items'}',
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: cs.onSurfaceVariant),
                    ),
                  ],
                ],
              ),
            ),
          ),
          SizeTransition(
            sizeFactor: _sizeFactor,
            child: Padding(
              padding: const EdgeInsets.only(left: 26),
              child: content,
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
}

// ─────────────────────────────────────────────────────────────────────────────
// Device sub-section  (collapsible, one per BT device)
// ─────────────────────────────────────────────────────────────────────────────

class _BtDeviceSection extends StatefulWidget {
  final String deviceName;
  final Map<String, dynamic> props;
  final String searchQuery;
  final bool showDivider;

  const _BtDeviceSection({
    required this.deviceName,
    required this.props,
    required this.searchQuery,
    required this.showDivider,
  });

  @override
  State<_BtDeviceSection> createState() => _BtDeviceSectionState();
}

class _BtDeviceSectionState extends State<_BtDeviceSection>
    with SingleTickerProviderStateMixin {
  bool _expanded = true;

  late final AnimationController _animCtrl;
  late final Animation<double> _sizeFactor;
  late final Animation<double> _chevronTurns;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
      value: 1.0,
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
  void didUpdateWidget(_BtDeviceSection old) {
    super.didUpdateWidget(old);
    if (widget.searchQuery.isNotEmpty && !_expanded) {
      setState(() => _expanded = true);
      _animCtrl.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final entries = widget.props.entries
        .where((e) => !isInternalKey(e.key))
        .toList();

    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: entries.isNotEmpty ? _toggle : null,
            borderRadius: BorderRadius.circular(6),
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(vertical: 7, horizontal: 4),
              child: Row(
                children: [
                  if (entries.isNotEmpty)
                    RotationTransition(
                      turns: _chevronTurns,
                      child: Icon(
                        Icons.expand_more,
                        size: 18,
                        color: cs.primary,
                      ),
                    )
                  else
                    Icon(Icons.bluetooth, size: 18, color: cs.primary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      widget.deviceName,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: cs.onSurface,
                      ),
                    ),
                  ),
                  if (!_expanded && entries.isNotEmpty)
                    Text(
                      '${entries.length} field${entries.length == 1 ? '' : 's'}',
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: cs.onSurfaceVariant),
                    ),
                ],
              ),
            ),
          ),
          if (entries.isNotEmpty)
            SizeTransition(
              sizeFactor: _sizeFactor,
              child: Padding(
                padding: const EdgeInsets.only(left: 24, bottom: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: entries
                      .map((e) => _BtKvRow(keyName: e.key, value: e.value))
                      .toList(),
                ),
              ),
            ),
          if (widget.showDivider)
            Divider(
              indent: 0,
              endIndent: 0,
              color: cs.outlineVariant.withAlpha(80),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Plain key-value row
// ─────────────────────────────────────────────────────────────────────────────

class _BtKvRow extends StatelessWidget {
  final String keyName;
  final dynamic value;

  const _BtKvRow({required this.keyName, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 200,
            child: Text(
              _fmtKey(keyName),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: cs.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: SelectableText(
              _fmtVal(value),
              style: theme.textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}
