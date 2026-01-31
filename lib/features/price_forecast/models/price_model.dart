class CropPrice {
  final String cropName;
  final double currentPrice;
  final String unit;
  final double changePercent;
  final bool isIncreasing;
  final String marketName;
  final DateTime lastUpdated;
  final List<double> priceHistory;
  final double predictedPrice;
  final DateTime bestSellDate;
  final double? minPrice;
  final double? maxPrice;
  final double? avgPrice;
  final String? priceCategory;
  final List<PriceAlert>? alerts;

  CropPrice({
    required this.cropName,
    required this.currentPrice,
    required this.unit,
    required this.changePercent,
    required this.isIncreasing,
    required this.marketName,
    required this.lastUpdated,
    required this.priceHistory,
    required this.predictedPrice,
    required this.bestSellDate,
    this.minPrice,
    this.maxPrice,
    this.avgPrice,
    this.priceCategory,
    this.alerts,
  });

  factory CropPrice.fromJson(Map<String, dynamic> json) {
    return CropPrice(
      cropName: json['cropName'] ?? '',
      currentPrice: (json['currentPrice'] ?? 0).toDouble(),
      unit: json['unit'] ?? 'per kg',
      changePercent: (json['changePercent'] ?? 0).toDouble(),
      isIncreasing: json['isIncreasing'] ?? false,
      marketName: json['marketName'] ?? '',
      lastUpdated: DateTime.parse(json['lastUpdated'] ?? DateTime.now().toIso8601String()),
      priceHistory: List<double>.from(
        (json['priceHistory'] ?? []).map((e) => (e as num).toDouble()),
      ),
      predictedPrice: (json['predictedPrice'] ?? 0).toDouble(),
      bestSellDate: DateTime.parse(json['bestSellDate'] ?? DateTime.now().toIso8601String()),
      minPrice: json['minPrice']?.toDouble(),
      maxPrice: json['maxPrice']?.toDouble(),
      avgPrice: json['avgPrice']?.toDouble(),
      priceCategory: json['priceCategory'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'cropName': cropName,
      'currentPrice': currentPrice,
      'unit': unit,
      'changePercent': changePercent,
      'isIncreasing': isIncreasing,
      'marketName': marketName,
      'lastUpdated': lastUpdated.toIso8601String(),
      'priceHistory': priceHistory,
      'predictedPrice': predictedPrice,
      'bestSellDate': bestSellDate.toIso8601String(),
      'minPrice': minPrice,
      'maxPrice': maxPrice,
      'avgPrice': avgPrice,
      'priceCategory': priceCategory,
    };
  }

  String get trendText => isIncreasing ? 'Increasing' : 'Decreasing';
  int get trendColor => isIncreasing ? 0xFF4CAF50 : 0xFFE53935;
  
  double get priceDifference => predictedPrice - currentPrice;
  double get potentialGain => (priceDifference / currentPrice) * 100;
}

class PriceAlert {
  final String id;
  final String cropName;
  final PriceAlertType type;
  final String message;
  final double targetPrice;
  final double currentPrice;
  final DateTime createdAt;
  final bool isTriggered;

  PriceAlert({
    required this.id,
    required this.cropName,
    required this.type,
    required this.message,
    required this.targetPrice,
    required this.currentPrice,
    required this.createdAt,
    required this.isTriggered,
  });
}

enum PriceAlertType {
  priceAbove,
  priceBelow,
  priceChange,
  bestSellTime,
}

class MarketInfo {
  final String id;
  final String name;
  final String location;
  final String district;
  final String state;
  final double latitude;
  final double longitude;
  final double distanceKm;
  final List<String> availableCrops;
  final String contactNumber;
  final String marketType;
  final List<String> operatingDays;
  final String timings;

  MarketInfo({
    required this.id,
    required this.name,
    required this.location,
    required this.district,
    required this.state,
    required this.latitude,
    required this.longitude,
    required this.distanceKm,
    required this.availableCrops,
    required this.contactNumber,
    required this.marketType,
    required this.operatingDays,
    required this.timings,
  });
}

class PriceForecast {
  final String cropName;
  final String marketName;
  final DateTime forecastDate;
  final double predictedPrice;
  final double confidenceLevel;
  final double lowerBound;
  final double upperBound;
  final String trend;
  final List<String> factors;
  final String recommendation;

  PriceForecast({
    required this.cropName,
    required this.marketName,
    required this.forecastDate,
    required this.predictedPrice,
    required this.confidenceLevel,
    required this.lowerBound,
    required this.upperBound,
    required this.trend,
    required this.factors,
    required this.recommendation,
  });
}

class PriceComparison {
  final String cropName;
  final List<MarketPriceData> marketPrices;
  final String bestMarket;
  final double bestPrice;
  final double priceDifference;
  final double distanceToBestMarket;

  PriceComparison({
    required this.cropName,
    required this.marketPrices,
    required this.bestMarket,
    required this.bestPrice,
    required this.priceDifference,
    required this.distanceToBestMarket,
  });
}

class MarketPriceData {
  final String marketName;
  final double price;
  final double distanceKm;
  final DateTime lastUpdated;
  final String grade;

  MarketPriceData({
    required this.marketName,
    required this.price,
    required this.distanceKm,
    required this.lastUpdated,
    required this.grade,
  });
}
