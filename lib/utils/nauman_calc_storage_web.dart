// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:convert';

import '../models/nauman_calc_entry.dart';

class NaumanCalcStorage {
  static String _key(String profileId) => 'nauman_calc_entries_$profileId';

  Future<List<NaumanCalcEntry>> loadEntries(String profileId) async {
    final raw = html.window.localStorage[_key(profileId)];
    if (raw == null || raw.isEmpty) return const [];

    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .cast<Map<String, dynamic>>()
          .map(NaumanCalcEntry.fromJson)
          .toList();
    } catch (_) {
      return const [];
    }
  }

  Future<void> saveEntry(String profileId, NaumanCalcEntry entry) async {
    final entries = await loadEntries(profileId);
    final idx = entries.indexWhere((e) => e.id == entry.id);
    if (idx >= 0) {
      entries[idx] = entry;
    } else {
      entries.insert(0, entry); // newest first
    }

    html.window.localStorage[_key(profileId)] =
        jsonEncode(entries.map((e) => e.toJson()).toList());
  }

  Future<void> deleteEntry(String profileId, String entryId) async {
    final entries = await loadEntries(profileId);
    entries.removeWhere((e) => e.id == entryId);
    html.window.localStorage[_key(profileId)] =
        jsonEncode(entries.map((e) => e.toJson()).toList());
  }
}

