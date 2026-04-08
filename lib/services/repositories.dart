import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/entities.dart';
import '../models/nauman_calc_entry.dart';

final supabase = Supabase.instance.client;

class ProfileRepository {
  Future<List<Profile>> getProfiles() async {
    final res = await supabase.from('profiles').select();
    return res.map(Profile.fromJson).toList();
  }

  Future<Profile> getOrCreateProfileByName(String name) async {
    final existing = await supabase
        .from('profiles')
        .select()
        .eq('name', name)
        .limit(1)
        .maybeSingle();
    if (existing != null) {
      return Profile.fromJson(existing);
    }
    final created = await supabase
        .from('profiles')
        .insert({'name': name})
        .select()
        .single();
    return Profile.fromJson(created);
  }

  Future<Profile> createProfile(String name) async {
    final res = await supabase
        .from('profiles')
        .insert({'name': name})
        .select()
        .single();
    return Profile.fromJson(res);
  }

  Future<Profile> updateProfileSecurity({
    required String profileId,
    required String email,
    required String pinHash,
  }) async {
    final res = await supabase
        .from('profiles')
        .update({
          'email': email,
          'pin_hash': pinHash,
        })
        .eq('id', profileId)
        .select()
        .single();
    return Profile.fromJson(res);
  }
}

class YearRepository {
  Future<List<ProfileYear>> getYearsForProfile(String profileId) async {
    final res = await supabase
        .from('profile_years')
        .select()
        .eq('profile_id', profileId)
        .order('year', ascending: false);
    return res.map(ProfileYear.fromJson).toList();
  }

  Future<ProfileYear> createYear(String profileId, int year) async {
    final res = await supabase
        .from('profile_years')
        .insert({'profile_id': profileId, 'year': year})
        .select()
        .single();
    return ProfileYear.fromJson(res);
  }

  Future<void> deleteYear(String yearId) async {
    await supabase.from('profile_years').delete().eq('id', yearId);
  }
}

class CarRepository {
  Future<List<Map<String, dynamic>>> getCarsForYearWithTotals(
    String profileYearId,
  ) async {
    // Join cars with aggregated cost items.
    final res = await supabase
        .from('cars')
        .select('*, car_cost_items(amount,status,description,date)')
        .eq('profile_year_id', profileYearId)
        .order('created_at');

    return res.map((row) {
      final items = (row['car_cost_items'] as List<dynamic>? ?? [])
          .cast<Map<String, dynamic>>();
      final buyingPrice = (row['buying_price'] as num?)?.toDouble() ?? 0;
      final paidAmount = items.fold<double>(0, (sum, item) {
        final status = (item['status'] as String? ?? '').toLowerCase();
        final amount = (item['amount'] as num?)?.toDouble() ?? 0;
        if (status == 'paid') return sum + amount;
        return sum;
      });
      final unpaidAmount = items.fold<double>(0, (sum, item) {
        final status = (item['status'] as String? ?? '').toLowerCase();
        final amount = (item['amount'] as num?)?.toDouble() ?? 0;
        if (status != 'paid') return sum + amount;
        return sum;
      });
      final totalCost = items.fold<double>(
        buyingPrice,
        (sum, item) => sum + (item['amount'] as num).toDouble(),
      );
      return {
        ...row,
        'paid_amount': paidAmount,
        'unpaid_amount': unpaidAmount,
        'total_cost': totalCost,
      };
    }).toList();
  }

  Future<Car> createOrUpdateCar({
    String? id,
    required String profileYearId,
    required String model,
    required String vin,
    required String readiness,
    required String status,
    double? buyingPrice,
    int? mileage,
    DateTime? purchaseDate,
    double? sellingPrice,
  }) async {
    final payload = <String, dynamic>{
      'profile_year_id': profileYearId,
      'model': model,
      'vin': vin,
      'readiness': readiness,
      'status': status,
      'buying_price': buyingPrice,
      'mileage': mileage,
      'purchase_date': purchaseDate?.toIso8601String(),
      'selling_price': sellingPrice,
    };

    if (id == null) {
      final res = await supabase
          .from('cars')
          .insert(payload)
          .select()
          .single();
      return Car.fromJson(res);
    } else {
      final res = await supabase
          .from('cars')
          .update(payload)
          .eq('id', id)
          .select()
          .single();
      return Car.fromJson(res);
    }
  }

  Future<void> deleteCar(String carId) async {
    await supabase.from('cars').delete().eq('id', carId);
  }
}

class CarCostRepository {
  Future<List<CarCostItem>> getCostItemsForCar(String carId) async {
    final res = await supabase
        .from('car_cost_items')
        .select()
        .eq('car_id', carId)
        .order('date');
    return res.map(CarCostItem.fromJson).toList();
  }

  Future<CarCostItem> addCostItem({
    required String carId,
    required DateTime date,
    required String status,
    required String description,
    String notes = '',
    required double amount,
  }) async {
    final res = await supabase
        .from('car_cost_items')
        .insert({
          'car_id': carId,
          'date': date.toIso8601String(),
          'status': status,
          'description': description,
          'notes': notes,
          'amount': amount,
        })
        .select()
        .single();
    return CarCostItem.fromJson(res);
  }

  Future<void> deleteCostItem(String id) async {
    await supabase.from('car_cost_items').delete().eq('id', id);
  }

  Future<CarCostItem> updateCostItem({
    required String id,
    required DateTime date,
    required String status,
    required String description,
    required double amount,
  }) async {
    final res = await supabase
        .from('car_cost_items')
        .update({
          'date': date.toIso8601String(),
          'status': status,
          'description': description,
          'amount': amount,
        })
        .eq('id', id)
        .select()
        .single();
    return CarCostItem.fromJson(res);
  }
}

class NaumanCalcRepository {
  Future<List<NaumanCalcEntry>> getEntriesForProfile(String profileId) async {
    final res = await supabase
        .from('nauman_calc_entries')
        .select()
        .eq('profile_id', profileId)
        .order('created_at', ascending: false);
    return res.map(NaumanCalcEntry.fromJson).toList();
  }

  Future<NaumanCalcEntry> addEntry({
    required String profileId,
    required String carName,
    required int accidents,
    required double carfax,
    required double expectedSellingPrice,
    required double transportation,
    required double auctionFee,
    required double dealershipDoc,
    required double repairFrontDoorShellPaint,
    required double repairFender,
    required double repairFrontLight,
    required double repairBumperFixBayArea,
    required double profit,
    required double repairsTotal,
    required double total,
    required double finalBiddingOffer,
  }) async {
    final payload = <String, dynamic>{
      'profile_id': profileId,
      'car_name': carName,
      'accidents': accidents,
      'carfax': carfax,
      'expected_selling_price': expectedSellingPrice,
      'transportation': transportation,
      'auction_fee': auctionFee,
      'dealership_doc': dealershipDoc,
      'repair_front_door_shell_paint': repairFrontDoorShellPaint,
      'repair_fender': repairFender,
      'repair_front_light': repairFrontLight,
      'repair_bumper_fix_bay_area': repairBumperFixBayArea,
      'profit': profit,
      'repairs_total': repairsTotal,
      'total': total,
      'final_bidding_offer': finalBiddingOffer,
    };

    final res = await supabase
        .from('nauman_calc_entries')
        .insert(payload)
        .select()
        .single();

    return NaumanCalcEntry.fromJson(res);
  }

  Future<void> deleteEntry(String entryId) async {
    await supabase
        .from('nauman_calc_entries')
        .delete()
        .eq('id', entryId);
  }
}

