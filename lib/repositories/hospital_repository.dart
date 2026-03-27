import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/config/supabase_config.dart';
import '../core/constants/app_constants.dart';
import '../core/utils/error_handler.dart';
import '../models/hospital.dart';

/// Repository for hospital data access.
class HospitalRepository {
  /// List all active hospitals.
  Future<List<Hospital>> listHospitals({int limit = 20, int offset = 0}) async {
    try {
      final data = await supabase
          .from(Tables.hospitals)
          .select()
          .eq('is_active', true)
          .order('rating', ascending: false)
          .range(offset, offset + limit - 1);
      return (data as List).map((e) => Hospital.fromJson(e)).toList();
    } on PostgrestException catch (e) {
      throw AppException.fromPostgrestException(e);
    } catch (e) {
      throw AppException(message: 'Failed to load hospitals: $e');
    }
  }

  /// Get a hospital by ID.
  Future<Hospital> getHospital(String id) async {
    try {
      final data = await supabase
          .from(Tables.hospitals)
          .select()
          .eq('id', id)
          .single();
      return Hospital.fromJson(data);
    } on PostgrestException catch (e) {
      throw AppException.fromPostgrestException(e);
    } catch (e) {
      throw AppException(message: 'Failed to load hospital: $e');
    }
  }

  /// Search hospitals by name or city.
  Future<List<Hospital>> searchHospitals(String query) async {
    try {
      final data = await supabase
          .from(Tables.hospitals)
          .select()
          .eq('is_active', true)
          .or('name.ilike.%$query%,city.ilike.%$query%')
          .order('rating', ascending: false)
          .limit(20);
      return (data as List).map((e) => Hospital.fromJson(e)).toList();
    } on PostgrestException catch (e) {
      throw AppException.fromPostgrestException(e);
    } catch (e) {
      throw AppException(message: 'Failed to search hospitals: $e');
    }
  }
}
