class Farm {
  final String id;
  final String name;
  final String location;
  final double latitude;
  final double longitude;
  final double totalArea;
  final String areaUnit;
  final String soilType;
  final String irrigationType;
  final List<String> crops;
  final DateTime createdAt;
  final double? ndviScore;
  final double? soilMoisture;
  final String? waterSource;
  final List<FarmSection>? sections;

  Farm({
    required this.id,
    required this.name,
    required this.location,
    required this.latitude,
    required this.longitude,
    required this.totalArea,
    required this.areaUnit,
    required this.soilType,
    required this.irrigationType,
    required this.crops,
    required this.createdAt,
    this.ndviScore,
    this.soilMoisture,
    this.waterSource,
    this.sections,
  });

  factory Farm.fromJson(Map<String, dynamic> json) {
    return Farm(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      location: json['location'] ?? '',
      latitude: (json['latitude'] ?? 0).toDouble(),
      longitude: (json['longitude'] ?? 0).toDouble(),
      totalArea: (json['totalArea'] ?? 0).toDouble(),
      areaUnit: json['areaUnit'] ?? 'Acres',
      soilType: json['soilType'] ?? '',
      irrigationType: json['irrigationType'] ?? '',
      crops: List<String>.from(json['crops'] ?? []),
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      ndviScore: json['ndviScore']?.toDouble(),
      soilMoisture: json['soilMoisture']?.toDouble(),
      waterSource: json['waterSource'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'location': location,
      'latitude': latitude,
      'longitude': longitude,
      'totalArea': totalArea,
      'areaUnit': areaUnit,
      'soilType': soilType,
      'irrigationType': irrigationType,
      'crops': crops,
      'createdAt': createdAt.toIso8601String(),
      'ndviScore': ndviScore,
      'soilMoisture': soilMoisture,
      'waterSource': waterSource,
    };
  }

  Farm copyWith({
    String? id,
    String? name,
    String? location,
    double? latitude,
    double? longitude,
    double? totalArea,
    String? areaUnit,
    String? soilType,
    String? irrigationType,
    List<String>? crops,
    DateTime? createdAt,
    double? ndviScore,
    double? soilMoisture,
    String? waterSource,
  }) {
    return Farm(
      id: id ?? this.id,
      name: name ?? this.name,
      location: location ?? this.location,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      totalArea: totalArea ?? this.totalArea,
      areaUnit: areaUnit ?? this.areaUnit,
      soilType: soilType ?? this.soilType,
      irrigationType: irrigationType ?? this.irrigationType,
      crops: crops ?? this.crops,
      createdAt: createdAt ?? this.createdAt,
      ndviScore: ndviScore ?? this.ndviScore,
      soilMoisture: soilMoisture ?? this.soilMoisture,
      waterSource: waterSource ?? this.waterSource,
    );
  }
}

class FarmSection {
  final String id;
  final String name;
  final double area;
  final String currentCrop;
  final String status;
  final double healthScore;
  final DateTime? plantingDate;
  final DateTime? expectedHarvestDate;

  FarmSection({
    required this.id,
    required this.name,
    required this.area,
    required this.currentCrop,
    required this.status,
    required this.healthScore,
    this.plantingDate,
    this.expectedHarvestDate,
  });
}

class SoilProfile {
  final String farmId;
  final String soilType;
  final double phLevel;
  final double nitrogenLevel;
  final double phosphorusLevel;
  final double potassiumLevel;
  final double organicMatter;
  final double moisture;
  final DateTime testedAt;
  final String recommendation;

  SoilProfile({
    required this.farmId,
    required this.soilType,
    required this.phLevel,
    required this.nitrogenLevel,
    required this.phosphorusLevel,
    required this.potassiumLevel,
    required this.organicMatter,
    required this.moisture,
    required this.testedAt,
    required this.recommendation,
  });
}

class CropHistory {
  final String id;
  final String farmId;
  final String cropName;
  final String season;
  final DateTime plantingDate;
  final DateTime? harvestDate;
  final double areaPlanted;
  final double? actualYield;
  final double? revenue;
  final double? expenses;
  final String status;
  final List<String>? issues;

  CropHistory({
    required this.id,
    required this.farmId,
    required this.cropName,
    required this.season,
    required this.plantingDate,
    this.harvestDate,
    required this.areaPlanted,
    this.actualYield,
    this.revenue,
    this.expenses,
    required this.status,
    this.issues,
  });
}
