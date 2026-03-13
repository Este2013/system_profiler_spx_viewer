import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../utils/key_formatter.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────────────────────

/// Formats raw log-item names like `install_log_description` → "Install Log".
String _formatLogName(String raw) {
  const suffix = '_description';
  final s =
      raw.endsWith(suffix) ? raw.substring(0, raw.length - suffix.length) : raw;
  return formatKey(s);
}

/// Human-readable byte size.
String _formatBytes(dynamic raw) {
  final bytes = raw is int ? raw : int.tryParse(raw?.toString() ?? '');
  if (bytes == null || bytes == 0) return '';
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
  return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
}

Map<String, dynamic>? _firstWithContent(List<Map<String, dynamic>> items) {
  for (final item in items) {
    if ((item['contents']?.toString() ?? '').isNotEmpty) return item;
  }
  return items.isEmpty ? null : items.first;
}

// ─────────────────────────────────────────────────────────────────────────────
// Public widget
// ─────────────────────────────────────────────────────────────────────────────

/// Two-pane log viewer.
/// Left: selectable list of log items (name, source, size).
/// Right: line-by-line content view with inline search/filter.
class LogViewer extends StatefulWidget {
  final List<Map<String, dynamic>> items;
  const LogViewer({super.key, required this.items});

  @override
  State<LogViewer> createState() => _LogViewerState();
}

class _LogViewerState extends State<LogViewer> {
  Map<String, dynamic>? _selected;

  @override
  void initState() {
    super.initState();
    _selected = _firstWithContent(widget.items);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Log list ───────────────────────────────────────────────────────
        SizedBox(
          width: 280,
          child: _ListPanel(
            items: widget.items,
            selected: _selected,
            onSelect: (item) => setState(() => _selected = item),
          ),
        ),

        VerticalDivider(width: 1, thickness: 1, color: cs.outlineVariant),

        // ── Content ────────────────────────────────────────────────────────
        Expanded(
          child: _selected == null
              ? Center(
                  child: Text(
                    'No logs available',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: cs.onSurface.withAlpha(100),
                        ),
                  ),
                )
              : _ContentPanel(
                  // ValueKey forces a fresh State when the selection changes,
                  // resetting scroll position and search query.
                  key: ValueKey(_selected!['_name']),
                  item: _selected!,
                ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Left panel – log list
// ─────────────────────────────────────────────────────────────────────────────

class _ListPanel extends StatelessWidget {
  final List<Map<String, dynamic>> items;
  final Map<String, dynamic>? selected;
  final ValueChanged<Map<String, dynamic>> onSelect;

  const _ListPanel({
    required this.items,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      color: cs.surfaceContainerLow,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 6),
        itemCount: items.length,
        itemBuilder: (context, index) =>
            _LogRow(item: items[index], selected: selected, onSelect: onSelect),
      ),
    );
  }
}

class _LogRow extends StatelessWidget {
  final Map<String, dynamic> item;
  final Map<String, dynamic>? selected;
  final ValueChanged<Map<String, dynamic>> onSelect;

