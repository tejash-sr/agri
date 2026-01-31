import 'package:flutter/material.dart';
import '../features/home/models/weather_model.dart';
import '../features/farm/models/farm_model.dart';
import '../features/disease_scanner/models/disease_model.dart';
import '../features/crop_recommendation/models/crop_model.dart';
import '../features/price_forecast/models/price_model.dart';
import '../features/marketplace/models/listing_model.dart';
import '../features/alerts/models/alert_model.dart';
import '../features/finance/models/finance_model.dart';

class AppProvider extends ChangeNotifier {
  // User Info
  String _userName = 'Rajesh Kumar';
  String _userPhone = '+91 98765 43210';
  String _userLocation = 'Nashik, Maharashtra';
  String _userAvatar = '';
  
  // Farm Data
  Farm? _currentFarm;
  List<Farm> _farms = [];
  
  // Weather Data
  WeatherData? _currentWeather;
  List<WeatherForecast> _weatherForecast = [];
  
  // Crop Health
  double _overallCropHealth = 0.85;
  
  // Alerts
  List<FarmAlert> _alerts = [];
  int _unreadAlerts = 0;
  
  // Disease Scans
  List<DiseaseScanResult> _recentScans = [];
  
  // Crop Recommendations
  List<CropRecommendation> _cropRecommendations = [];
  
  // Price Data
  List<CropPrice> _priceData = [];
  
  // Marketplace
  List<MarketListing> _myListings = [];
  List<MarketListing> _marketplaceListings = [];
  
  // Finance
  FinanceSummary? _financeSummary;
  
  // App State
  bool _isLoading = false;
  int _currentNavIndex = 0;
  String _selectedLanguage = 'en';
  
  // Getters
  String get userName => _userName;
  String get userPhone => _userPhone;
  String get userLocation => _userLocation;
  String get userAvatar => _userAvatar;
  Farm? get currentFarm => _currentFarm;
  List<Farm> get farms => _farms;
  WeatherData? get currentWeather => _currentWeather;
  List<WeatherForecast> get weatherForecast => _weatherForecast;
  double get overallCropHealth => _overallCropHealth;
  List<FarmAlert> get alerts => _alerts;
  int get unreadAlerts => _unreadAlerts;
  List<DiseaseScanResult> get recentScans => _recentScans;
  List<CropRecommendation> get cropRecommendations => _cropRecommendations;
  List<CropPrice> get priceData => _priceData;
  List<MarketListing> get myListings => _myListings;
  List<MarketListing> get marketplaceListings => _marketplaceListings;
  FinanceSummary? get financeSummary => _financeSummary;
  bool get isLoading => _isLoading;
  int get currentNavIndex => _currentNavIndex;
  String get selectedLanguage => _selectedLanguage;
  
  // Initialize with demo data
  AppProvider() {
    _initializeDemoData();
  }
  
