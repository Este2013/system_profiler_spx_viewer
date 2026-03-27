import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/split_pane_provider.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Vertical split (left | right)
// ─────────────────────────────────────────────────────────────────────────────

/// A two-pane horizontal split with a shared, draggable divider.
///
/// The left-panel width is stored in [SplitPaneProvider] so all split views
/// share the same position.  Min widths are enforced on both sides.
class ResizableSplit extends StatelessWidget {
  final Widget left;
  final Widget right;

  static const double _handleW = 10.0;

  const ResizableSplit({
    super.key,
    required this.left,
    required this.right,
  });

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SplitPaneProvider>();

    return LayoutBuilder(
      builder: (context, constraints) {
        final totalW    = constraints.maxWidth;
        final available = totalW - _handleW;
        // Clamp stored width to valid range given current total width.
        final leftW = provider.treeWidth.clamp(
          SplitPaneProvider.minLeft,
          (available - SplitPaneProvider.minRight)
              .clamp(SplitPaneProvider.minLeft, double.infinity),
        );

        return Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(width: leftW, child: left),
            _SplitHandle(
              onDragUpdate: (dx) =>
                  context.read<SplitPaneProvider>().setWidth(leftW + dx, available),
            ),
            Expanded(child: right),
          ],
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Drag handle
// ─────────────────────────────────────────────────────────────────────────────

class _SplitHandle extends StatefulWidget {
  final ValueChanged<double> onDragUpdate;

  const _SplitHandle({required this.onDragUpdate});

  @override
  State<_SplitHandle> createState() => _SplitHandleState();
}

class _SplitHandleState extends State<_SplitHandle> {
  bool _hovered  = false;
  bool _dragging = false;

  bool get _active => _hovered || _dragging;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    // Grip line colour: subtle at rest, more visible on hover/drag.
    final lineColor = _active
        ? cs.onSurface.withAlpha(130)
        : cs.onSurface.withAlpha(45);

    // Background: just slightly tinted when active.
    final bgColor = _active
        ? cs.surfaceContainerHigh
        : cs.surfaceContainerLow;

    return MouseRegion(
      cursor: SystemMouseCursors.resizeColumn,
      onEnter: (_) => setState(() => _hovered  = true),
      onExit:  (_) => setState(() => _hovered  = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onHorizontalDragStart:  (_) => setState(() => _dragging = true),
        onHorizontalDragEnd:    (_) => setState(() => _dragging = false),
        onHorizontalDragUpdate: (d) => widget.onDragUpdate(d.delta.dx),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          width:  ResizableSplit._handleW,
          color:  bgColor,
          child:  Center(
            child: _DoubleLinePip(color: lineColor),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Double-line pip
// ─────────────────────────────────────────────────────────────────────────────

/// Two short parallel vertical bars — the classic resize-handle indicator.
class _DoubleLinePip extends StatelessWidget {
  final Color color;

  const _DoubleLinePip({required this.color});

  static const double _barH = 22.0;
  static const double _barW =  1.5;
  static const double _gap  =  3.0;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _Bar(color: color),
          const SizedBox(width: _gap),
          _Bar(color: color),
        ],
      );
}

class _Bar extends StatelessWidget {
  final Color color;

  const _Bar({required this.color});

  @override
  Widget build(BuildContext context) => AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        width:  _DoubleLinePip._barW,
        height: _DoubleLinePip._barH,
        decoration: BoxDecoration(
          color:        color,
          borderRadius: BorderRadius.circular(1),
        ),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Horizontal split (top / bottom)
// ─────────────────────────────────────────────────────────────────────────────

/// A two-pane vertical split with a shared, draggable divider.
///
/// The bottom-panel height is stored in [SplitPaneProvider] so all horizontal
/// split views share the same position.  Min heights are enforced on both sides.
class ResizableHSplit extends StatelessWidget {
  final Widget top;
  final Widget bottom;

  static const double _handleH = 10.0;

  const ResizableHSplit({
    super.key,
    required this.top,
    required this.bottom,
  });

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SplitPaneProvider>();

    return LayoutBuilder(
      builder: (context, constraints) {
        final totalH    = constraints.maxHeight;
        final available = totalH - _handleH;
        // Clamp stored height to valid range given current total height.
        final bottomH = provider.detailHeight.clamp(
          SplitPaneProvider.minDetail,
          (available - SplitPaneProvider.minRows)
              .clamp(SplitPaneProvider.minDetail, double.infinity),
        );
        final topH = available - bottomH;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(height: topH,    child: top),
            _HSplitHandle(
              onDragUpdate: (dy) => context
                  .read<SplitPaneProvider>()
                  .setDetailHeight(provider.detailHeight - dy, available),
            ),
            SizedBox(height: bottomH, child: bottom),
          ],
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Horizontal drag handle
// ─────────────────────────────────────────────────────────────────────────────

class _HSplitHandle extends StatefulWidget {
  final ValueChanged<double> onDragUpdate;

  const _HSplitHandle({required this.onDragUpdate});

  @override
  State<_HSplitHandle> createState() => _HSplitHandleState();
}

class _HSplitHandleState extends State<_HSplitHandle> {
  bool _hovered  = false;
  bool _dragging = false;

  bool get _active => _hovered || _dragging;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final barColor = _active
        ? cs.onSurface.withAlpha(130)
        : cs.onSurface.withAlpha(45);
    final bgColor  = _active
        ? cs.surfaceContainerHigh
        : cs.surfaceContainerLow;

    return MouseRegion(
      cursor: SystemMouseCursors.resizeRow,
      onEnter: (_) => setState(() => _hovered  = true),
      onExit:  (_) => setState(() => _hovered  = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onVerticalDragStart:  (_) => setState(() => _dragging = true),
        onVerticalDragEnd:    (_) => setState(() => _dragging = false),
        onVerticalDragUpdate: (d) => widget.onDragUpdate(d.delta.dy),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          height: ResizableHSplit._handleH,
          color:  bgColor,
          child:  Center(
            child: _HDoubleLinePip(color: barColor),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Horizontal double-line pip
// ─────────────────────────────────────────────────────────────────────────────

/// Two short parallel horizontal bars — the resize-handle indicator for
/// a top/bottom split.
class _HDoubleLinePip extends StatelessWidget {
  final Color color;

  const _HDoubleLinePip({required this.color});

  static const double _barW = 22.0;
  static const double _barH =  1.5;
  static const double _gap  =  3.0;

  @override
  Widget build(BuildContext context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _HBar(color: color),
          const SizedBox(height: _gap),
          _HBar(color: color),
        ],
      );
}

class _HBar extends StatelessWidget {
  final Color color;

  const _HBar({required this.color});

  @override
  Widget build(BuildContext context) => AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        width:  _HDoubleLinePip._barW,
        height: _HDoubleLinePip._barH,
        decoration: BoxDecoration(
          color:        color,
          borderRadius: BorderRadius.circular(1),
        ),
      );
}
