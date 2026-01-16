import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/site.dart';

class AppProvider extends ChangeNotifier {
  bool _isLoggedIn = false;
  ThemeMode _themeMode = ThemeMode.system;
  List<Site> _sites = [];
  Site? _currentSite;

  bool get isLoggedIn => _isLoggedIn;
  ThemeMode get themeMode => _themeMode;
  List<Site> get sites => _sites;
  Site? get currentSite => _currentSite;

  AppProvider() {
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Load theme
    final themeIndex = prefs.getInt('themeMode') ?? 0;
    _themeMode = ThemeMode.values[themeIndex];
    
    // Load sites
    final sitesJson = prefs.getStringList('sites') ?? [];
    _sites = sitesJson.map((s) => Site.fromJsonString(s)).toList();
    
    // Load current site
    final currentSiteIndex = prefs.getInt('currentSiteIndex');
    if (currentSiteIndex != null && currentSiteIndex < _sites.length) {
      _currentSite = _sites[currentSiteIndex];
      _isLoggedIn = true;
    }
    
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('themeMode', mode.index);
    notifyListeners();
  }

  Future<void> addSite(Site site) async {
    _sites.add(site);
    await _saveSites();
    notifyListeners();
  }

  Future<void> removeSite(int index) async {
    _sites.removeAt(index);
    if (_currentSite != null && !_sites.contains(_currentSite)) {
      _currentSite = _sites.isNotEmpty ? _sites.first : null;
      if (_currentSite == null) {
        _isLoggedIn = false;
      }
    }
    await _saveSites();
    notifyListeners();
  }

  Future<void> setCurrentSite(Site site) async {
    _currentSite = site;
    _isLoggedIn = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('currentSiteIndex', _sites.indexOf(site));
    notifyListeners();
  }

  Future<void> _saveSites() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      'sites',
      _sites.map((s) => s.toJsonString()).toList(),
    );
    if (_currentSite != null) {
      await prefs.setInt('currentSiteIndex', _sites.indexOf(_currentSite!));
    }
  }

  Future<void> logout() async {
    _isLoggedIn = false;
    _currentSite = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('currentSiteIndex');
    notifyListeners();
  }
}
