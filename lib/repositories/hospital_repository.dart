import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/config/supabase_config.dart';
import '../core/constants/app_constants.dart';
import '../core/utils/error_handler.dart';
import '../models/hospital.dart';

/// Repository for hospital data access.
class HospitalRepository {
  static const String _hospitalColumns =
      'id, name, description, address, city, state, country, zip_code, latitude, longitude, '
      'phone, email, website, logo_url, cover_image_url, operating_hours, services, rating, is_active, '
      'status, created_at, updated_at';

  List<Hospital>? _hospitalCache;
  final Map<String, List<Hospital>> _searchCache = {};

  /// List only approved hospitals (patient-facing).
  Future<List<Hospital>> getApprovedHospitals({int limit = 50, int offset = 0}) async {
    if (offset == 0 && _hospitalCache != null && _hospitalCache!.isNotEmpty) {
      return _hospitalCache!;
    }

    try {
      final data = await supabase
          .from(Tables.hospitals)
          .select(_hospitalColumns)
          .eq('status', 'approved')
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);
      final hospitals = (data as List).map((e) => Hospital.fromJson(e)).toList();
      if (offset == 0) {
        _hospitalCache = hospitals;
      }
      return hospitals;
    } on PostgrestException catch (e) {
      throw AppException.fromPostgrestException(e);
    } catch (e) {
      throw AppException(message: 'Failed to load hospitals: $e');
    }
  }

  /// List all active hospitals.
  Future<List<Hospital>> listHospitals({int limit = 20, int offset = 0}) async {
    return getApprovedHospitals(limit: limit, offset: offset);
  }

  /// Get a hospital by ID.
  Future<Hospital> getHospital(String id) async {
    try {
      final data = await supabase
          .from(Tables.hospitals)
          .select(_hospitalColumns)
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
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) {
      return listHospitals();
    }
    if (_searchCache.containsKey(normalized)) {
      return _searchCache[normalized]!;
    }

    try {
      final data = await supabase
          .from(Tables.hospitals)
          .select(_hospitalColumns)
          .eq('status', 'approved')
          .or('name.ilike.%$normalized%,city.ilike.%$normalized%')
          .order('rating', ascending: false)
          .limit(20);
      final results = (data as List).map((e) => Hospital.fromJson(e)).toList();
      _searchCache[normalized] = results;
      return results;
    } on PostgrestException catch (e) {
      throw AppException.fromPostgrestException(e);
    } catch (e) {
      throw AppException(message: 'Failed to search hospitals: $e');
    }
  }
}
