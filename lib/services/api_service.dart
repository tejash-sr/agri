/// AgriSense Pro - API Service
/// Handles all communication with the custom backend API
/// No BaaS - Direct REST API integration

import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// API Configuration
class ApiConfig {
  // ========================================================================
  // IMPORTANT: Update this URL before deployment
  // ========================================================================
  // For local development:
  static const String baseUrl = 'http://localhost:8000/api/v1';
  
  // For production (replace with your actual server URL):
  // static const String baseUrl = 'https://api.agrisensepro.com/api/v1';
  
  // For Android emulator connecting to host machine:
  // static const String baseUrl = 'http://10.0.2.2:8000/api/v1';
  
  // Request timeout
  static const Duration timeout = Duration(seconds: 30);
  
  // Headers
  static Map<String, String> get defaultHeaders => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };
}

/// API Response wrapper
class ApiResponse<T> {
  final bool success;
  final T? data;
  final String? message;
  final String? errorCode;
  final int statusCode;
  
  ApiResponse({
    required this.success,
    this.data,
    this.message,
    this.errorCode,
    required this.statusCode,
  });
  
  factory ApiResponse.success(T data, int statusCode) {
    return ApiResponse(
      success: true,
      data: data,
      statusCode: statusCode,
    );
  }
  
  factory ApiResponse.error(String message, int statusCode, [String? errorCode]) {
    return ApiResponse(
      success: false,
      message: message,
      errorCode: errorCode,
      statusCode: statusCode,
    );
  }
}

/// Token Storage
class TokenStorage {
  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _tokenExpiryKey = 'token_expiry';
  
  static Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
    required int expiresIn,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_accessTokenKey, accessToken);
    await prefs.setString(_refreshTokenKey, refreshToken);
    await prefs.setInt(_tokenExpiryKey, 
      DateTime.now().millisecondsSinceEpoch + (expiresIn * 1000));
  }
  
  static Future<String?> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_accessTokenKey);
  }
  
  static Future<String?> getRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_refreshTokenKey);
  }
  
  static Future<bool> isTokenExpired() async {
    final prefs = await SharedPreferences.getInstance();
    final expiry = prefs.getInt(_tokenExpiryKey) ?? 0;
    return DateTime.now().millisecondsSinceEpoch >= expiry;
  }
  
  static Future<void> clearTokens() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_accessTokenKey);
    await prefs.remove(_refreshTokenKey);
    await prefs.remove(_tokenExpiryKey);
  }
}

