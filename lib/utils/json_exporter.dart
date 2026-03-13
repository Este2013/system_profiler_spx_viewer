import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import '../models/spx_document.dart';

class JsonExporter {
  static Future<bool> exportDocument(SpxDocument document) async {
    final savePath = await FilePicker.platform.saveFile(
      dialogTitle: 'Export as JSON',
      fileName: document.fileName.replaceAll(RegExp(r'\.spx$', caseSensitive: false), '.json'),
      type: FileType.custom,
      allowedExtensions: ['json'],
    );

    if (savePath == null) return false;

    final json = const JsonEncoder.withIndent('  ').convert(_sanitize(document.toJson()));
    await File(savePath).writeAsString(json);
    return true;
  }

  /// Recursively convert non-serializable types (DateTime) to strings.
  static dynamic _sanitize(dynamic value) {
    if (value is DateTime) return value.toIso8601String();
    if (value is Map) {
      return value.map((k, v) => MapEntry(k.toString(), _sanitize(v)));
    }
    if (value is List) return value.map(_sanitize).toList();
    return value;
  }
}
