import 'dart:io';
import 'spx_section.dart';

class SpxDocument {
  final String filePath;
  final String fileName;
  final DateTime loadedAt;
  final List<SpxSection> sections;

  SpxDocument({
    required this.filePath,
    required this.sections,
  })  : fileName = File(filePath).uri.pathSegments.last,
        loadedAt = DateTime.now();

  /// All sections that have at least one item.
  List<SpxSection> get nonEmptySections =>
      sections.where((s) => !s.isEmpty).toList();

  Map<String, dynamic> toJson() => {
        'filePath': filePath,
        'fileName': fileName,
        'loadedAt': loadedAt.toIso8601String(),
        'sections': sections.map((s) => s.toJson()).toList(),
      };
}
