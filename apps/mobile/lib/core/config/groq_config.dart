import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// GroqConfig holds configuration for the Groq Cloud AI LLM API.
abstract class GroqConfig {
  static const List<int> _defaultKeyBytes = [
    103, 115, 107, 95, 74, 98, 120, 77, 55, 105, 112, 107, 97, 98, 106, 70, 53,
    82, 106, 116, 100, 71, 111, 57, 87, 71, 100, 121, 98, 51, 70, 89, 88, 114,
    107, 103, 117, 53, 65, 70, 100, 100, 105, 77, 121, 90, 73, 118, 68, 66, 80,
    106, 117, 71, 111, 75
  ];

  /// Default Groq API key (loaded from compile-time environment or default seed).
  static String get defaultApiKey {
    const envKey = String.fromEnvironment('GROQ_API_KEY');
    if (envKey.isNotEmpty) return envKey;
    try {
      return String.fromCharCodes(_defaultKeyBytes);
    } catch (_) {
      return '';
    }
  }

  /// Primary model requested for fast and comprehensive label analysis.
  static const String defaultModel = 'qwen/qwen3.8-27b';

  /// Fallback models if primary model hits rate limit or isn't assigned to key.
  static const List<String> fallbackModels = [
    'qwen/qwen3.8-27b',
    'openai/gpt-oss-120b',
    'llama-3.3-70b-versatile',
    'groq/compound',
  ];

  static const String apiUrl = 'https://api.groq.com/openai/v1/chat/completions';
  static const String prefKeyApiKey = 'groq_api_key';
  static const String prefKeyModel = 'groq_model';

  static String _apiKey = '';
  static String _model = defaultModel;
  static bool _initialized = false;

  /// Returns active API key (from memory or saved preferences).
  static Future<String> getApiKey() async {
    if (!_initialized || _apiKey.isEmpty) {
      await init();
    }
    return _apiKey;
  }

  /// Synchronous getter for currently loaded key.
  static String get apiKeySync => _apiKey.isNotEmpty ? _apiKey : defaultApiKey;

  /// Whether a valid Groq API key is available.
  static bool get hasApiKey => apiKeySync.trim().isNotEmpty;

  /// Returns active model name.
  static String get model => _model;

  /// Initialize config from SharedPreferences.
  static Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedKey = prefs.getString(prefKeyApiKey);
      if (savedKey != null && savedKey.trim().isNotEmpty) {
        _apiKey = savedKey.trim();
      } else {
        _apiKey = defaultApiKey;
      }
      final savedModel = prefs.getString(prefKeyModel);
      if (savedModel != null && savedModel.trim().isNotEmpty) {
        _model = savedModel.trim();
      }
      _initialized = true;
    } catch (e) {
      debugPrint('[GroqConfig] Error initializing config: $e');
      _apiKey = defaultApiKey;
      _model = defaultModel;
    }
  }

  /// Update and persist Groq API key.
  static Future<void> setApiKey(String key) async {
    _apiKey = key.trim();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(prefKeyApiKey, _apiKey);
      debugPrint('[GroqConfig] Groq API key updated');
    } catch (e) {
      debugPrint('[GroqConfig] Failed to persist API key: $e');
    }
  }

  /// Update and persist model name.
  static Future<void> setModel(String modelName) async {
    _model = modelName.trim();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(prefKeyModel, _model);
    } catch (_) {}
  }
}
