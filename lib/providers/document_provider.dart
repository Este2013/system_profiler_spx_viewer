import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../models/spx_document.dart';
import '../models/spx_section.dart';
import '../parser/spx_parser.dart';
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
    } catch (e) {
      _errorMessage = 'Failed to load file:\n$e';
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
