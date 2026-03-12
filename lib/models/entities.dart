class Profile {
  final String id;
  final String name;
  final String? email;
  final String? pinHash;

  Profile({
    required this.id,
    required this.name,
    this.email,
    this.pinHash,
  });

  factory Profile.fromJson(Map<String, dynamic> json) => Profile(
        id: json['id'] as String,
        name: json['name'] as String,
        email: json['email'] as String?,
        pinHash: json['pin_hash'] as String?,
      );
}

class ProfileYear {
  final String id;
  final int year;
  final String profileId;

  ProfileYear({
    required this.id,
    required this.year,
    required this.profileId,
  });

  factory ProfileYear.fromJson(Map<String, dynamic> json) => ProfileYear(
        id: json['id'] as String,
        year: json['year'] as int,
        profileId: json['profile_id'] as String,
      );
}

class Car {
  final String id;
  final String profileYearId;
  final String model;
  final String vin;
  final String readiness;
  final String status;
  final double? buyingPrice;
  final int? mileage;
  final DateTime? purchaseDate;
  final double? sellingPrice;

  Car({
    required this.id,
    required this.profileYearId,
    required this.model,
    required this.vin,
    required this.readiness,
    required this.status,
    this.buyingPrice,
    this.mileage,
    this.purchaseDate,
    this.sellingPrice,
  });

  factory Car.fromJson(Map<String, dynamic> json) => Car(
        id: json['id'] as String,
        profileYearId: json['profile_year_id'] as String,
        model: json['model'] as String,
        vin: json['vin'] as String,
        readiness: json['readiness'] as String? ?? '',
        status: json['status'] as String? ?? '',
        buyingPrice: (json['buying_price'] as num?)?.toDouble(),
        mileage: json['mileage'] as int?,
        purchaseDate: json['purchase_date'] == null
            ? null
            : DateTime.parse(json['purchase_date'] as String),
        sellingPrice: (json['selling_price'] as num?)?.toDouble(),
      );
}

class CarCostItem {
  final String id;
  final String carId;
  final DateTime date;
  final String status;
  final String description;
  final String notes;
  final double amount;

  CarCostItem({
    required this.id,
    required this.carId,
    required this.date,
    required this.status,
    required this.description,
    required this.notes,
    required this.amount,
  });

  factory CarCostItem.fromJson(Map<String, dynamic> json) => CarCostItem(
        id: json['id'] as String,
        carId: json['car_id'] as String,
        date: DateTime.parse(json['date'] as String),
        status: json['status'] as String? ?? '',
        description: json['description'] as String? ?? '',
        notes: json['notes'] as String? ?? '',
        amount: (json['amount'] as num).toDouble(),
      );
}