  void _initializeDemoData() {
    // Initialize Farm
    _currentFarm = Farm(
      id: 'farm_001',
      name: 'Green Valley Farm',
      location: 'Nashik, Maharashtra',
      latitude: 19.9975,
      longitude: 73.7898,
      totalArea: 25.5,
      areaUnit: 'Acres',
      soilType: 'Black Cotton Soil',
      irrigationType: 'Drip Irrigation',
      crops: ['Grapes', 'Onion', 'Tomato'],
      createdAt: DateTime.now().subtract(const Duration(days: 365)),
    );
    
    _farms = [_currentFarm!];
    
    // Initialize Weather
    _currentWeather = WeatherData(
      temperature: 28,
      humidity: 65,
      windSpeed: 12,
      condition: 'Partly Cloudy',
      icon: 'partly_cloudy',
      feelsLike: 30,
      uvIndex: 6,
      precipitation: 20,
      visibility: 10,
      pressure: 1013,
      sunrise: '06:15 AM',
      sunset: '06:45 PM',
    );
    
    _weatherForecast = [
      WeatherForecast(day: 'Today', high: 32, low: 22, condition: 'Partly Cloudy', icon: 'partly_cloudy', rainChance: 20),
      WeatherForecast(day: 'Tomorrow', high: 30, low: 21, condition: 'Sunny', icon: 'sunny', rainChance: 10),
      WeatherForecast(day: 'Wed', high: 29, low: 20, condition: 'Cloudy', icon: 'cloudy', rainChance: 40),
      WeatherForecast(day: 'Thu', high: 27, low: 19, condition: 'Rainy', icon: 'rainy', rainChance: 80),
      WeatherForecast(day: 'Fri', high: 26, low: 18, condition: 'Rainy', icon: 'rainy', rainChance: 70),
      WeatherForecast(day: 'Sat', high: 28, low: 19, condition: 'Partly Cloudy', icon: 'partly_cloudy', rainChance: 30),
      WeatherForecast(day: 'Sun', high: 31, low: 21, condition: 'Sunny', icon: 'sunny', rainChance: 5),
    ];
    
    // Initialize Alerts
    _alerts = [
      FarmAlert(
        id: 'alert_001',
        type: AlertType.weather,
        title: 'Heavy Rainfall Expected',
        message: 'Heavy rainfall expected in next 48 hours. Consider harvesting mature crops.',
        severity: AlertSeverity.warning,
        timestamp: DateTime.now().subtract(const Duration(hours: 2)),
        isRead: false,
        actionRequired: true,
      ),
      FarmAlert(
        id: 'alert_002',
        type: AlertType.disease,
        title: 'Disease Outbreak Alert',
        message: 'Downy mildew detected in nearby farms. Inspect your grape vines.',
        severity: AlertSeverity.high,
        timestamp: DateTime.now().subtract(const Duration(hours: 5)),
        isRead: false,
        actionRequired: true,
      ),
      FarmAlert(
        id: 'alert_003',
        type: AlertType.price,
        title: 'Price Surge: Onions',
        message: 'Onion prices increased by 15% in Nashik market. Good time to sell!',
        severity: AlertSeverity.info,
        timestamp: DateTime.now().subtract(const Duration(hours: 8)),
        isRead: true,
        actionRequired: false,
      ),
      FarmAlert(
        id: 'alert_004',
        type: AlertType.irrigation,
        title: 'Irrigation Scheduled',
        message: 'Automated irrigation scheduled for tomorrow 5:00 AM for Grape Section.',
        severity: AlertSeverity.info,
        timestamp: DateTime.now().subtract(const Duration(days: 1)),
        isRead: true,
        actionRequired: false,
      ),
    ];
    
    _unreadAlerts = _alerts.where((a) => !a.isRead).length;
    
    // Initialize Crop Recommendations
    _cropRecommendations = [
      CropRecommendation(
        id: 'rec_001',
        cropName: 'Grapes (Thomson)',
        expectedYield: 12.5,
        expectedProfit: 450000,
        riskScore: 0.25,
        waterRequirement: 'Medium',
        season: 'Kharif',
        marketDemand: 'High',
        suitabilityScore: 0.92,
        reasons: ['Ideal soil type', 'Good market prices', 'Established supply chain'],
      ),
      CropRecommendation(
        id: 'rec_002',
        cropName: 'Pomegranate',
        expectedYield: 8.0,
        expectedProfit: 380000,
        riskScore: 0.30,
        waterRequirement: 'Low',
        season: 'Rabi',
        marketDemand: 'High',
        suitabilityScore: 0.88,
        reasons: ['Drought resistant', 'Export potential', 'Premium pricing'],
      ),
      CropRecommendation(
        id: 'rec_003',
        cropName: 'Onion (Red)',
        expectedYield: 180.0,
        expectedProfit: 320000,
        riskScore: 0.35,
        waterRequirement: 'Medium',
        season: 'Rabi',
        marketDemand: 'Very High',
        suitabilityScore: 0.85,
        reasons: ['High demand', 'Quick harvest', 'Storage friendly'],
      ),
    ];
    
    // Initialize Price Data
    _priceData = [
      CropPrice(
        cropName: 'Grapes',
        currentPrice: 85,
        unit: 'per kg',
        changePercent: 5.2,
        isIncreasing: true,
        marketName: 'Nashik APMC',
        lastUpdated: DateTime.now(),
        priceHistory: [75, 78, 80, 82, 85, 83, 85],
        predictedPrice: 90,
        bestSellDate: DateTime.now().add(const Duration(days: 7)),
      ),
      CropPrice(
        cropName: 'Onion',
        currentPrice: 32,
        unit: 'per kg',
        changePercent: 15.0,
        isIncreasing: true,
        marketName: 'Lasalgaon APMC',
        lastUpdated: DateTime.now(),
        priceHistory: [22, 24, 26, 28, 30, 31, 32],
        predictedPrice: 38,
        bestSellDate: DateTime.now().add(const Duration(days: 14)),
      ),
      CropPrice(
        cropName: 'Tomato',
        currentPrice: 45,
        unit: 'per kg',
        changePercent: -8.5,
        isIncreasing: false,
        marketName: 'Pune APMC',
        lastUpdated: DateTime.now(),
        priceHistory: [55, 52, 50, 48, 46, 45, 45],
        predictedPrice: 40,
        bestSellDate: DateTime.now(),
      ),
    ];
    
    // Initialize Marketplace Listings
    _myListings = [
      MarketListing(
        id: 'listing_001',
        farmerId: 'farmer_001',
        farmerName: 'Rajesh Kumar',
        cropName: 'Grapes (Thomson)',
        quantity: 500,
        unit: 'kg',
        pricePerUnit: 90,
        quality: 'A Grade',
        description: 'Fresh Thomson grapes, harvested this week. Sweet and seedless.',
        images: [],
        location: 'Nashik, Maharashtra',
        availableFrom: DateTime.now(),
        availableUntil: DateTime.now().add(const Duration(days: 7)),
        status: ListingStatus.active,
        bids: 3,
        views: 45,
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
      ),
    ];
    
    _marketplaceListings = [
      MarketListing(
        id: 'listing_002',
        farmerId: 'farmer_002',
        farmerName: 'Suresh Patil',
        cropName: 'Onion (Red)',
        quantity: 2000,
        unit: 'kg',
        pricePerUnit: 30,
        quality: 'A Grade',
        description: 'Fresh red onions from Nashik. Ideal for export.',
        images: [],
        location: 'Lasalgaon, Maharashtra',
        availableFrom: DateTime.now(),
        availableUntil: DateTime.now().add(const Duration(days: 14)),
        status: ListingStatus.active,
        bids: 8,
        views: 120,
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
      MarketListing(
        id: 'listing_003',
        farmerId: 'farmer_003',
        farmerName: 'Amit Sharma',
        cropName: 'Pomegranate',
        quantity: 800,
        unit: 'kg',
        pricePerUnit: 120,
        quality: 'Export Grade',
        description: 'Premium Bhagwa pomegranates. Export quality with excellent color.',
        images: [],
        location: 'Solapur, Maharashtra',
        availableFrom: DateTime.now(),
        availableUntil: DateTime.now().add(const Duration(days: 10)),
        status: ListingStatus.active,
        bids: 5,
        views: 89,
        createdAt: DateTime.now().subtract(const Duration(hours: 12)),
      ),
    ];
    
    // Initialize Finance Summary
    _financeSummary = FinanceSummary(
      totalIncome: 850000,
      totalExpenses: 320000,
      netProfit: 530000,
      pendingPayments: 125000,
      upcomingExpenses: 45000,
      monthlyIncome: [65000, 72000, 58000, 85000, 92000, 78000],
      monthlyExpenses: [28000, 32000, 25000, 35000, 38000, 30000],
      incomeBySource: {'Grapes': 450000, 'Onion': 280000, 'Tomato': 120000},
      expensesByCategory: {'Seeds': 45000, 'Fertilizer': 85000, 'Labor': 120000, 'Irrigation': 35000, 'Transport': 35000},
    );
    
    // Initialize Recent Scans
    _recentScans = [
      DiseaseScanResult(
        id: 'scan_001',
        cropName: 'Grape',
        imagePath: '',
        diseaseName: 'Healthy',
        confidence: 0.95,
        severity: DiseaseSeverity.healthy,
        description: 'Your grape leaves appear healthy with no signs of disease.',
        treatments: [],
        preventiveMeasures: ['Continue regular monitoring', 'Maintain proper spacing', 'Ensure good air circulation'],
        scannedAt: DateTime.now().subtract(const Duration(hours: 3)),
      ),
      DiseaseScanResult(
        id: 'scan_002',
        cropName: 'Tomato',
        imagePath: '',
        diseaseName: 'Early Blight',
        confidence: 0.87,
        severity: DiseaseSeverity.moderate,
        description: 'Early blight detected. Dark spots with concentric rings on lower leaves.',
        treatments: ['Apply copper-based fungicide', 'Remove affected leaves', 'Improve air circulation'],
        preventiveMeasures: ['Crop rotation', 'Proper spacing', 'Avoid overhead watering'],
        scannedAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
    ];
    
    notifyListeners();
  }
  
  // Methods
  void setNavIndex(int index) {
    _currentNavIndex = index;
    notifyListeners();
  }
  
  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
  
  void updateCropHealth(double health) {
    _overallCropHealth = health;
    notifyListeners();
  }
  
  void markAlertAsRead(String alertId) {
    final index = _alerts.indexWhere((a) => a.id == alertId);
    if (index != -1) {
      _alerts[index] = _alerts[index].copyWith(isRead: true);
      _unreadAlerts = _alerts.where((a) => !a.isRead).length;
      notifyListeners();
    }
  }
  
  void addScanResult(DiseaseScanResult result) {
    _recentScans.insert(0, result);
    notifyListeners();
  }
  
  void addMarketListing(MarketListing listing) {
    _myListings.add(listing);
    notifyListeners();
  }
  
  void setLanguage(String langCode) {
    _selectedLanguage = langCode;
    notifyListeners();
  }
  
  void updateUserInfo({String? name, String? phone, String? location}) {
    if (name != null) _userName = name;
    if (phone != null) _userPhone = phone;
    if (location != null) _userLocation = location;
    notifyListeners();
  }
  
  void refreshData() {
    setLoading(true);
    // Simulate API call
    Future.delayed(const Duration(seconds: 1), () {
      _initializeDemoData();
      setLoading(false);
    });
  }
}
