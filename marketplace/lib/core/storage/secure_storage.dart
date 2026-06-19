import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Abstraction fine au-dessus de `flutter_secure_storage`.
///
/// Centralise le stockage chiffré des secrets (tokens JWT/refresh, préférence
/// de langue). Aucune logique d'authentification ici : voir `AuthController`.
class SecureStorage {
  SecureStorage([FlutterSecureStorage? storage])
    : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  Future<String?> read(String key) => _storage.read(key: key);

  Future<void> write(String key, String value) =>
      _storage.write(key: key, value: value);

  Future<void> delete(String key) => _storage.delete(key: key);

  Future<void> deleteAll() => _storage.deleteAll();
}

/// Provider singleton du stockage sécurisé.
final secureStorageProvider = Provider<SecureStorage>((ref) => SecureStorage());
