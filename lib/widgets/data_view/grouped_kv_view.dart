import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../utils/key_formatter.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Label helpers — specific to sections that use grouped KV layout
// ─────────────────────────────────────────────────────────────────────────────

/// Human-readable overrides for known macOS group names (the `_name` values).
const _kGroupNames = {
  'user_settings': 'User Settings',
  'system_settings': 'System Settings',
  'recovery_os_settings': 'Recovery Partition Settings',
};

String _formatGroupName(String raw) =>
    _kGroupNames[raw] ?? formatKey(raw);

/// Human-readable overrides for keys inside SPInternationalDataType items.
/// Keys not listed here have their `user_` / `system_` / `boot_` prefix
/// stripped and are passed through [formatKey].
const _kKeyNames = {
  'user_assistant_language': 'Siri Language',
  'user_assistant_voice_gender': 'Siri Voice Gender',
  'user_assistant_voice_language': 'Siri Voice Language',
  'linguistic_data_assets_requested': 'Requested Linguistic Assets',
  'user_app_language_overrides': 'Application Language Overrides',
  'system_country': 'Country Code',
  'system_interface_languages': 'OS Interface Languages',
  'system_languages': 'System Preferred Interface Languages',
  'boot_kbd': 'Keyboard Code',
};

String _fmtKey(String key) {
  if (_kKeyNames.containsKey(key)) return _kKeyNames[key]!;
  for (final prefix in ['user_', 'system_', 'boot_']) {
    if (key.startsWith(prefix)) {
      return formatKey(key.substring(prefix.length));
    }
  }
  return formatKey(key);
}

// ─────────────────────────────────────────────────────────────────────────────
// Value helpers
// ─────────────────────────────────────────────────────────────────────────────

String _fmtScalar(dynamic v) {
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
  return _fmtScalar(v);
}

// ─────────────────────────────────────────────────────────────────────────────
// Public widget
// ─────────────────────────────────────────────────────────────────────────────

/// Renders a multi-item section as stacked named groups, each with its own
/// key-value rows.  Suitable for sections like Language & Region where the
/// items represent logical sub-groups rather than peer table rows.
class GroupedKvView extends StatefulWidget {
  final List<Map<String, dynamic>> items;
  final String searchQuery;

  const GroupedKvView({
    super.key,
    required this.items,
    this.searchQuery = '',
  });

  @override
  State<GroupedKvView> createState() => _GroupedKvViewState();
}

class _GroupedKvViewState extends State<GroupedKvView> {
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

        // ── Groups ─────────────────────────────────────────────────────────
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            itemCount: widget.items.length,
            itemBuilder: (context, index) => _GroupSection(
              item: widget.items[index],
              searchQuery: _effectiveFilter,
              showDivider: index < widget.items.length - 1,
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Group section  (collapsible)
// ─────────────────────────────────────────────────────────────────────────────

class _GroupSection extends StatefulWidget {
  final Map<String, dynamic> item;
  final String searchQuery;
  final bool showDivider;

  const _GroupSection({
    required this.item,
    required this.searchQuery,
    required this.showDivider,
  });

  @override
  State<_GroupSection> createState() => _GroupSectionState();
}

class _GroupSectionState extends State<_GroupSection>
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
      value: 1.0, // starts expanded
    );
    _sizeFactor = CurvedAnimation(
      parent: _animCtrl,
      curve: Curves.easeInOut,
    );
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

