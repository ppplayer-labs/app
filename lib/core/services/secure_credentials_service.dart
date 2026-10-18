import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureCredentialsService {
  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    // Apple specific options: ensure credentials are only available when device is unlocked
    iOptions: IOSOptions(accessibility: KeychainAccessibility.unlocked),
    mOptions: MacOsOptions(accessibility: KeychainAccessibility.unlocked),
  );

  static const _spotifyClientIdKey = 'spotify_client_id';
  static const _spotifyClientSecretKey = 'spotify_client_secret';
  static const _youtubeApiKeyKey = 'youtube_api_key';

  // --- Spotify ---

  Future<String?> readSpotifyClientId() async {
    try {
      return await _storage.read(key: _spotifyClientIdKey);
    } catch (_) {
      return null;
    }
  }

  Future<String?> readSpotifyClientSecret() async {
    try {
      return await _storage.read(key: _spotifyClientSecretKey);
    } catch (_) {
      return null;
    }
  }

  Future<void> writeSpotifyCredentials({
    required String clientId,
    required String clientSecret,
  }) async {
    try {
      await _storage.write(key: _spotifyClientIdKey, value: clientId);
      await _storage.write(key: _spotifyClientSecretKey, value: clientSecret);
    } catch (_) {}
  }

  Future<void> clearSpotifyCredentials() async {
    try {
      await _storage.delete(key: _spotifyClientIdKey);
      await _storage.delete(key: _spotifyClientSecretKey);
    } catch (_) {}
  }

  // --- YouTube ---

  Future<String?> readYoutubeApiKey() async {
    try {
      return await _storage.read(key: _youtubeApiKeyKey);
    } catch (_) {
      return null;
    }
  }

  Future<void> writeYoutubeApiKey(String apiKey) async {
    try {
      await _storage.write(key: _youtubeApiKeyKey, value: apiKey);
    } catch (_) {}
  }

  Future<void> clearYoutubeApiKey() async {
    try {
      await _storage.delete(key: _youtubeApiKeyKey);
    } catch (_) {}
  }
}

final secureCredentialsProvider = Provider<SecureCredentialsService>((ref) {
  return SecureCredentialsService();
});
