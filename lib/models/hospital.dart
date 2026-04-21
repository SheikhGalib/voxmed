class Hospital {
  final String id;
  final String name;
  final String? description;
  final String address;
  final String city;
  final String? state;
  final String country;
  final String? zipCode;
  final double? latitude;
  final double? longitude;
  final String? phone;
  final String? email;
  final String? website;
  final String? logoUrl;
  final String? coverImageUrl;
  final Map<String, dynamic>? operatingHours;
  final List<String>? services;
  final double rating;
  final bool isActive;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Hospital({
    required this.id,
    required this.name,
    this.description,
    required this.address,
    required this.city,
    this.state,
    required this.country,
    this.zipCode,
    this.latitude,
    this.longitude,
    this.phone,
    this.email,
    this.website,
    this.logoUrl,
    this.coverImageUrl,
    this.operatingHours,
    this.services,
    this.rating = 0,
    this.isActive = true,
    this.status = 'pending',
    required this.createdAt,
    required this.updatedAt,
  });

  factory Hospital.fromJson(Map<String, dynamic> json) {
    return Hospital(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      address: json['address'] as String,
      city: json['city'] as String,
      state: json['state'] as String?,
      country: json['country'] as String,
      zipCode: json['zip_code'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      website: json['website'] as String?,
      logoUrl: json['logo_url'] as String?,
      coverImageUrl: json['cover_image_url'] as String?,
      operatingHours: json['operating_hours'] as Map<String, dynamic>?,
      services: (json['services'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      rating: (json['rating'] as num?)?.toDouble() ?? 0,
      isActive: json['is_active'] as bool? ?? true,
      status: json['status'] as String? ?? 'pending',
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      if (description != null) 'description': description,
      'address': address,
      'city': city,
      if (state != null) 'state': state,
      'country': country,
      if (zipCode != null) 'zip_code': zipCode,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (phone != null) 'phone': phone,
      if (email != null) 'email': email,
      if (website != null) 'website': website,
      if (logoUrl != null) 'logo_url': logoUrl,
      if (coverImageUrl != null) 'cover_image_url': coverImageUrl,
      if (operatingHours != null) 'operating_hours': operatingHours,
      if (services != null) 'services': services,
      'rating': rating,
      'is_active': isActive,
    };
  }
}