  // Auto-expand when a search query reveals hidden rows.
  @override
  void didUpdateWidget(_GroupSection old) {
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

    final groupName = _formatGroupName(widget.item['_name']?.toString() ?? '');

    final entries = widget.item.entries
        .where((e) => !isInternalKey(e.key))
        .toList();

    final visible = widget.searchQuery.isEmpty
        ? entries
        : entries.where((e) {
            final q = widget.searchQuery.toLowerCase();
            return _fmtKey(e.key).toLowerCase().contains(q) ||
                _flatten(e.value).toLowerCase().contains(q);
          }).toList();

    // Hide group entirely when nothing matches a search.
    if (visible.isEmpty && widget.searchQuery.isNotEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Clickable header ────────────────────────────────────────────
          InkWell(
            onTap: _toggle,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
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
                      '${visible.length} field${visible.length == 1 ? '' : 's'}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // ── Animated rows ───────────────────────────────────────────────
          SizeTransition(
            sizeFactor: _sizeFactor,
            child: Padding(
              padding: const EdgeInsets.only(left: 26),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: visible
                    .map((e) => _KvRow(
                          keyName: e.key,
                          value: e.value,
                          searchQuery: widget.searchQuery,
                        ))
                    .toList(),
              ),
            ),
          ),

          // ── Divider between groups ──────────────────────────────────────
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
// KV row
// ─────────────────────────────────────────────────────────────────────────────

class _KvRow extends StatefulWidget {
  final String keyName;
  final dynamic value;
  final String searchQuery;

  const _KvRow({
    required this.keyName,
    required this.value,
    this.searchQuery = '',
  });

  @override
  State<_KvRow> createState() => _KvRowState();
}

class _KvRowState extends State<_KvRow> {
  bool _expanded = false;

  /// True when the value should be rendered as a collapsible sub-table.
  /// Small dicts (≤ 8 entries) start auto-expanded; large ones start collapsed.
  bool get _isDict => widget.value is Map;
  bool get _isList => widget.value is List;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    // ── Decide rendering strategy ─────────────────────────────────────────
    final Widget valueWidget;
    if (_isDict) {
      final map = (widget.value as Map<dynamic, dynamic>).cast<String, dynamic>();
      // Auto-expand small dicts; keep larger ones collapsed.
      if (!_expanded && map.length <= 8) {
        // Trigger expansion on first build.
        WidgetsBinding.instance.addPostFrameCallback(
          (_) { if (mounted) setState(() => _expanded = true); },
        );
      }
      valueWidget = _buildDictValue(context, map, cs, theme);
    } else if (_isList) {
      final list = widget.value as List;
      final allScalar = list.every((e) => e is! Map && e is! List);
      valueWidget = allScalar
          ? _buildScalarValue(
              context,
              list.map((e) => formatSpxValue(e.toString())).join(', '),
              theme,
            )
          : _buildExpandable(
              context,
              summary: '${list.length} item${list.length == 1 ? '' : 's'}',
              child: _ListInline(list: list),
              cs: cs,
              theme: theme,
            );
    } else {
      valueWidget = _buildScalarValue(
          context, _fmtScalar(widget.value), theme);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Key label
          SizedBox(
            width: 220,
            child: Text(
              _fmtKey(widget.keyName),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: cs.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Value
          Expanded(child: valueWidget),
        ],
      ),
    );
  }

  Widget _buildScalarValue(
      BuildContext context, String text, ThemeData theme) {
    if (widget.searchQuery.isNotEmpty) {
      return _HighlightText(text: text, query: widget.searchQuery);
    }
    return SelectableText(text, style: theme.textTheme.bodyMedium);
  }

  Widget _buildDictValue(
    BuildContext context,
    Map<String, dynamic> map,
    ColorScheme cs,
    ThemeData theme,
  ) {
    if (_expanded) {
      return Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
          border:
              Border.all(color: cs.outlineVariant.withAlpha(120)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: map.entries
              .where((e) => !isInternalKey(e.key))
              .map(
                (e) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 160,
                        child: Text(
                          e.key, // bundle IDs etc. — keep as-is
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: cs.onSurfaceVariant,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _fmtScalar(e.value),
                          style: theme.textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),
                ),
              )
              .toList(),
        ),
      );
    }

    return _buildExpandable(
      context,
      summary: '${map.length} field${map.length == 1 ? '' : 's'}',
      child: _DictInline(map: map),
      cs: cs,
      theme: theme,
    );
  }

  Widget _buildExpandable(
    BuildContext context, {
    required String summary,
    required Widget child,
    required ColorScheme cs,
    required ThemeData theme,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => setState(() => _expanded = !_expanded),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _expanded ? Icons.expand_less : Icons.expand_more,
                size: 16,
                color: cs.primary,
              ),
              const SizedBox(width: 4),
              Text(
                _expanded ? 'Collapse' : summary,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: cs.primary),
              ),
            ],
          ),
        ),
        if (_expanded) ...[
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                  color: cs.outlineVariant.withAlpha(120)),
            ),
            child: child,
          ),
        ],
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Inline renderers for complex values
// ─────────────────────────────────────────────────────────────────────────────

class _DictInline extends StatelessWidget {
  final Map<String, dynamic> map;
  const _DictInline({required this.map});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: map.entries
          .where((e) => !isInternalKey(e.key))
          .map(
            (e) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 160,
                    child: Text(
                      e.key,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _fmtScalar(e.value),
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}

class _ListInline extends StatelessWidget {
  final List<dynamic> list;
  const _ListInline({required this.list});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: list
          .map(
            (item) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 1),
              child: Text(
                '• ${_fmtScalar(item)}',
                style: theme.textTheme.bodySmall,
              ),
            ),
          )
          .toList(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Highlight text
// ─────────────────────────────────────────────────────────────────────────────

class _HighlightText extends StatelessWidget {
  final String text;
  final String query;
  const _HighlightText({required this.text, required this.query});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
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
        TextSpan(style: theme.textTheme.bodyMedium, children: spans));
  }
}
