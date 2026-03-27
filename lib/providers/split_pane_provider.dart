import 'package:flutter/foundation.dart';

/// Stores shared split positions for all resizable panes in the app.
class SplitPaneProvider extends ChangeNotifier {
  // ── Vertical (left / right) split ──────────────────────────────────────────
  static const double defaultWidth = 280.0;
  static const double minLeft      = 160.0;
  static const double minRight     = 280.0;

  double _treeWidth = defaultWidth;
  double get treeWidth => _treeWidth;

  /// Update the tree-panel width, clamped to valid range.
  void setWidth(double w, double available) {
    final max     = available - minRight;
    final clamped = w.clamp(minLeft, max < minLeft ? minLeft : max);
    if ((clamped - _treeWidth).abs() > 0.5) {
      _treeWidth = clamped;
      notifyListeners();
    }
  }

  // ── Horizontal (top / bottom) split ────────────────────────────────────────
  static const double defaultDetailHeight = 300.0;
  static const double minRows             = 100.0;
  static const double minDetail           = 140.0;

  double _detailHeight = defaultDetailHeight;
  double get detailHeight => _detailHeight;

  /// Update the detail-panel height, clamped to valid range.
  void setDetailHeight(double h, double available) {
    final max     = available - minRows;
    final clamped = h.clamp(minDetail, max < minDetail ? minDetail : max);
    if ((clamped - _detailHeight).abs() > 0.5) {
      _detailHeight = clamped;
      notifyListeners();
    }
  }
}
