import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Manages the global UI zoom level (0.8 – 2.0, step 0.1) and app theme mode.
class UiScaleProvider extends ChangeNotifier {
  double _scale = 1.0;
  ThemeMode _themeMode = ThemeMode.system;

  static const double minScale = 0.8;
  static const double maxScale = 2.0;
  static const double step = 0.1;

  double get scale => _scale;
  ThemeMode get themeMode => _themeMode;

  /// Scales a base icon pixel size by the current factor.
  double sz(double base) => base * _scale;

  void increase() => _setRaw(_scale + step);
  void decrease() => _setRaw(_scale - step);
  void reset() => _setRaw(1.0);
  void setScale(double value) => _setRaw(value);

  /// Cycles: system → light → dark → system.
  void cycleTheme() {
    switch (_themeMode) {
      case ThemeMode.system:
        _themeMode = ThemeMode.light;
      case ThemeMode.light:
        _themeMode = ThemeMode.dark;
      case ThemeMode.dark:
        _themeMode = ThemeMode.system;
    }
    notifyListeners();
  }

  void _setRaw(double raw) {
    final rounded = ((raw.clamp(minScale, maxScale)) * 10).round() / 10.0;
    if (rounded == _scale) return;
    _scale = rounded;
    notifyListeners();
  }
}
