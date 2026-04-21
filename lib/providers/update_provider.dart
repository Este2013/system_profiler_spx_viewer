import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';

/// Current app version — keep in sync with pubspec.yaml.
const String kAppVersion = '0.1.0';

class UpdateProvider extends ChangeNotifier {
  bool _checked = false;
  String? _latestTag;
  bool _hasUpdate = false;

  bool get hasUpdate => _hasUpdate;
  String? get latestTag => _latestTag;

  static const String releasesPageUrl =
      'https://github.com/Este2013/system_profiler_spx_viewer/releases';
  static const String _apiUrl =
      'https://api.github.com/repos/Este2013/system_profiler_spx_viewer/releases/latest';

  Future<void> checkForUpdates() async {
    if (_checked) return;
    _checked = true;
    try {
      final client = HttpClient()
        ..connectionTimeout = const Duration(seconds: 10);
      final req = await client.getUrl(Uri.parse(_apiUrl));
      req.headers.set('Accept', 'application/vnd.github+json');
      req.headers.set('User-Agent', 'spx_viewer/$kAppVersion');
      final resp = await req.close();
      final body = await resp.transform(utf8.decoder).join();
      client.close();

      if (resp.statusCode == 200) {
        final json = jsonDecode(body) as Map<String, dynamic>;
        final raw = (json['tag_name'] as String? ?? '');
        final tag = raw.startsWith('v') ? raw.substring(1) : raw;
        if (tag.isNotEmpty && _isNewer(tag, kAppVersion)) {
          _latestTag = tag;
          _hasUpdate = true;
          notifyListeners();
        }
      }
    } catch (_) {
      // Silently fail — no network, timeout, rate limit, etc.
    }
  }

  bool _isNewer(String a, String b) {
    final av = _parse(a);
    final bv = _parse(b);
    for (var i = 0; i < 3; i++) {
      if (av[i] > bv[i]) return true;
      if (av[i] < bv[i]) return false;
    }
    return false;
  }

  List<int> _parse(String v) {
    final parts = v.split('+').first.split('.');
    return List.generate(
      3,
      (i) => int.tryParse(i < parts.length ? parts[i] : '0') ?? 0,
    );
  }
}
