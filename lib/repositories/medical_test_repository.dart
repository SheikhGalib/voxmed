import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/config/supabase_config.dart';
import '../core/constants/app_constants.dart';
import '../core/utils/error_handler.dart';
import '../models/medical_test.dart';

enum MedicalTestSort {
  priceLowToHigh,
  priceHighToLow,
}

class MedicalTestRepository {
  static const String _columns =
      'id, hospital_id, name, description, category, price, '
      'hospital_profit_percent, admin_profit_percent, is_active, created_at, updated_at, '
      'hospitals(name, city)';

  Future<List<MedicalTest>> listTests({
    String? hospitalId,
    String query = '',
    String category = 'All Tests',
    MedicalTestSort sort = MedicalTestSort.priceLowToHigh,
    int limit = 50,
  }) async {
    try {
      var request = supabase
          .from(Tables.medicalTests)
          .select(_columns)
          .eq('is_active', true);

      if (hospitalId != null && hospitalId.isNotEmpty) {
        request = request.eq('hospital_id', hospitalId);
      }

      final normalizedQuery = query.trim();
      if (normalizedQuery.isNotEmpty) {
        request = request.or(
          'name.ilike.%$normalizedQuery%,category.ilike.%$normalizedQuery%,description.ilike.%$normalizedQuery%',
        );
      }

      if (category != 'All Tests') {
        request = request.ilike('category', '%$category%');
      }

      final data = await request
          .order(
            'price',
            ascending: sort == MedicalTestSort.priceLowToHigh,
          )
          .limit(limit);

      return List<Map<String, dynamic>>.from(data)
          .map(MedicalTest.fromJson)
          .toList();
    } on PostgrestException catch (e) {
      throw AppException.fromPostgrestException(e);
    } catch (e) {
      throw AppException(message: 'Failed to load medical tests: $e');
    }
  }
}
