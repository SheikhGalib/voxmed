import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/medical_test.dart';
import '../repositories/medical_test_repository.dart';

final medicalTestRepositoryProvider = Provider<MedicalTestRepository>((ref) {
  return MedicalTestRepository();
});

class MedicalTestFilters {
  final String? hospitalId;
  final String query;
  final String category;
  final MedicalTestSort sort;

  const MedicalTestFilters({
    this.hospitalId,
    this.query = '',
    this.category = 'All Tests',
    this.sort = MedicalTestSort.priceLowToHigh,
  });

  @override
  bool operator ==(Object other) {
    return other is MedicalTestFilters &&
        other.hospitalId == hospitalId &&
        other.query == query &&
        other.category == category &&
        other.sort == sort;
  }

  @override
  int get hashCode => Object.hash(hospitalId, query, category, sort);
}

final medicalTestsProvider =
    FutureProvider.family<List<MedicalTest>, MedicalTestFilters>((
      ref,
      filters,
    ) async {
      return ref
          .read(medicalTestRepositoryProvider)
          .listTests(
            hospitalId: filters.hospitalId,
            query: filters.query,
            category: filters.category,
            sort: filters.sort,
          );
    });
