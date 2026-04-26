class MedicalTest {
  final String id;
  final String hospitalId;
  final String name;
  final String? description;
  final String? category;
  final double price;
  final double hospitalProfitPercent;
  final double adminProfitPercent;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  final String? hospitalName;
  final String? hospitalCity;

  const MedicalTest({
    required this.id,
    required this.hospitalId,
    required this.name,
    this.description,
    this.category,
    required this.price,
    this.hospitalProfitPercent = 90,
    this.adminProfitPercent = 10,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
    this.hospitalName,
    this.hospitalCity,
  });

  factory MedicalTest.fromJson(Map<String, dynamic> json) {
    final hospital = json['hospitals'] as Map<String, dynamic>?;

    return MedicalTest(
      id: json['id'] as String,
      hospitalId: json['hospital_id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      category: json['category'] as String?,
      price: (json['price'] as num?)?.toDouble() ?? 0,
      hospitalProfitPercent:
          (json['hospital_profit_percent'] as num?)?.toDouble() ?? 90,
      adminProfitPercent:
          (json['admin_profit_percent'] as num?)?.toDouble() ?? 10,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      hospitalName: hospital?['name'] as String?,
      hospitalCity: hospital?['city'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'hospital_id': hospitalId,
      'name': name,
      if (description != null) 'description': description,
      if (category != null) 'category': category,
      'price': price,
      'hospital_profit_percent': hospitalProfitPercent,
      'admin_profit_percent': adminProfitPercent,
      'is_active': isActive,
    };
  }

  String get displayCategory {
    final value = category?.trim();
    return value == null || value.isEmpty ? 'General test' : value;
  }

  String get priceLabel => 'BDT ${price.toStringAsFixed(price % 1 == 0 ? 0 : 2)}';
}
