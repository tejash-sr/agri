enum DiseaseSeverity {
  healthy,
  mild,
  moderate,
  severe,
  critical,
}

class DiseaseScanResult {
  final String id;
  final String cropName;
  final String imagePath;
  final String diseaseName;
  final double confidence;
  final DiseaseSeverity severity;
  final String description;
  final List<String> treatments;
  final List<String> preventiveMeasures;
  final DateTime scannedAt;
  final String? affectedPart;
  final double? spreadRisk;
  final List<String>? nearbyAffectedFarms;

  DiseaseScanResult({
    required this.id,
    required this.cropName,
    required this.imagePath,
    required this.diseaseName,
    required this.confidence,
    required this.severity,
    required this.description,
    required this.treatments,
    required this.preventiveMeasures,
    required this.scannedAt,
    this.affectedPart,
    this.spreadRisk,
    this.nearbyAffectedFarms,
  });

  factory DiseaseScanResult.fromJson(Map<String, dynamic> json) {
    return DiseaseScanResult(
      id: json['id'] ?? '',
      cropName: json['cropName'] ?? '',
      imagePath: json['imagePath'] ?? '',
      diseaseName: json['diseaseName'] ?? '',
      confidence: (json['confidence'] ?? 0).toDouble(),
      severity: DiseaseSeverity.values.firstWhere(
        (e) => e.name == json['severity'],
        orElse: () => DiseaseSeverity.healthy,
      ),
      description: json['description'] ?? '',
      treatments: List<String>.from(json['treatments'] ?? []),
      preventiveMeasures: List<String>.from(json['preventiveMeasures'] ?? []),
      scannedAt: DateTime.parse(json['scannedAt'] ?? DateTime.now().toIso8601String()),
      affectedPart: json['affectedPart'],
      spreadRisk: json['spreadRisk']?.toDouble(),
      nearbyAffectedFarms: json['nearbyAffectedFarms'] != null
          ? List<String>.from(json['nearbyAffectedFarms'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'cropName': cropName,
      'imagePath': imagePath,
      'diseaseName': diseaseName,
      'confidence': confidence,
      'severity': severity.name,
      'description': description,
      'treatments': treatments,
      'preventiveMeasures': preventiveMeasures,
      'scannedAt': scannedAt.toIso8601String(),
      'affectedPart': affectedPart,
      'spreadRisk': spreadRisk,
      'nearbyAffectedFarms': nearbyAffectedFarms,
    };
  }

  String get severityText {
    switch (severity) {
      case DiseaseSeverity.healthy:
        return 'Healthy';
      case DiseaseSeverity.mild:
        return 'Mild';
      case DiseaseSeverity.moderate:
        return 'Moderate';
      case DiseaseSeverity.severe:
        return 'Severe';
      case DiseaseSeverity.critical:
        return 'Critical';
    }
  }

  int get severityColor {
    switch (severity) {
      case DiseaseSeverity.healthy:
        return 0xFF4CAF50;
      case DiseaseSeverity.mild:
        return 0xFFFFC107;
      case DiseaseSeverity.moderate:
        return 0xFFFF9800;
      case DiseaseSeverity.severe:
        return 0xFFE53935;
      case DiseaseSeverity.critical:
        return 0xFF9C27B0;
    }
  }
}

class DiseaseInfo {
  final String id;
  final String name;
  final String scientificName;
  final String category;
  final List<String> affectedCrops;
  final String description;
  final List<String> symptoms;
  final List<String> causes;
  final List<String> treatments;
  final List<String> preventiveMeasures;
  final String spreadPattern;
  final List<String> favorableConditions;
  final String? imageUrl;

  DiseaseInfo({
    required this.id,
    required this.name,
    required this.scientificName,
    required this.category,
    required this.affectedCrops,
    required this.description,
    required this.symptoms,
    required this.causes,
    required this.treatments,
    required this.preventiveMeasures,
    required this.spreadPattern,
    required this.favorableConditions,
    this.imageUrl,
  });
}

// Common crop diseases database
class DiseaseDatabase {
  static final List<DiseaseInfo> diseases = [
    DiseaseInfo(
      id: 'disease_001',
      name: 'Early Blight',
      scientificName: 'Alternaria solani',
      category: 'Fungal',
      affectedCrops: ['Tomato', 'Potato', 'Eggplant'],
      description: 'A common fungal disease causing dark spots with concentric rings on leaves.',
      symptoms: [
        'Dark brown spots with concentric rings',
        'Yellowing around spots',
        'Leaf drop starting from lower leaves',
        'Stem lesions',
      ],
      causes: [
        'Warm, humid conditions',
        'Overhead irrigation',
        'Poor air circulation',
        'Infected seeds or transplants',
      ],
      treatments: [
        'Apply copper-based fungicide',
        'Remove affected leaves',
        'Improve air circulation',
        'Apply neem oil spray',
      ],
      preventiveMeasures: [
        'Crop rotation',
        'Proper plant spacing',
        'Avoid overhead watering',
        'Use disease-free seeds',
        'Mulching to prevent soil splash',
      ],
      spreadPattern: 'Wind-borne spores, water splash',
      favorableConditions: ['Temperature: 24-29°C', 'High humidity', 'Wet foliage'],
    ),
    DiseaseInfo(
      id: 'disease_002',
      name: 'Downy Mildew',
      scientificName: 'Plasmopara viticola',
      category: 'Fungal',
      affectedCrops: ['Grape', 'Cucumber', 'Lettuce', 'Onion'],
      description: 'A serious fungal disease causing yellow patches and downy growth on leaf undersides.',
      symptoms: [
        'Yellow patches on upper leaf surface',
        'White/gray downy growth underneath',
        'Curling and browning of leaves',
        'Stunted growth',
      ],
      causes: [
        'Cool, moist conditions',
        'Poor drainage',
        'Dense planting',
        'Morning dew',
      ],
      treatments: [
        'Apply mancozeb fungicide',
        'Remove infected parts',
        'Improve ventilation',
        'Apply bordeaux mixture',
      ],
      preventiveMeasures: [
        'Ensure good air circulation',
        'Water in morning',
        'Use resistant varieties',
        'Remove crop debris',
      ],
      spreadPattern: 'Water splash, wind',
      favorableConditions: ['Temperature: 15-25°C', 'High humidity >80%', 'Rainy weather'],
    ),
    DiseaseInfo(
      id: 'disease_003',
      name: 'Powdery Mildew',
      scientificName: 'Erysiphe cichoracearum',
      category: 'Fungal',
      affectedCrops: ['Wheat', 'Grape', 'Cucumber', 'Mango'],
      description: 'A common disease causing white powdery coating on leaves and stems.',
      symptoms: [
        'White powdery patches on leaves',
        'Leaf curling and yellowing',
        'Stunted growth',
        'Premature leaf drop',
      ],
      causes: [
        'Moderate temperatures',
        'Low humidity',
        'Poor air circulation',
        'Shaded conditions',
      ],
      treatments: [
        'Apply sulfur-based fungicide',
        'Use potassium bicarbonate spray',
        'Apply neem oil',
        'Remove heavily infected parts',
      ],
      preventiveMeasures: [
        'Proper spacing',
        'Good sunlight exposure',
        'Avoid excess nitrogen fertilizer',
        'Use resistant varieties',
      ],
      spreadPattern: 'Wind-borne spores',
      favorableConditions: ['Temperature: 20-25°C', 'Moderate humidity 40-70%', 'Shaded areas'],
    ),
  ];

  static DiseaseInfo? findByName(String name) {
    try {
      return diseases.firstWhere(
        (d) => d.name.toLowerCase() == name.toLowerCase(),
      );
    } catch (e) {
      return null;
    }
  }

  static List<DiseaseInfo> findByCrop(String cropName) {
    return diseases.where(
      (d) => d.affectedCrops.any(
        (c) => c.toLowerCase() == cropName.toLowerCase(),
      ),
    ).toList();
  }
}
