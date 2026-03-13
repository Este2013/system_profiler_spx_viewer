class SpxSection {
  final String dataType;
  final String displayName;
  final String categoryName;
  final DateTime? timestamp;
  final List<Map<String, dynamic>> items;
  final Map<String, dynamic> properties;
  final int detailLevel;

  const SpxSection({
    required this.dataType,
    required this.displayName,
    required this.categoryName,
    this.timestamp,
    required this.items,
    required this.properties,
    required this.detailLevel,
  });

  bool get isEmpty => items.isEmpty;

  /// Returns column keys ordered by _properties _order, with _name first.
  List<String> get columnKeys {
    final ordered = <MapEntry<String, int>>[];
    for (final entry in properties.entries) {
      final val = entry.value;
      if (val is Map) {
        final order = int.tryParse(val['_order']?.toString() ?? '');
        if (order != null) {
          ordered.add(MapEntry(entry.key, order));
        }
      }
    }
    ordered.sort((a, b) => a.value.compareTo(b.value));

    var keys = ordered.map((e) => e.key).toList();

    // Put _name first
    if (keys.contains('_name') && keys.isNotEmpty && keys.first != '_name') {
      keys.remove('_name');
      keys.insert(0, '_name');
    }

    // If no keys from properties, derive from first item
    if (keys.isEmpty && items.isNotEmpty) {
      final allKeys = <String>{};
      for (final item in items) {
        allKeys.addAll(item.keys);
      }
      final list = allKeys.toList();
      list.sort();
      list.remove('_name');
      list.insert(0, '_name');
      return list.where((k) => !k.startsWith('_') || k == '_name').toList();
    }

    return keys;
  }

  Map<String, dynamic> toJson() => {
        'dataType': dataType,
        'displayName': displayName,
        'categoryName': categoryName,
        'timestamp': timestamp?.toIso8601String(),
        'items': items,
      };
}