/// Main API Service
class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();
  
  final http.Client _client = http.Client();
  
  /// Get headers with authentication token
  Future<Map<String, String>> _getHeaders({bool requireAuth = true}) async {
    final headers = Map<String, String>.from(ApiConfig.defaultHeaders);
    
    if (requireAuth) {
      final token = await TokenStorage.getAccessToken();
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
    }
    
    return headers;
  }
  
  /// Handle API response
  ApiResponse<T> _handleResponse<T>(
    http.Response response,
    T Function(dynamic)? parser,
  ) {
    try {
      final body = jsonDecode(response.body);
      
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = parser != null ? parser(body) : body as T;
        return ApiResponse.success(data, response.statusCode);
      } else {
        return ApiResponse.error(
          body['message'] ?? 'An error occurred',
          response.statusCode,
          body['error_code'],
        );
      }
    } catch (e) {
      return ApiResponse.error(
        'Failed to parse response: $e',
        response.statusCode,
      );
    }
  }
  
  /// Generic GET request
  Future<ApiResponse<T>> get<T>(
    String endpoint, {
    Map<String, String>? queryParams,
    T Function(dynamic)? parser,
    bool requireAuth = true,
  }) async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}$endpoint')
        .replace(queryParameters: queryParams);
      final headers = await _getHeaders(requireAuth: requireAuth);
      
      final response = await _client
        .get(uri, headers: headers)
        .timeout(ApiConfig.timeout);
      
      return _handleResponse(response, parser);
    } on SocketException {
      return ApiResponse.error('No internet connection', 0);
    } on HttpException {
      return ApiResponse.error('Server error', 500);
    } catch (e) {
      return ApiResponse.error('Request failed: $e', 0);
    }
  }
  
  /// Generic POST request
  Future<ApiResponse<T>> post<T>(
    String endpoint, {
    Map<String, dynamic>? body,
    T Function(dynamic)? parser,
    bool requireAuth = true,
  }) async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}$endpoint');
      final headers = await _getHeaders(requireAuth: requireAuth);
      
      final response = await _client
        .post(uri, headers: headers, body: jsonEncode(body ?? {}))
        .timeout(ApiConfig.timeout);
      
      return _handleResponse(response, parser);
    } on SocketException {
      return ApiResponse.error('No internet connection', 0);
    } on HttpException {
      return ApiResponse.error('Server error', 500);
    } catch (e) {
      return ApiResponse.error('Request failed: $e', 0);
    }
  }
  
  /// Generic PUT request
  Future<ApiResponse<T>> put<T>(
    String endpoint, {
    Map<String, dynamic>? body,
    T Function(dynamic)? parser,
    bool requireAuth = true,
  }) async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}$endpoint');
      final headers = await _getHeaders(requireAuth: requireAuth);
      
      final response = await _client
        .put(uri, headers: headers, body: jsonEncode(body ?? {}))
        .timeout(ApiConfig.timeout);
      
      return _handleResponse(response, parser);
    } on SocketException {
      return ApiResponse.error('No internet connection', 0);
    } on HttpException {
      return ApiResponse.error('Server error', 500);
    } catch (e) {
      return ApiResponse.error('Request failed: $e', 0);
    }
  }
  
  /// Generic DELETE request
  Future<ApiResponse<T>> delete<T>(
    String endpoint, {
    T Function(dynamic)? parser,
    bool requireAuth = true,
  }) async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}$endpoint');
      final headers = await _getHeaders(requireAuth: requireAuth);
      
      final response = await _client
        .delete(uri, headers: headers)
        .timeout(ApiConfig.timeout);
      
      return _handleResponse(response, parser);
    } on SocketException {
      return ApiResponse.error('No internet connection', 0);
    } on HttpException {
      return ApiResponse.error('Server error', 500);
    } catch (e) {
      return ApiResponse.error('Request failed: $e', 0);
    }
  }
  
  // ==========================================================================
  // Authentication APIs
  // ==========================================================================
  
  /// Register a new user
  Future<ApiResponse<Map<String, dynamic>>> register({
    required String email,
    required String password,
    required String fullName,
    String? phone,
    String role = 'farmer',
  }) async {
    final response = await post<Map<String, dynamic>>(
      '/auth/register',
      body: {
        'email': email,
        'password': password,
        'full_name': fullName,
        if (phone != null) 'phone': phone,
        'role': role,
      },
      requireAuth: false,
    );
    
    if (response.success && response.data != null) {
      await TokenStorage.saveTokens(
        accessToken: response.data!['access_token'],
        refreshToken: response.data!['refresh_token'],
        expiresIn: response.data!['expires_in'] ?? 1800,
      );
    }
    
    return response;
  }
  
  /// Login user
  Future<ApiResponse<Map<String, dynamic>>> login({
    required String email,
    required String password,
  }) async {
    final response = await post<Map<String, dynamic>>(
      '/auth/login',
      body: {
        'email': email,
        'password': password,
      },
      requireAuth: false,
    );
    
    if (response.success && response.data != null) {
      await TokenStorage.saveTokens(
        accessToken: response.data!['access_token'],
        refreshToken: response.data!['refresh_token'],
        expiresIn: response.data!['expires_in'] ?? 1800,
      );
    }
    
    return response;
  }
  
  /// Logout user
  Future<ApiResponse<void>> logout() async {
    final response = await post<void>('/auth/logout');
    await TokenStorage.clearTokens();
    return response;
  }
  
  /// Get current user profile
  Future<ApiResponse<Map<String, dynamic>>> getCurrentUser() async {
    return get<Map<String, dynamic>>('/auth/me');
  }
  
  /// Refresh access token
  Future<ApiResponse<Map<String, dynamic>>> refreshToken() async {
    final refreshToken = await TokenStorage.getRefreshToken();
    if (refreshToken == null) {
      return ApiResponse.error('No refresh token', 401);
    }
    
    final response = await post<Map<String, dynamic>>(
      '/auth/refresh',
      body: {'refresh_token': refreshToken},
      requireAuth: false,
    );
    
    if (response.success && response.data != null) {
      await TokenStorage.saveTokens(
        accessToken: response.data!['access_token'],
        refreshToken: response.data!['refresh_token'],
        expiresIn: response.data!['expires_in'] ?? 1800,
      );
    }
    
    return response;
  }
  
  // ==========================================================================
  // Farm APIs
  // ==========================================================================
  
  /// Get all farms for current user
  Future<ApiResponse<List<dynamic>>> getFarms() async {
    return get<List<dynamic>>('/farms');
  }
  
  /// Create a new farm
  Future<ApiResponse<Map<String, dynamic>>> createFarm({
    required String name,
    required double totalAreaAcres,
    String? farmType,
    String? address,
    String? village,
    String? district,
    String? state,
    double? latitude,
    double? longitude,
    String? soilType,
    String? waterSource,
    String? irrigationType,
    bool isPrimary = false,
  }) async {
    return post<Map<String, dynamic>>(
      '/farms',
      body: {
        'name': name,
        'total_area_acres': totalAreaAcres,
        if (farmType != null) 'farm_type': farmType,
        if (address != null) 'address': address,
        if (village != null) 'village': village,
        if (district != null) 'district': district,
        if (state != null) 'state': state,
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
        if (soilType != null) 'soil_type': soilType,
        if (waterSource != null) 'water_source': waterSource,
        if (irrigationType != null) 'irrigation_type': irrigationType,
        'is_primary': isPrimary,
      },
    );
  }
  
  /// Get farm by ID
  Future<ApiResponse<Map<String, dynamic>>> getFarm(String farmId) async {
    return get<Map<String, dynamic>>('/farms/$farmId');
  }
  
  /// Update farm
  Future<ApiResponse<Map<String, dynamic>>> updateFarm(
    String farmId,
    Map<String, dynamic> data,
  ) async {
    return put<Map<String, dynamic>>('/farms/$farmId', body: data);
  }
  
  /// Delete farm
  Future<ApiResponse<void>> deleteFarm(String farmId) async {
    return delete<void>('/farms/$farmId');
  }
  
  /// Get farm summary
  Future<ApiResponse<Map<String, dynamic>>> getFarmSummary(String farmId) async {
    return get<Map<String, dynamic>>('/farms/$farmId/summary');
  }
  
  // ==========================================================================
  // Crop APIs
  // ==========================================================================
  
  /// Get crop master data
  Future<ApiResponse<List<dynamic>>> getCropMaster() async {
    return get<List<dynamic>>('/crops/master');
  }
  
  /// Get all crops
  Future<ApiResponse<List<dynamic>>> getCrops({
    String? farmId,
    String? status,
  }) async {
    return get<List<dynamic>>(
      '/crops',
      queryParams: {
        if (farmId != null) 'farm_id': farmId,
        if (status != null) 'status': status,
      },
    );
  }
  
  /// Create a new crop
  Future<ApiResponse<Map<String, dynamic>>> createCrop({
    required String farmId,
    required int cropMasterId,
    required double areaAcres,
    String? variety,
    String? sowingDate,
    String? expectedHarvestDate,
    String? notes,
  }) async {
    return post<Map<String, dynamic>>(
      '/crops',
      body: {
        'farm_id': farmId,
        'crop_master_id': cropMasterId,
        'area_acres': areaAcres,
        if (variety != null) 'variety': variety,
        if (sowingDate != null) 'sowing_date': sowingDate,
        if (expectedHarvestDate != null) 'expected_harvest_date': expectedHarvestDate,
        if (notes != null) 'notes': notes,
      },
    );
  }
  
  /// Get crop recommendations for a farm
  Future<ApiResponse<List<dynamic>>> getCropRecommendations(String farmId) async {
    return get<List<dynamic>>('/crops/recommendations/$farmId');
  }
  
  // ==========================================================================
  // Disease Detection APIs
  // ==========================================================================
  
  /// Get disease catalog
  Future<ApiResponse<List<dynamic>>> getDiseaseCatalog() async {
    return get<List<dynamic>>('/diseases/catalog');
  }
  
  /// Submit disease scan
  Future<ApiResponse<Map<String, dynamic>>> submitDiseaseScan({
    required String imageUrl,
    String? cropId,
    String? farmId,
    double? latitude,
    double? longitude,
  }) async {
    return post<Map<String, dynamic>>(
      '/diseases/scan',
      body: {
        'image_url': imageUrl,
        if (cropId != null) 'crop_id': cropId,
        if (farmId != null) 'farm_id': farmId,
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
      },
    );
  }
  
  /// Get disease scan history
  Future<ApiResponse<List<dynamic>>> getDiseaseScans({
    String? farmId,
    String? cropId,
  }) async {
    return get<List<dynamic>>(
      '/diseases/scans',
      queryParams: {
        if (farmId != null) 'farm_id': farmId,
        if (cropId != null) 'crop_id': cropId,
      },
    );
  }
  
  // ==========================================================================
  // Weather APIs
  // ==========================================================================
  
  /// Get current weather
  Future<ApiResponse<Map<String, dynamic>>> getCurrentWeather({
    required double latitude,
    required double longitude,
  }) async {
    return get<Map<String, dynamic>>(
      '/weather/current',
      queryParams: {
        'latitude': latitude.toString(),
        'longitude': longitude.toString(),
      },
    );
  }
  
  /// Get weather forecast
  Future<ApiResponse<List<dynamic>>> getWeatherForecast({
    required double latitude,
    required double longitude,
    int days = 7,
  }) async {
    return get<List<dynamic>>(
      '/weather/forecast',
      queryParams: {
        'latitude': latitude.toString(),
        'longitude': longitude.toString(),
        'days': days.toString(),
      },
    );
  }
  
  /// Get farm weather with advisories
  Future<ApiResponse<Map<String, dynamic>>> getFarmWeather(String farmId) async {
    return get<Map<String, dynamic>>('/weather/farm/$farmId');
  }
  
  // ==========================================================================
  // Price APIs
  // ==========================================================================
  
  /// Get current prices
  Future<ApiResponse<List<dynamic>>> getCurrentPrices({
    int? cropId,
    String? marketId,
    String? state,
  }) async {
    return get<List<dynamic>>(
      '/prices/current',
      queryParams: {
        if (cropId != null) 'crop_id': cropId.toString(),
        if (marketId != null) 'market_id': marketId,
        if (state != null) 'state': state,
      },
    );
  }
  
  /// Get price prediction
  Future<ApiResponse<Map<String, dynamic>>> getPricePrediction({
    required int cropId,
    String? marketId,
    int daysAhead = 30,
  }) async {
    return get<Map<String, dynamic>>(
      '/prices/prediction',
      queryParams: {
        'crop_id': cropId.toString(),
        if (marketId != null) 'market_id': marketId,
        'days_ahead': daysAhead.toString(),
      },
    );
  }
  
  /// Get markets
  Future<ApiResponse<List<dynamic>>> getMarkets({
    String? state,
    String? district,
  }) async {
    return get<List<dynamic>>(
      '/prices/markets',
      queryParams: {
        if (state != null) 'state': state,
        if (district != null) 'district': district,
      },
    );
  }
  
  // ==========================================================================
  // Marketplace APIs
  // ==========================================================================
  
  /// Get marketplace listings
  Future<ApiResponse<List<dynamic>>> getListings({
    String? cropName,
    String? state,
    double? minPrice,
    double? maxPrice,
    bool? isOrganic,
  }) async {
    return get<List<dynamic>>(
      '/marketplace/listings',
      queryParams: {
        if (cropName != null) 'crop_name': cropName,
        if (state != null) 'state': state,
        if (minPrice != null) 'min_price': minPrice.toString(),
        if (maxPrice != null) 'max_price': maxPrice.toString(),
        if (isOrganic != null) 'is_organic': isOrganic.toString(),
      },
      requireAuth: false,
    );
  }
  
  /// Create listing
  Future<ApiResponse<Map<String, dynamic>>> createListing({
    required String title,
    required String cropName,
    required double quantity,
    required double pricePerUnit,
    String? description,
    String? variety,
    String unit = 'kg',
    bool negotiable = true,
    String? city,
    String? state,
    bool deliveryAvailable = false,
    List<String>? images,
  }) async {
    return post<Map<String, dynamic>>(
      '/marketplace/listings',
      body: {
        'title': title,
        'crop_name': cropName,
        'quantity': quantity,
        'price_per_unit': pricePerUnit,
        'unit': unit,
        'negotiable': negotiable,
        'delivery_available': deliveryAvailable,
        if (description != null) 'description': description,
        if (variety != null) 'variety': variety,
        if (city != null) 'city': city,
        if (state != null) 'state': state,
        if (images != null) 'images': images,
      },
    );
  }
  
  /// Get my listings
  Future<ApiResponse<List<dynamic>>> getMyListings() async {
    return get<List<dynamic>>('/marketplace/listings/my');
  }
  
  // ==========================================================================
  // Dashboard API
  // ==========================================================================
  
  /// Get dashboard summary
  Future<ApiResponse<Map<String, dynamic>>> getDashboard() async {
    return get<Map<String, dynamic>>('/dashboard');
  }
}

// Global API service instance
final apiService = ApiService();
