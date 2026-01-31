class CropRecommendation {
  final String id;
  final String cropName;
  final double expectedYield;
  final double expectedProfit;
  final double riskScore;
  final String waterRequirement;
  final String season;
  final String marketDemand;
  final double suitabilityScore;
  final List<String> reasons;
  final String? imageUrl;
  final int? growthDays;
  final String? soilRequirement;
  final String? temperatureRange;
  final List<String>? commonDiseases;
  final double? investmentRequired;

  CropRecommendation({
    required this.id,
    required this.cropName,
    required this.expectedYield,
    required this.expectedProfit,
    required this.riskScore,
    required this.waterRequirement,
    required this.season,
    required this.marketDemand,
    required this.suitabilityScore,
    required this.reasons,
    this.imageUrl,
    this.growthDays,
    this.soilRequirement,
    this.temperatureRange,
    this.commonDiseases,
    this.investmentRequired,
  });

  factory CropRecommendation.fromJson(Map<String, dynamic> json) {
    return CropRecommendation(
      id: json['id'] ?? '',
      cropName: json['cropName'] ?? '',
      expectedYield: (json['expectedYield'] ?? 0).toDouble(),
      expectedProfit: (json['expectedProfit'] ?? 0).toDouble(),
      riskScore: (json['riskScore'] ?? 0).toDouble(),
      waterRequirement: json['waterRequirement'] ?? '',
      season: json['season'] ?? '',
      marketDemand: json['marketDemand'] ?? '',
      suitabilityScore: (json['suitabilityScore'] ?? 0).toDouble(),
      reasons: List<String>.from(json['reasons'] ?? []),
      imageUrl: json['imageUrl'],
      growthDays: json['growthDays'],
      soilRequirement: json['soilRequirement'],
      temperatureRange: json['temperatureRange'],
      commonDiseases: json['commonDiseases'] != null
          ? List<String>.from(json['commonDiseases'])
          : null,
      investmentRequired: json['investmentRequired']?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'cropName': cropName,
      'expectedYield': expectedYield,
      'expectedProfit': expectedProfit,
      'riskScore': riskScore,
      'waterRequirement': waterRequirement,
      'season': season,
      'marketDemand': marketDemand,
      'suitabilityScore': suitabilityScore,
      'reasons': reasons,
      'imageUrl': imageUrl,
      'growthDays': growthDays,
      'soilRequirement': soilRequirement,
      'temperatureRange': temperatureRange,
      'commonDiseases': commonDiseases,
      'investmentRequired': investmentRequired,
    };
  }

  String get riskLevel {
    if (riskScore < 0.25) return 'Low';
    if (riskScore < 0.5) return 'Medium';
    if (riskScore < 0.75) return 'High';
    return 'Very High';
  }

  int get riskColor {
    if (riskScore < 0.25) return 0xFF4CAF50;
    if (riskScore < 0.5) return 0xFFFFC107;
    if (riskScore < 0.75) return 0xFFFF9800;
    return 0xFFE53935;
  }
}

class CropInfo {
  final String id;
  final String name;
  final String category;
  final String scientificName;
  final String description;
  final List<String> seasons;
  final int growthDays;
  final String waterRequirement;
  final String soilType;
  final String temperatureRange;
  final double averageYield;
  final String yieldUnit;
  final List<String> commonDiseases;
  final List<String> companionCrops;
  final List<String> nutritionalValue;
  final String? imageUrl;

  CropInfo({
    required this.id,
    required this.name,
    required this.category,
    required this.scientificName,
    required this.description,
    required this.seasons,
    required this.growthDays,
    required this.waterRequirement,
    required this.soilType,
    required this.temperatureRange,
    required this.averageYield,
    required this.yieldUnit,
    required this.commonDiseases,
    required this.companionCrops,
    required this.nutritionalValue,
    this.imageUrl,
  });
}

