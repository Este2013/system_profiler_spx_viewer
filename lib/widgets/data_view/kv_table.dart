import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../providers/ui_scale_provider.dart';
import '../../utils/key_formatter.dart';
import '../highlight_text.dart';

/// Displays a single SPX item (Map) as a filterable key-value table.
class KvTable extends StatefulWidget {
  final Map<String, dynamic> item;
  final String searchQuery;
  /// Display name of the section that owns this item, used to suppress
  /// filtering when the global search matched the section name itself.
  final String sectionName;

  const KvTable({
    super.key,
    required this.item,
    this.searchQuery = '',
    this.sectionName = '',
  });

  @override
  State<KvTable> createState() => _KvTableState();
}

class _KvTableState extends State<KvTable> {
  final _filterController = TextEditingController();
  String _filter = '';

  bool _isNameMatch(String q) =>
      q.isNotEmpty &&
      widget.sectionName.isNotEmpty &&
      widget.sectionName.toLowerCase().contains(q.toLowerCase());

  void _syncLocalFilter(String q) {
    _filter = _isNameMatch(q) ? '' : q;
    _filterController.text = _filter;
  }

  /// Filtering uses only the local field; highlighting falls back to the
  /// global query so matches stay visible even when the filter is cleared.
  String get _highlightQuery =>
      _filter.isNotEmpty ? _filter : widget.searchQuery;

  @override
  void initState() {
    super.initState();
    _syncLocalFilter(widget.searchQuery);
  }

  @override
  void didUpdateWidget(covariant KvTable old) {
    super.didUpdateWidget(old);
    if (old.searchQuery != widget.searchQuery) {
      setState(() => _syncLocalFilter(widget.searchQuery));
    }
  }

  @override
  void dispose() {
    _filterController.dispose();
    super.dispose();
  }

  List<MapEntry<String, dynamic>> get _filteredEntries {
    final entries = widget.item.entries
        .where((e) => !isInternalKey(e.key) && e.key != '_name')
        .toList();

    if (_filter.isEmpty) return entries;

    final q = _filter.toLowerCase();
    return entries.where((e) {
      return formatKey(e.key).toLowerCase().contains(q) ||
          _flattenToString(e.value).toLowerCase().contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final sp = context.watch<UiScaleProvider>();
    final entries = _filteredEntries;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Filter bar
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: TextField(
            controller: _filterController,
            decoration: InputDecoration(
              isDense: true,
              hintText: 'Filter fields...',
              prefixIcon: Icon(Icons.search, size: sp.sz(18)),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: colorScheme.outlineVariant),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              suffixIcon: _filter.isNotEmpty
                  ? IconButton(
                      icon: Icon(Icons.close, size: sp.sz(16)),
                      onPressed: () {
                        _filterController.clear();
                        setState(() => _filter = '');
                      },
                    )
                  : null,
            ),
            onChanged: (v) => setState(() => _filter = v),
          ),
        ),

        if (entries.isEmpty)
          Expanded(
            child: Center(
              child: Text(
                'No matching fields',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          )
        else
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              itemCount: entries.length,
              separatorBuilder: (context, index) =>
                  Divider(height: 1, color: colorScheme.outlineVariant.withAlpha(80)),
              itemBuilder: (context, i) {
                final entry = entries[i];
                return _KvRow(
                  keyName: entry.key,
                  value: entry.value,
                  searchQuery: _highlightQuery,
                );
              },
            ),
          ),
      ],
    );
  }

  String _flattenToString(dynamic value) {
    if (value is List) {
      return value.map(_flattenToString).join(', ');
    }
    if (value is Map) {
      return value.values.map(_flattenToString).join(', ');
    }
    return value.toString();
  }
}

// ---------------------------------------------------------------------------

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

class _KvRowState extends State<_KvRow> with SingleTickerProviderStateMixin {
  bool _expanded = true;

  late final AnimationController _animCtrl;
  late final Animation<double> _sizeFactor;
  late final Animation<double> _chevronTurns;

