import 'dart:convert';

class NaumanCalcEntry {
  final String id;
  final String profileId;
  final DateTime createdAt;

  final String carName;
  final int accidents;
  final double carfax;

  final double expectedSellingPrice;
  final double transportation;
  final double auctionFee;
  final double dealershipDoc;

  final double repairFrontDoorShellPaint;
  final double repairFender;
  final double repairFrontLight;
  final double repairBumperFixBayArea;

  final double profit;

  final double repairsTotal;
  final double total;
  final double finalBiddingOffer;

  NaumanCalcEntry({
    required this.id,
    required this.profileId,
    required this.createdAt,
    required this.carName,
    required this.accidents,
    required this.carfax,
    required this.expectedSellingPrice,
    required this.transportation,
    required this.auctionFee,
    required this.dealershipDoc,
    required this.repairFrontDoorShellPaint,
    required this.repairFender,
    required this.repairFrontLight,
    required this.repairBumperFixBayArea,
    required this.profit,
    required this.repairsTotal,
    required this.total,
    required this.finalBiddingOffer,
  });

  factory NaumanCalcEntry.fromJson(Map<String, dynamic> json) {
    double d(String key) {
      final v = json[key];
      if (v == null) return 0;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString()) ?? 0;
    }

    int i(String key) {
      final v = json[key];
      if (v == null) return 0;
      if (v is num) return v.toInt();
      return int.tryParse(v.toString()) ?? 0;
    }

    return NaumanCalcEntry(
      id: json['id'] as String,
      profileId: json['profile_id'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      carName: json['car_name'] as String? ?? '',
      accidents: i('accidents'),
      carfax: d('carfax'),
      expectedSellingPrice: d('expected_selling_price'),
      transportation: d('transportation'),
      auctionFee: d('auction_fee'),
      dealershipDoc: d('dealership_doc'),
      repairFrontDoorShellPaint: d('repair_front_door_shell_paint'),
      repairFender: d('repair_fender'),
      repairFrontLight: d('repair_front_light'),
      repairBumperFixBayArea: d('repair_bumper_fix_bay_area'),
      profit: d('profit'),
      repairsTotal: d('repairs_total'),
      total: d('total'),
      finalBiddingOffer: d('final_bidding_offer'),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'profile_id': profileId,
        'created_at': createdAt.toIso8601String(),
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

  /// Helpers for debugging/printing.
  @override
  String toString() => jsonEncode(toJson());
}

