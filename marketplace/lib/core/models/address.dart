import 'json_utils.dart';

/// `AddressDto` (spec §5) :
/// `{ id, label, fullName, phoneNumber, line1, line2?, city, region?, country,
///    landmark?, isDefault }`.
class Address {
  const Address({
    required this.id,
    this.label,
    required this.fullName,
    required this.phoneNumber,
    required this.line1,
    this.line2,
    required this.city,
    this.region,
    required this.country,
    this.landmark,
    required this.isDefault,
  });

  final String id;
  final String? label;
  final String fullName;
  final String phoneNumber;
  final String line1;
  final String? line2;
  final String city;
  final String? region;
  final String country;
  final String? landmark;
  final bool isDefault;

  /// Adresse formatée sur une ligne (pour récapitulatifs).
  String get oneLine {
    final parts = [
      line1,
      if (line2 != null && line2!.isNotEmpty) line2,
      city,
      if (region != null && region!.isNotEmpty) region,
      country,
    ]..removeWhere((p) => p == null || p.isEmpty);
    return parts.join(', ');
  }

  factory Address.fromJson(Map<String, dynamic> json) => Address(
    id: asString(json['id']),
    label: json['label'] as String?,
    fullName: asString(json['fullName']),
    phoneNumber: asString(json['phoneNumber']),
    line1: asString(json['line1']),
    line2: json['line2'] as String?,
    city: asString(json['city']),
    region: json['region'] as String?,
    country: asString(json['country']),
    landmark: json['landmark'] as String?,
    isDefault: asBool(json['isDefault']),
  );
}

/// `AddressRequest` (spec §5) :
/// `{ label?, fullName, phoneNumber, line1, line2?, city, region?, country,
///    landmark? }`.
class AddressRequest {
  const AddressRequest({
    this.label,
    required this.fullName,
    required this.phoneNumber,
    required this.line1,
    this.line2,
    required this.city,
    this.region,
    required this.country,
    this.landmark,
  });

  final String? label;
  final String fullName;
  final String phoneNumber;
  final String line1;
  final String? line2;
  final String city;
  final String? region;
  final String country;
  final String? landmark;

  Map<String, dynamic> toJson() => {
    if (label != null && label!.isNotEmpty) 'label': label,
    'fullName': fullName,
    'phoneNumber': phoneNumber,
    'line1': line1,
    if (line2 != null && line2!.isNotEmpty) 'line2': line2,
    'city': city,
    if (region != null && region!.isNotEmpty) 'region': region,
    'country': country,
    if (landmark != null && landmark!.isNotEmpty) 'landmark': landmark,
  };

  /// Construit une requête à partir d'une adresse existante (édition).
  factory AddressRequest.fromAddress(Address a) => AddressRequest(
    label: a.label,
    fullName: a.fullName,
    phoneNumber: a.phoneNumber,
    line1: a.line1,
    line2: a.line2,
    city: a.city,
    region: a.region,
    country: a.country,
    landmark: a.landmark,
  );
}
