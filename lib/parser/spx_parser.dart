import 'dart:io';
import 'package:xml/xml.dart';
import '../models/spx_document.dart';
import '../models/spx_section.dart';
import '../utils/category_mapping.dart';

class SpxParser {
  static Future<SpxDocument> parseFile(String filePath) async {
    final file = File(filePath);
    final content = await file.readAsString();
    return parse(filePath, content);
  }

  static SpxDocument parse(String filePath, String content) {
    final xmlDoc = XmlDocument.parse(content);

    // Navigate to the root element (plist)
    final plist = xmlDoc.rootElement;

    // Find the top-level array or dict
    XmlElement? rootContainer;
    for (final child in plist.childElements) {
      if (child.name.local == 'array' || child.name.local == 'dict') {
        rootContainer = child;
        break;
      }
    }

    if (rootContainer == null) {
      throw const FormatException('Invalid SPX file: no root array/dict found inside <plist>');
    }

    final sections = <SpxSection>[];

    if (rootContainer.name.local == 'array') {
      for (final child in rootContainer.childElements) {
        if (child.name.local == 'dict') {
          final section = _parseSection(child);
          if (section != null) sections.add(section);
        }
      }
    } else if (rootContainer.name.local == 'dict') {
      final section = _parseSection(rootContainer);
      if (section != null) sections.add(section);
    }

    return SpxDocument(filePath: filePath, sections: sections);
  }

  static SpxSection? _parseSection(XmlElement dictElement) {
    final data = _parseDictElement(dictElement);

    final dataType = data['_dataType'] as String? ?? 'Unknown';
    final rawItems = data['_items'];
    final items = _extractItems(rawItems);
    final properties = (data['_properties'] is Map<String, dynamic>)
        ? data['_properties'] as Map<String, dynamic>
        : <String, dynamic>{};
    final detailLevel = (data['_detailLevel'] as int?) ?? 0;

    DateTime? timestamp;
    final ts = data['_timeStamp'];
    if (ts is DateTime) timestamp = ts;

    final info = getSectionInfo(dataType);

    return SpxSection(
      dataType: dataType,
      displayName: info.displayName,
      categoryName: info.category,
      timestamp: timestamp,
      items: items,
      properties: properties,
      detailLevel: detailLevel,
    );
  }

  static List<Map<String, dynamic>> _extractItems(dynamic rawItems) {
    if (rawItems is! List) return [];
    return rawItems
        .whereType<Map<String, dynamic>>()
        .toList();
  }

  static dynamic _parseValue(XmlElement element) {
    switch (element.name.local) {
      case 'string':
        return element.innerText;
      case 'integer':
        return int.tryParse(element.innerText.trim()) ?? element.innerText;
      case 'real':
        return double.tryParse(element.innerText.trim()) ?? element.innerText;
      case 'true':
        return true;
      case 'false':
        return false;
      case 'date':
        return DateTime.tryParse(element.innerText.trim()) ?? element.innerText;
      case 'data':
        return element.innerText.trim();
      case 'array':
        return element.childElements
            .map((e) => _parseValue(e))
            .toList();
      case 'dict':
        return _parseDictElement(element);
      default:
        return element.innerText;
    }
  }

  static Map<String, dynamic> _parseDictElement(XmlElement dictElement) {
    final result = <String, dynamic>{};
    final children = dictElement.childElements.toList();

    for (int i = 0; i + 1 < children.length; i += 2) {
      final keyElem = children[i];
      final valElem = children[i + 1];

      if (keyElem.name.local != 'key') {
        // Malformed: skip ahead one element and retry
        i -= 1;
        continue;
      }

      final key = keyElem.innerText;
      final value = _parseValue(valElem);
      result[key] = value;
    }

    return result;
  }
}
