import 'package:flutter/foundation.dart';

/// Manages the global UI zoom level (0.8 – 2.0, step 0.1).
///
/// Text is scaled via [MediaQuery.textScaler] in [_AppRootState].
/// Explicit icon pixel sizes should call [sz] so they grow/shrink in sync.
class UiScaleProvider extends ChangeNotifier {
  double _scale = 1.0;

  static const double minScale = 0.8;
  static const double maxScale = 2.0;
  static const double step = 0.1;

  double get scale => _scale;

  /// Scales a base icon pixel size by the current factor.
  /// Example: `Icon(Icons.search, size: sp.sz(18))`
  double sz(double base) => base * _scale;

  void increase() => _setRaw(_scale + step);
  void decrease() => _setRaw(_scale - step);
  void reset() => _setRaw(1.0);
  void setScale(double value) => _setRaw(value);

  void _setRaw(double raw) {
    final rounded = ((raw.clamp(minScale, maxScale)) * 10).round() / 10.0;
    if (rounded == _scale) return;
    _scale = rounded;
    notifyListeners();
  }
}
