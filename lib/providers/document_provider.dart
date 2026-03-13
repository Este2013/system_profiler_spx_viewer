import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../models/spx_document.dart';
import '../models/spx_section.dart';
import '../parser/spx_parser.dart';
import '../utils/category_mapping.dart';
import '../utils/json_exporter.dart';

class DocumentProvider extends ChangeNotifier {
  SpxDocument? _document;
  SpxSection? _selectedSection;
  String _globalSearchQuery = '';
  bool _isSearchActive = false;
  bool _isSidebarCollapsed = false;
  bool _isLoading = false;
  String? _errorMessage;

  SpxDocument? get document => _document;
  SpxSection? get selectedSection => _selectedSection;
  String get globalSearchQuery => _globalSearchQuery;
  bool get isSearchActive => _isSearchActive;
  bool get isSidebarCollapsed => _isSidebarCollapsed;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasDocument => _document != null;

  /// Returns the category name if the currently selected section is a
  /// category overview (e.g. 'Hardware' when SPHardwareDataType is shown).
  String? get selectedCategoryOverview {
    final section = _selectedSection;
    if (section == null) return null;
    for (final entry in kCategoryOverviewDataType.entries) {
      if (entry.value == section.dataType) return entry.key;
    }
    return null;
  }

  Future<void> loadFile(String path) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final doc = await SpxParser.parseFile(path);
      _document = doc;
      // Auto-select first non-empty section
      _selectedSection = doc.sections
          .where((s) => !s.isEmpty)
          .cast<SpxSection?>()
          .firstOrNull;
      _globalSearchQuery = '';
      _isSearchActive = false;
    } catch (e, stackTrace) {
      _errorMessage = 'Failed to load file:\n\n$e\n\n$stackTrace';
      _document = null;
      _selectedSection = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> openFilePicker() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['spx'],
      dialogTitle: 'Open SPX Report',
    );

    if (result != null && result.files.single.path != null) {
      await loadFile(result.files.single.path!);
    }
  }

  void selectSection(SpxSection section) {
    _selectedSection = section;
    notifyListeners();
  }

  /// Selects the overview section for [category] (e.g. SPHardwareDataType for
  /// 'Hardware'). Does nothing if the document has no such section.
  void selectCategoryOverview(String category) {
    if (_document == null) return;
    final overviewType = kCategoryOverviewDataType[category];
    if (overviewType == null) return;
    final section = _document!.sections
        .where((s) => s.dataType == overviewType)
        .cast<SpxSection?>()
        .firstOrNull;
    if (section != null) selectSection(section);
  }

  void setGlobalSearch(String query) {
    _globalSearchQuery = query;
    notifyListeners();
  }

  void setSearchActive(bool active) {
    _isSearchActive = active;
    if (!active) _globalSearchQuery = '';
    notifyListeners();
  }

  void toggleSidebar() {
    _isSidebarCollapsed = !_isSidebarCollapsed;
    notifyListeners();
  }

  Future<bool> exportJson() async {
    if (_document == null) return false;
    return JsonExporter.exportDocument(_document!);
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
