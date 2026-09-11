import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// GeminiConfig holds configuration for the Google Gemini API.
///
/// Ensures the mobile client always transmits an active Gemini API key
/// to the ML Scanner backend via the `X-Gemini-Api-Key` header, preventing
/// slow EasyOCR multi-pass CPU execution.
abstract class GeminiConfig {
  /// Default active Gemini API key (set via --dart-define=GEMINI_API_KEY or SharedPreferences).
  static const String defaultApiKey =
      String.fromEnvironment('GEMINI_API_KEY', defaultValue: '');

  static const String prefKeyApiKey = 'gemini_api_key';

  static String _apiKey = '';
  static bool _initialized = false;

  /// Returns active API key (from memory or saved preferences).
  static Future<String> getApiKey() async {
    if (!_initialized || _apiKey.isEmpty) {
      await init();
    }
    return _apiKey;
  }

  /// Synchronous getter for currently loaded key.
  static String get apiKeySync {
    if (_apiKey.isNotEmpty) return _apiKey;
    const envKey = String.fromEnvironment('GEMINI_API_KEY');
    if (envKey.isNotEmpty) return envKey;
    return defaultApiKey;
  }

  /// Whether a valid Gemini API key is available.
  static bool get hasApiKey => apiKeySync.trim().isNotEmpty;

  /// Initialize config from SharedPreferences.
  static Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedKey = prefs.getString(prefKeyApiKey);
      const envKey = String.fromEnvironment('GEMINI_API_KEY');

      if (savedKey != null && savedKey.trim().isNotEmpty) {
        _apiKey = savedKey.trim();
      } else if (envKey.isNotEmpty) {
        _apiKey = envKey;
      } else {
        _apiKey = defaultApiKey;
      }
    } catch (e) {
      debugPrint('[GeminiConfig] Error initializing SharedPreferences: $e');
      _apiKey = defaultApiKey;
    } finally {
      _initialized = true;
    }
  }

  /// Persist a custom API key.
  static Future<void> setApiKey(String key) async {
    _apiKey = key.trim();
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_apiKey.isEmpty) {
        await prefs.remove(prefKeyApiKey);
      } else {
        await prefs.setString(prefKeyApiKey, _apiKey);
      }
    } catch (e) {
      debugPrint('[GeminiConfig] Error saving API key: $e');
    }
  }

  /// Reset to defaults.
  static Future<void> reset() async {
    _apiKey = defaultApiKey;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(prefKeyApiKey);
    } catch (_) {}
  }
}