  bool get _isComplex {
    if (widget.value is Map) return true;
    if (widget.value is List) {
      return (widget.value as List).any((e) => e is Map || e is List);
    }
    return false;
  }

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
      value: 1.0, // starts expanded
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
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final sp = context.watch<UiScaleProvider>();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Key column (fixed width)
          SizedBox(
            width: sp.sz(210),
            child: HighlightText(
              text:  formatKey(widget.keyName),
              query: widget.searchQuery,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Value column
          Expanded(
            child: _isComplex
                ? _buildComplexValue(context)
                : _buildSimpleValue(context),
          ),
        ],
      ),
    );
  }

  Widget _buildSimpleValue(BuildContext context) {
    final str = _formatSimple(widget.value);
    return HighlightText(
      text:  str,
      query: widget.searchQuery,
      style: Theme.of(context).textTheme.bodyMedium,
    );
  }

  Widget _buildComplexValue(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final sp = context.read<UiScaleProvider>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Animated header (same style as Language & Region groups) ───────
        InkWell(
          onTap: _toggle,
          borderRadius: BorderRadius.circular(6),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 2),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                RotationTransition(
                  turns: _chevronTurns,
                  child: Icon(Icons.expand_more, size: sp.sz(16), color: cs.primary),
                ),
                const SizedBox(width: 4),
                Text(
                  _expanded ? 'Collapse' : _summarizeComplex(widget.value),
                  style: theme.textTheme.bodySmall?.copyWith(color: cs.primary),
                ),
              ],
            ),
          ),
        ),
        // ── Animated content ───────────────────────────────────────────────
        SizeTransition(
          sizeFactor: _sizeFactor,
          child: Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: cs.outlineVariant.withAlpha(120)),
              ),
              child: _ComplexValueView(value: widget.value, depth: 0),
            ),
          ),
        ),
      ],
    );
  }

  String _summarizeComplex(dynamic value) {
    if (value is Map) return '${value.length} field${value.length != 1 ? 's' : ''}';
    if (value is List) return '${value.length} item${value.length != 1 ? 's' : ''}';
    return value.toString();
  }

  String _formatSimple(dynamic value) {
    if (value == null) return '—';
    if (value is bool) return value ? 'Yes' : 'No';
    if (value is DateTime) {
      return DateFormat('yyyy-MM-dd  HH:mm:ss').format(value.toLocal());
    }
    if (value is List) {
      if (value.every((e) => e is! Map && e is! List)) {
        return value.map((e) => formatSpxValue(e.toString())).join(', ');
      }
    }
    if (value is String) return formatSpxValue(value);
    return value.toString();
  }
}

// ---------------------------------------------------------------------------

class _ComplexValueView extends StatelessWidget {
  final dynamic value;
  final int depth;

  const _ComplexValueView({required this.value, required this.depth});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final sp = context.watch<UiScaleProvider>();

    if (value is Map<String, dynamic>) {
      final map = value as Map<String, dynamic>;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: map.entries
            .where((e) => !isInternalKey(e.key))
            .map((e) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: depth == 0 ? sp.sz(200) : sp.sz(150),
                        child: Text(
                          formatKey(e.key),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: (e.value is Map || e.value is List)
                            ? _ComplexValueView(value: e.value, depth: depth + 1)
                            : Text(
                                _fmt(e.value),
                                style: theme.textTheme.bodySmall,
                              ),
                      ),
                    ],
                  ),
                ))
            .toList(),
      );
    }

    if (value is List) {
      final list = value as List;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: list.map((item) {
          if (item is Map || item is List) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: colorScheme.outlineVariant.withAlpha(100),
                  ),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: _ComplexValueView(value: item, depth: depth + 1),
              ),
            );
          }
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 1),
            child: Text('• ${_fmt(item)}', style: theme.textTheme.bodySmall),
          );
        }).toList(),
      );
    }

    return Text(_fmt(value), style: theme.textTheme.bodySmall);
  }

  String _fmt(dynamic v) {
    if (v == null) return '—';
    if (v is bool) return v ? 'Yes' : 'No';
    if (v is DateTime) {
      return DateFormat('yyyy-MM-dd HH:mm:ss').format(v.toLocal());
    }
    return v.toString();
  }
}

