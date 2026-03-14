import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/entities.dart';

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
        .select('*, car_cost_items(amount)')
        .eq('profile_year_id', profileYearId)
        .order('created_at');

    return res.map((row) {
      final items = (row['car_cost_items'] as List<dynamic>? ?? [])
          .cast<Map<String, dynamic>>();
      final buyingPrice = (row['buying_price'] as num?)?.toDouble() ?? 0;
      final totalCost = items.fold<double>(
        buyingPrice,
        (sum, item) => sum + (item['amount'] as num).toDouble(),
      );
      return {
        ...row,
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