  const _LogRow({
    required this.item,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isSel = selected == item;
    final name = _formatLogName(item['_name']?.toString() ?? '');
    final source = item['source']?.toString() ?? '';
    final sizeStr = _formatBytes(item['byteSize']);
    final hasContent = (item['contents']?.toString() ?? '').isNotEmpty;

    return Material(
      color: isSel ? cs.primaryContainer : Colors.transparent,
      child: InkWell(
        onTap: () => onSelect(item),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 7, 10, 7),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Icon
              Icon(
                Icons.description_outlined,
                size: 15,
                color: isSel
                    ? cs.primary
                    : (hasContent
                        ? cs.onSurfaceVariant
                        : cs.onSurface.withAlpha(60)),
              ),
              const SizedBox(width: 8),

              // Name + source
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight:
                            isSel ? FontWeight.w600 : FontWeight.normal,
                        color: isSel
                            ? cs.onPrimaryContainer
                            : (hasContent
                                ? cs.onSurface
                                : cs.onSurface.withAlpha(90)),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (source.isNotEmpty)
                      Text(
                        source,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: isSel
                              ? cs.onPrimaryContainer.withAlpha(160)
                              : cs.onSurfaceVariant,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),

              // Size badge
              if (sizeStr.isNotEmpty) ...[
                const SizedBox(width: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: isSel
                        ? cs.onPrimaryContainer.withAlpha(30)
                        : cs.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    sizeStr,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: isSel
                          ? cs.onPrimaryContainer
                          : cs.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Right panel – content viewer
// ─────────────────────────────────────────────────────────────────────────────

class _ContentPanel extends StatefulWidget {
  final Map<String, dynamic> item;
  const _ContentPanel({super.key, required this.item});

  @override
  State<_ContentPanel> createState() => _ContentPanelState();
}

class _ContentPanelState extends State<_ContentPanel> {
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';
  bool _copied = false;

  /// Pre-split lines (cached; large files split once).
  late final List<String> _allLines;

  @override
  void initState() {
    super.initState();
    final raw = widget.item['contents']?.toString() ?? '';
    _allLines = raw.isEmpty ? const [] : raw.split('\n');
    _searchCtrl.addListener(() {
      setState(() => _searchQuery = _searchCtrl.text);
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  /// Returns the lines to display, optionally filtered by search query.
  List<({int lineNum, String text})> get _visible {
    if (_searchQuery.isEmpty) {
      return [
        for (var i = 0; i < _allLines.length; i++)
          (lineNum: i + 1, text: _allLines[i]),
      ];
    }
    final q = _searchQuery.toLowerCase();
    return [
      for (var i = 0; i < _allLines.length; i++)
        if (_allLines[i].toLowerCase().contains(q))
          (lineNum: i + 1, text: _allLines[i]),
    ];
  }

  Future<void> _copyContent() async {
    final lines = _visible;
    final text = lines.map((l) => l.text).join('\n');
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    setState(() => _copied = true);
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) setState(() => _copied = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final name = _formatLogName(widget.item['_name']?.toString() ?? '');
    final source = widget.item['source']?.toString() ?? '';
    final sizeStr = _formatBytes(widget.item['byteSize']);
    final lastMod = widget.item['lastModified'];
    String? dateStr;
    if (lastMod is DateTime) {
      dateStr =
          DateFormat('yyyy-MM-dd  HH:mm').format(lastMod.toLocal());
    }

    final isEmpty = _allLines.isEmpty;
    final visible = isEmpty ? <({int lineNum, String text})>[] : _visible;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Header ─────────────────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.fromLTRB(16, 10, 12, 8),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: cs.outlineVariant, width: 0.5),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Icon(Icons.description_outlined, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (source.isNotEmpty || dateStr != null)
                      Text(
                        [
                          if (source.isNotEmpty) source,
                          if (dateStr != null) dateStr,
                        ].join('  ·  '),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
              // Chips
              if (sizeStr.isNotEmpty) ...[
                _Chip(sizeStr, cs, theme),
                const SizedBox(width: 6),
              ],
              if (!isEmpty) ...[
                _Chip('${_allLines.length} lines', cs, theme),
                const SizedBox(width: 6),
              ],
              // Copy button
              if (!isEmpty)
                Tooltip(
                  message: _searchQuery.isEmpty
                      ? 'Copy all content'
                      : 'Copy filtered lines',
                  child: TextButton.icon(
                    onPressed: _copyContent,
                    icon: Icon(
                      _copied ? Icons.check : Icons.copy_outlined,
                      size: 15,
                    ),
                    label: Text(_copied ? 'Copied' : 'Copy'),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      textStyle: theme.textTheme.labelMedium,
                    ),
                  ),
                ),
            ],
          ),
        ),

        // ── Search bar ─────────────────────────────────────────────────────
        if (!isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: cs.surfaceContainerLowest,
              border: Border(
                bottom: BorderSide(color: cs.outlineVariant, width: 0.5),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchCtrl,
                    style: theme.textTheme.bodySmall,
                    decoration: InputDecoration(
                      hintText: 'Filter lines…',
                      hintStyle: theme.textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                      prefixIcon: Padding(
                        padding: const EdgeInsets.only(left: 10, right: 6),
                        child: Icon(Icons.search, size: 15,
                            color: cs.onSurfaceVariant),
                      ),
                      prefixIconConstraints: const BoxConstraints(
                          minWidth: 32, minHeight: 32),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 15),
                              onPressed: _searchCtrl.clear,
                              splashRadius: 14,
                            )
                          : null,
                      isDense: true,
                      contentPadding:
                          const EdgeInsets.symmetric(vertical: 7),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: cs.outline),
                      ),
                    ),
                  ),
                ),
                if (_searchQuery.isNotEmpty) ...[
                  const SizedBox(width: 10),
                  Text(
                    '${visible.length} match${visible.length == 1 ? '' : 'es'}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),

        // ── Log lines ──────────────────────────────────────────────────────
        Expanded(
          child: isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.inbox_outlined,
                          size: 48, color: cs.onSurface.withAlpha(50)),
                      const SizedBox(height: 12),
                      Text(
                        'No log entries',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: cs.onSurface.withAlpha(100),
                        ),
                      ),
                    ],
                  ),
                )
              : visible.isEmpty
                  ? Center(
                      child: Text(
                        'No lines matching "$_searchQuery"',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: cs.onSurface.withAlpha(120),
                        ),
                      ),
                    )
                  : _LineList(
                      lines: visible,
                      searchQuery: _searchQuery,
                    ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Log line list
// ─────────────────────────────────────────────────────────────────────────────

class _LineList extends StatelessWidget {
  final List<({int lineNum, String text})> lines;
  final String searchQuery;

  const _LineList({required this.lines, required this.searchQuery});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final monoStyle = TextStyle(
      fontFamily: 'Courier New, Courier, monospace',
      fontSize: 11.5,
      height: 1.55,
      color: cs.onSurface,
    );
    final gutterStyle = monoStyle.copyWith(
      color: cs.onSurface.withAlpha(55),
    );
    final highlightBg = cs.tertiaryContainer;
    final highlightFg = cs.onTertiaryContainer;

    // Width hint for the line-number gutter (based on total lines).
    final maxLineNum = lines.last.lineNum;
    final gutterWidth = maxLineNum >= 100000
        ? 54.0
        : maxLineNum >= 10000
            ? 46.0
            : maxLineNum >= 1000
                ? 38.0
                : 32.0;

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 6),
      itemCount: lines.length,
      itemBuilder: (context, index) {
        final line = lines[index];
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Line-number gutter
              SizedBox(
                width: gutterWidth,
                child: Text(
                  '${line.lineNum}',
                  textAlign: TextAlign.right,
                  style: gutterStyle,
                ),
              ),
              const SizedBox(width: 10),
              // Line content
              Expanded(
                child: searchQuery.isEmpty
                    ? SelectableText(line.text, style: monoStyle)
                    : _HighlightLine(
                        text: line.text,
                        query: searchQuery,
                        baseStyle: monoStyle,
                        highlightBg: highlightBg,
                        highlightFg: highlightFg,
                      ),
              ),
              const SizedBox(width: 8),
            ],
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _HighlightLine extends StatelessWidget {
  final String text;
  final String query;
  final TextStyle baseStyle;
  final Color highlightBg;
  final Color highlightFg;

  const _HighlightLine({
    required this.text,
    required this.query,
    required this.baseStyle,
    required this.highlightBg,
    required this.highlightFg,
  });

  @override
  Widget build(BuildContext context) {
    final spans = <TextSpan>[];
    final lower = text.toLowerCase();
    final lowerQ = query.toLowerCase();
    int start = 0;
    while (true) {
      final idx = lower.indexOf(lowerQ, start);
      if (idx == -1) {
        spans.add(TextSpan(text: text.substring(start)));
        break;
      }
      if (idx > start) spans.add(TextSpan(text: text.substring(start, idx)));
      spans.add(TextSpan(
        text: text.substring(idx, idx + query.length),
        style: baseStyle.copyWith(
          backgroundColor: highlightBg,
          color: highlightFg,
          fontWeight: FontWeight.w700,
        ),
      ));
      start = idx + query.length;
    }
    return Text.rich(TextSpan(style: baseStyle, children: spans));
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _Chip extends StatelessWidget {
  final String label;
  final ColorScheme cs;
  final ThemeData theme;
  const _Chip(this.label, this.cs, this.theme);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: cs.secondaryContainer,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: cs.onSecondaryContainer,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
