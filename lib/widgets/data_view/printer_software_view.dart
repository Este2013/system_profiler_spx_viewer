import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/ui_scale_provider.dart';
import '../../utils/key_formatter.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Label helpers
// ─────────────────────────────────────────────────────────────────────────────

const _kCategoryLabels = <String, String>{
  'ppds':                    'PPDs',
  'printers':                'Printers',
  'image capture devices':   'Image Capture Devices',
  'image capture support':   'Image Capture Support',
};

String _categoryLabel(String raw) => _kCategoryLabels[raw] ?? formatKey(raw);

String _valueStr(dynamic v) {
  if (v == null) return '—';
  if (v is bool) return v ? 'Yes' : 'No';
  if (v is List) return v.isEmpty ? '—' : v.join(', ');
  if (v is Map) return '{${v.length}}';
  return v.toString();
}

// ─────────────────────────────────────────────────────────────────────────────
// Widget
// ─────────────────────────────────────────────────────────────────────────────

/// Renders SPPrintersSoftwareDataType.
///
/// The section's items are category wrappers (ppds, printers,
/// image capture devices / support); each has an array of child dicts.
/// This view shows each non-empty category as a collapsible section with
/// its children listed as key-value rows.
class PrinterSoftwareView extends StatefulWidget {
  final List<Map<String, dynamic>> items;
  final String searchQuery;

  const PrinterSoftwareView({
    super.key,
    required this.items,
    this.searchQuery = '',
  });

  @override
  State<PrinterSoftwareView> createState() => _PrinterSoftwareViewState();
}

class _PrinterSoftwareViewState extends State<PrinterSoftwareView> {
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

        // ── Category sections ────────────────────────────────────────────────
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            itemCount: widget.items.length,
            itemBuilder: (context, i) => _CategorySection(
              item:        widget.items[i],
              searchQuery: _q,
              showDivider: i < widget.items.length - 1,
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Category section (collapsible)
// ─────────────────────────────────────────────────────────────────────────────

class _CategorySection extends StatefulWidget {
  final Map<String, dynamic> item;
  final String searchQuery;
  final bool showDivider;

  const _CategorySection({
    required this.item,
    required this.searchQuery,
    required this.showDivider,
  });

  @override
  State<_CategorySection> createState() => _CategorySectionState();
}

class _CategorySectionState extends State<_CategorySection>
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
    _sizeFactor    = CurvedAnimation(parent: _animCtrl, curve: Curves.easeInOut);
    _chevronTurns  = Tween<double>(begin: -0.25, end: 0.0).animate(
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
  void didUpdateWidget(_CategorySection old) {
    super.didUpdateWidget(old);
    if (widget.searchQuery.isNotEmpty && !_expanded) {
      setState(() => _expanded = true);
      _animCtrl.forward();
    }
  }

  /// Extract the children list for this category.
  List<Map<String, dynamic>> _children() {
    final categoryKey = widget.item['_name']?.toString() ?? '';
    final raw = widget.item[categoryKey];
    if (raw is List) {
      return raw.whereType<Map>()
          .map((m) => Map<String, dynamic>.fromEntries(
                m.entries.map((e) => MapEntry(e.key.toString(), e.value))))
          .toList();
    }
    return [];
  }

  @override
  Widget build(BuildContext context) {
    final theme    = Theme.of(context);
    final cs       = theme.colorScheme;
    final sp       = context.watch<UiScaleProvider>();
    final q        = widget.searchQuery;

    final categoryKey  = widget.item['_name']?.toString() ?? '';
    final categoryName = _categoryLabel(categoryKey);
    final children     = _children();

    // Filter children that match the query.
    final filtered = q.isEmpty
        ? children
        : children.where((child) {
            final lower = q.toLowerCase();
            return categoryName.toLowerCase().contains(lower) ||
                child.values.any((v) =>
                    _valueStr(v).toLowerCase().contains(lower)) ||
                child.keys.any((k) =>
                    formatKey(k).toLowerCase().contains(lower));
          }).toList();

    // Hide category entirely when nothing matches a search.
    if (q.isNotEmpty && filtered.isEmpty &&
        !categoryName.toLowerCase().contains(q.toLowerCase())) {
      return const SizedBox.shrink();
    }

    final badge = children.isEmpty ? 'None' : '${children.length} item${children.length == 1 ? '' : 's'}';

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Collapsible header ─────────────────────────────────────────
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
                      size: sp.sz(20),
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      categoryName,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: cs.onSurface,
                      ),
                    ),
                  ),
                  Text(
                    _expanded ? '' : badge,
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: cs.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ),

          // ── Animated content ───────────────────────────────────────────
          SizeTransition(
            sizeFactor: _sizeFactor,
            child: Padding(
              padding: const EdgeInsets.only(left: 26, bottom: 4),
              child: children.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Text(
                        'None',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: cs.onSurfaceVariant,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: filtered.map((child) =>
                          _ChildItem(child: child, searchQuery: q),
                      ).toList(),
                    ),
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
// Child item (key-value block)
// ─────────────────────────────────────────────────────────────────────────────

class _ChildItem extends StatelessWidget {
  final Map<String, dynamic> child;
  final String searchQuery;

  const _ChildItem({required this.child, required this.searchQuery});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs    = theme.colorScheme;
    final sp    = context.watch<UiScaleProvider>();

    final entries = child.entries
        .where((e) => !isInternalKey(e.key) && e.key != '_name')
        .toList();

    final name = child['_name']?.toString();

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (name != null && name.isNotEmpty) ...[
            Text(
              name,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(height: 4),
          ],
          ...entries.map((e) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: sp.sz(200),
                      child: Text(
                        formatKey(e.key),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color:      cs.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SelectableText(
                        _valueStr(e.value),
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}