// Crop Database
class CropDatabase {
  static final List<CropInfo> crops = [
    CropInfo(
      id: 'crop_001',
      name: 'Rice',
      category: 'Cereals',
      scientificName: 'Oryza sativa',
      description: 'Rice is the staple food crop for more than half of the world\'s population.',
      seasons: ['Kharif'],
      growthDays: 120,
      waterRequirement: 'High',
      soilType: 'Clayey loam, Alluvial',
      temperatureRange: '20-35°C',
      averageYield: 25,
      yieldUnit: 'quintals/acre',
      commonDiseases: ['Blast', 'Brown spot', 'Bacterial leaf blight'],
      companionCrops: ['Fish farming', 'Azolla'],
      nutritionalValue: ['Carbohydrates', 'Protein', 'Vitamin B'],
    ),
    CropInfo(
      id: 'crop_002',
      name: 'Wheat',
      category: 'Cereals',
      scientificName: 'Triticum aestivum',
      description: 'Wheat is the second most important cereal crop in India.',
      seasons: ['Rabi'],
      growthDays: 140,
      waterRequirement: 'Medium',
      soilType: 'Loamy, Clay loam',
      temperatureRange: '15-25°C',
      averageYield: 20,
      yieldUnit: 'quintals/acre',
      commonDiseases: ['Rust', 'Powdery mildew', 'Loose smut'],
      companionCrops: ['Mustard', 'Chickpea'],
      nutritionalValue: ['Carbohydrates', 'Protein', 'Fiber'],
    ),
    CropInfo(
      id: 'crop_003',
      name: 'Cotton',
      category: 'Commercial Crops',
      scientificName: 'Gossypium hirsutum',
      description: 'Cotton is the most important fiber crop known as white gold.',
      seasons: ['Kharif'],
      growthDays: 180,
      waterRequirement: 'Medium',
      soilType: 'Black cotton soil, Alluvial',
      temperatureRange: '21-30°C',
      averageYield: 8,
      yieldUnit: 'quintals/acre',
      commonDiseases: ['Boll rot', 'Root rot', 'Wilt'],
      companionCrops: ['Green gram', 'Black gram'],
      nutritionalValue: ['Fiber for textile'],
    ),
    CropInfo(
      id: 'crop_004',
      name: 'Sugarcane',
      category: 'Commercial Crops',
      scientificName: 'Saccharum officinarum',
      description: 'Sugarcane is the main source of sugar and jaggery in India.',
      seasons: ['Kharif', 'Rabi'],
      growthDays: 365,
      waterRequirement: 'High',
      soilType: 'Loamy, Alluvial',
      temperatureRange: '20-35°C',
      averageYield: 400,
      yieldUnit: 'quintals/acre',
      commonDiseases: ['Red rot', 'Smut', 'Wilt'],
      companionCrops: ['Potato', 'Onion'],
      nutritionalValue: ['Sucrose', 'Energy'],
    ),
    CropInfo(
      id: 'crop_005',
      name: 'Tomato',
      category: 'Vegetables',
      scientificName: 'Solanum lycopersicum',
      description: 'Tomato is one of the most widely grown vegetables worldwide.',
      seasons: ['Kharif', 'Rabi', 'Zaid'],
      growthDays: 90,
      waterRequirement: 'Medium',
      soilType: 'Sandy loam, Red soil',
      temperatureRange: '20-27°C',
      averageYield: 120,
      yieldUnit: 'quintals/acre',
      commonDiseases: ['Early blight', 'Late blight', 'Leaf curl'],
      companionCrops: ['Basil', 'Carrot', 'Onion'],
      nutritionalValue: ['Vitamin C', 'Lycopene', 'Potassium'],
    ),
    CropInfo(
      id: 'crop_006',
      name: 'Grape',
      category: 'Fruits',
      scientificName: 'Vitis vinifera',
      description: 'Grapes are one of the most valuable fruit crops with export potential.',
      seasons: ['Rabi'],
      growthDays: 150,
      waterRequirement: 'Medium',
      soilType: 'Sandy loam, Black soil',
      temperatureRange: '15-35°C',
      averageYield: 80,
      yieldUnit: 'quintals/acre',
      commonDiseases: ['Downy mildew', 'Powdery mildew', 'Anthracnose'],
      companionCrops: ['Legumes'],
      nutritionalValue: ['Vitamin C', 'Antioxidants', 'Potassium'],
    ),
  ];

  static CropInfo? findByName(String name) {
    try {
      return crops.firstWhere(
        (c) => c.name.toLowerCase() == name.toLowerCase(),
      );
    } catch (e) {
      return null;
    }
  }

  static List<CropInfo> findByCategory(String category) {
    return crops.where(
      (c) => c.category.toLowerCase() == category.toLowerCase(),
    ).toList();
  }

  static List<CropInfo> findBySeason(String season) {
    return crops.where(
      (c) => c.seasons.any(
        (s) => s.toLowerCase().contains(season.toLowerCase()),
      ),
    ).toList();
  }
}
