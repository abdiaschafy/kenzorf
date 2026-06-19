import 'json_utils.dart';

/// `UserDto` (spec §5) : `{ id, email, firstName, lastName, phoneNumber?, role }`.
/// `role` : `"Customer"` | `"Admin"`.
class User {
  const User({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    this.phoneNumber,
    required this.role,
  });

  final String id;
  final String email;
  final String firstName;
  final String lastName;
  final String? phoneNumber;
  final String role;

  bool get isCustomer => role == 'Customer';
  bool get isAdmin => role == 'Admin';

  String get fullName => '$firstName $lastName'.trim();

  factory User.fromJson(Map<String, dynamic> json) => User(
    id: asString(json['id']),
    email: asString(json['email']),
    firstName: asString(json['firstName']),
    lastName: asString(json['lastName']),
    phoneNumber: json['phoneNumber'] as String?,
    role: asString(json['role'], fallback: 'Customer'),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'email': email,
    'firstName': firstName,
    'lastName': lastName,
    'phoneNumber': phoneNumber,
    'role': role,
  };
}

/// `AuthResponse` (spec §5) :
/// `{ accessToken, refreshToken, expiresAt, user: UserDto }`.
class AuthResponse {
  const AuthResponse({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresAt,
    required this.user,
  });

  final String accessToken;
  final String refreshToken;
  final DateTime? expiresAt;
  final User user;

  factory AuthResponse.fromJson(Map<String, dynamic> json) => AuthResponse(
    accessToken: asString(json['accessToken']),
    refreshToken: asString(json['refreshToken']),
    expiresAt: asDate(json['expiresAt']),
    user: User.fromJson(
      (json['user'] as Map?)?.cast<String, dynamic>() ?? const {},
    ),
  );
}

/// `RegisterRequest` (spec §5) :
/// `{ email, password, firstName, lastName, phoneNumber? }`.
class RegisterRequest {
  const RegisterRequest({
    required this.email,
    required this.password,
    required this.firstName,
    required this.lastName,
    this.phoneNumber,
  });

  final String email;
  final String password;
  final String firstName;
  final String lastName;
  final String? phoneNumber;

  Map<String, dynamic> toJson() => {
    'email': email,
    'password': password,
    'firstName': firstName,
    'lastName': lastName,
    if (phoneNumber != null && phoneNumber!.isNotEmpty)
      'phoneNumber': phoneNumber,
  };
}

/// `LoginRequest` (spec §5) : `{ email, password }`.
class LoginRequest {
  const LoginRequest({required this.email, required this.password});

  final String email;
  final String password;

  Map<String, dynamic> toJson() => {'email': email, 'password': password};
}
