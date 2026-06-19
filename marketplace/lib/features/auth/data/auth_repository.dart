import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_exception.dart';
import '../../../core/models/user.dart';

/// Accès réseau aux endpoints `/auth` (spec §4). Aucune logique d'état ici :
/// le [AuthController] orchestre la persistance des jetons.
class AuthRepository {
  AuthRepository(this._dio);

  final Dio _dio;

  /// `POST /auth/register` → `AuthResponse`.
  Future<AuthResponse> register(RegisterRequest request) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        '/auth/register',
        data: request.toJson(),
      );
      return AuthResponse.fromJson(res.data!);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// `POST /auth/login` → `AuthResponse`.
  Future<AuthResponse> login(LoginRequest request) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        '/auth/login',
        data: request.toJson(),
      );
      return AuthResponse.fromJson(res.data!);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// `GET /auth/me` → `UserDto` (requiert un access token valide).
  Future<User> me() async {
    try {
      final res = await _dio.get<Map<String, dynamic>>('/auth/me');
      return User.fromJson(res.data!);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// `POST /auth/logout` — révoque le refresh token côté serveur (204).
  Future<void> logout(String refreshToken) async {
    try {
      await _dio.post<void>(
        '/auth/logout',
        data: {'refreshToken': refreshToken},
      );
    } on DioException catch (e) {
      // La déconnexion locale doit aboutir même si l'appel serveur échoue.
      throw ApiException.fromDio(e);
    }
  }
}

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(ref.read(dioProvider)),
);
