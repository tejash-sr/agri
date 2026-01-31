class AppConstants {
  // App Info
  static const String appName = 'AgriSense Pro';
  static const String appVersion = '1.0.0';
  static const String appTagline = 'AI Crop Intelligence & Farmer Profit Engine';
  static const String appDescription = 'Empowering farmers with AI-driven insights for better yields, higher profits, and sustainable farming.';
  
  // API Endpoints (Placeholder for future backend integration)
  static const String baseUrl = 'https://api.agrisense.com/v1';
  static const String weatherApiUrl = 'https://api.openweathermap.org/data/2.5';
  static const String priceApiUrl = 'https://api.agmarknet.gov.in';
  
  // Storage Keys
  static const String userTokenKey = 'user_token';
  static const String userDataKey = 'user_data';
  static const String farmDataKey = 'farm_data';
  static const String settingsKey = 'app_settings';
  static const String languageKey = 'language';
  static const String themeKey = 'theme_mode';
  static const String onboardingKey = 'onboarding_complete';
  
  // Supported Languages
  static const Map<String, String> supportedLanguages = {
    'en': 'English',
    'hi': 'हिंदी',
    'ta': 'தமிழ்',
    'te': 'తెలుగు',
    'kn': 'ಕನ್ನಡ',
    'mr': 'मराठी',
    'gu': 'ગુજરાતી',
    'bn': 'বাংলা',
    'pa': 'ਪੰਜਾਬੀ',
  };
  
  // Crop Categories
  static const List<String> cropCategories = [
    'Cereals',
    'Pulses',
    'Oilseeds',
    'Vegetables',
    'Fruits',
    'Spices',
    'Commercial Crops',
    'Fiber Crops',
  ];
  
  // Common Crops in India
  static const List<String> commonCrops = [
    'Rice',
    'Wheat',
    'Maize',
    'Cotton',
    'Sugarcane',
    'Groundnut',
    'Soybean',
    'Mustard',
    'Chickpea',
    'Pigeon Pea',
    'Tomato',
    'Onion',
    'Potato',
    'Chilli',
    'Turmeric',
    'Mango',
    'Banana',
    'Grapes',
    'Coconut',
    'Tea',
    'Coffee',
    'Jute',
    'Tobacco',
  ];
  
  // Soil Types
  static const List<String> soilTypes = [
    'Alluvial Soil',
    'Black Cotton Soil',
    'Red Soil',
    'Laterite Soil',
    'Desert Soil',
    'Mountain Soil',
    'Peaty Soil',
    'Saline Soil',
  ];
  
  // Seasons
  static const List<String> farmingSeasons = [
    'Kharif (Monsoon)',
    'Rabi (Winter)',
    'Zaid (Summer)',
  ];
  
  // Disease Severity Levels
  static const List<String> diseaseSeverity = [
    'Healthy',
    'Mild',
    'Moderate',
    'Severe',
    'Critical',
  ];
  
  // Weather Conditions
  static const List<String> weatherConditions = [
    'Sunny',
    'Partly Cloudy',
    'Cloudy',
    'Rainy',
    'Thunderstorm',
    'Foggy',
    'Windy',
    'Hailstorm',
  ];
  
  // Units
  static const String areaUnit = 'Acres';
  static const String areaUnitHectare = 'Hectares';
  static const String weightUnit = 'Quintals';
  static const String weightUnitKg = 'Kg';
  static const String currencySymbol = '₹';
  static const String temperatureUnit = '°C';
  
  // Animation Durations
  static const Duration shortAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 350);
  static const Duration longAnimation = Duration(milliseconds: 500);
  
  // UI Constants
  static const double borderRadius = 16.0;
  static const double borderRadiusSmall = 8.0;
  static const double borderRadiusLarge = 24.0;
  static const double cardElevation = 4.0;
  static const double spacing = 16.0;
  static const double spacingSmall = 8.0;
  static const double spacingLarge = 24.0;
  
  // Chart Colors
  static const List<int> chartColors = [
    0xFF2E7D32, // Primary Green
    0xFF0288D1, // Sky Blue
    0xFFF9A825, // Sun Yellow
    0xFF00897B, // Ocean Teal
    0xFFFF6F00, // Harvest Orange
    0xFF6D4C41, // Soil Brown
    0xFF7B1FA2, // Purple
    0xFFE53935, // Red
  ];
}

// Feature Flags for Free/Premium Tiers
class FeatureFlags {
  // Free Tier Features
  static const bool enableDiseaseDetection = true;
  static const bool enableWeatherAlerts = true;
  static const bool enableBasicCropRecommendation = true;
  static const bool enablePriceTracking = true;
  static const bool enableBasicMarketplace = true;
  
  // Premium Features (Disabled for Free Tier)
  static const bool enableAdvancedAI = false;
  static const bool enableSatelliteMonitoring = false;
  static const bool enableDigitalTwin = true; // Demo mode for free tier
  static const bool enableVoiceAssistant = true; // Basic voice for free
  static const bool enablePremiumAnalytics = false;
  static const bool enableExportReports = false;
  static const bool enableMultiFarmSupport = false;
  static const bool enableApiAccess = false;
  
  // Demo Mode Limits
  static const int freeScansPerDay = 10;
  static const int freeMarketListings = 5;
  static const int freeWeatherAlertsPerDay = 20;
}
