import '../models/nauman_calc_entry.dart';

/// Stub: local storage not available on this platform.
class NaumanCalcStorage {
  Future<List<NaumanCalcEntry>> loadEntries(String profileId) async {
    return const [];
  }

  Future<void> saveEntry(String profileId, NaumanCalcEntry entry) async {
    // No-op.
  }

  Future<void> deleteEntry(String profileId, String entryId) async {
    // No-op.
  }
}

