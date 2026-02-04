import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';

/// Authentication state enum
enum AuthState {
  initial,
  loading,
  authenticated,
  unauthenticated,
  error,
}

/// User model for authentication
class AuthUser {
  final String id;
  final String email;
  final String fullName;
  final String? phone;
  final String? avatarUrl;
  final String role;
  final String subscriptionTier;
  final String? address;
  final String? city;
  final String? district;
  final String? state;
  final String? pincode;
  final double? latitude;
  final double? longitude;
  final String language;
  final bool notificationEnabled;
  final bool emailVerified;
  final bool phoneVerified;
  final DateTime createdAt;

  AuthUser({
    required this.id,
    required this.email,
    required this.fullName,
    this.phone,
    this.avatarUrl,
    this.role = 'farmer',
    this.subscriptionTier = 'free',
    this.address,
    this.city,
    this.district,
    this.state,
    this.pincode,
    this.latitude,
    this.longitude,
    this.language = 'en',
    this.notificationEnabled = true,
    this.emailVerified = false,
    this.phoneVerified = false,
    required this.createdAt,
  });

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      id: json['id'] ?? '',
      email: json['email'] ?? '',
      fullName: json['full_name'] ?? '',
      phone: json['phone'],
      avatarUrl: json['avatar_url'],
      role: json['role'] ?? 'farmer',
      subscriptionTier: json['subscription_tier'] ?? 'free',
      address: json['address'],
      city: json['city'],
      district: json['district'],
      state: json['state'],
      pincode: json['pincode'],
      latitude: json['latitude']?.toDouble(),
      longitude: json['longitude']?.toDouble(),
      language: json['language'] ?? 'en',
      notificationEnabled: json['notification_enabled'] ?? true,
      emailVerified: json['email_verified'] ?? false,
      phoneVerified: json['phone_verified'] ?? false,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'full_name': fullName,
      'phone': phone,
      'avatar_url': avatarUrl,
      'role': role,
      'subscription_tier': subscriptionTier,
      'address': address,
      'city': city,
      'district': district,
      'state': state,
      'pincode': pincode,
      'latitude': latitude,
      'longitude': longitude,
      'language': language,
      'notification_enabled': notificationEnabled,
      'email_verified': emailVerified,
      'phone_verified': phoneVerified,
      'created_at': createdAt.toIso8601String(),
    };
  }

  AuthUser copyWith({
    String? id,
    String? email,
    String? fullName,
    String? phone,
    String? avatarUrl,
    String? role,
    String? subscriptionTier,
    String? address,
    String? city,
    String? district,
    String? state,
    String? pincode,
    double? latitude,
    double? longitude,
    String? language,
    bool? notificationEnabled,
    bool? emailVerified,
    bool? phoneVerified,
    DateTime? createdAt,
  }) {
    return AuthUser(
      id: id ?? this.id,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      role: role ?? this.role,
      subscriptionTier: subscriptionTier ?? this.subscriptionTier,
      address: address ?? this.address,
      city: city ?? this.city,
      district: district ?? this.district,
      state: state ?? this.state,
      pincode: pincode ?? this.pincode,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      language: language ?? this.language,
      notificationEnabled: notificationEnabled ?? this.notificationEnabled,
      emailVerified: emailVerified ?? this.emailVerified,
      phoneVerified: phoneVerified ?? this.phoneVerified,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

/// Authentication provider for managing user authentication state
class AuthProvider extends ChangeNotifier {
  // State
  AuthState _authState = AuthState.initial;
  AuthUser? _user;
  String? _errorMessage;
  String? _successMessage;
  
  // Token storage keys
  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _userDataKey = 'user_data';
  
  // API Service
  final ApiService _apiService = ApiService();
  
  // Getters
  AuthState get authState => _authState;
  AuthUser? get user => _user;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;
  bool get isAuthenticated => _authState == AuthState.authenticated && _user != null;
  bool get isLoading => _authState == AuthState.loading;
  
  // Initialize - check for existing tokens
  Future<void> initialize() async {
    _authState = AuthState.loading;
    notifyListeners();
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString(_accessTokenKey);
      
      if (accessToken != null && accessToken.isNotEmpty) {
        // Token exists, try to fetch user profile
        final result = await _apiService.getCurrentUser();
        
        if (result['success'] == true && result['data'] != null) {
          _user = AuthUser.fromJson(result['data']);
          _authState = AuthState.authenticated;
        } else {
          // Token invalid, clear storage
          await _clearTokens();
          _authState = AuthState.unauthenticated;
        }
      } else {
        _authState = AuthState.unauthenticated;
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Auth initialization error: $e');
      }
      _authState = AuthState.unauthenticated;
    }
    
    notifyListeners();
  }
  
  /// Register a new user
  Future<bool> register({
    required String email,
    required String password,
    required String fullName,
    String? phone,
    String role = 'farmer',
  }) async {
    _authState = AuthState.loading;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
    
    try {
      final result = await _apiService.register(
        email: email,
        password: password,
        fullName: fullName,
        phone: phone,
        role: role,
      );
      
      if (result['success'] == true) {
        // Save tokens
        await _saveTokens(
          result['access_token'] ?? '',
          result['refresh_token'] ?? '',
        );
        
        // Fetch user profile
        final userResult = await _apiService.getCurrentUser();
        if (userResult['success'] == true && userResult['data'] != null) {
          _user = AuthUser.fromJson(userResult['data']);
        }
        
        _authState = AuthState.authenticated;
        _successMessage = 'Registration successful! Welcome to AgriSense Pro.';
        notifyListeners();
        return true;
      } else {
        _errorMessage = result['message'] ?? 'Registration failed. Please try again.';
        _authState = AuthState.unauthenticated;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Network error. Please check your connection and try again.';
      _authState = AuthState.error;
      notifyListeners();
      return false;
    }
  }
  
  /// Login user
  Future<bool> login({
    required String email,
    required String password,
  }) async {
    _authState = AuthState.loading;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
    
    try {
      final result = await _apiService.login(
        email: email,
        password: password,
      );
      
      if (result['success'] == true) {
        // Save tokens
        await _saveTokens(
          result['access_token'] ?? '',
          result['refresh_token'] ?? '',
        );
        
        // Fetch user profile
        final userResult = await _apiService.getCurrentUser();
        if (userResult['success'] == true && userResult['data'] != null) {
          _user = AuthUser.fromJson(userResult['data']);
        }
        
        _authState = AuthState.authenticated;
        _successMessage = 'Welcome back, ${_user?.fullName ?? 'Farmer'}!';
        notifyListeners();
        return true;
      } else {
        _errorMessage = result['message'] ?? 'Invalid email or password.';
        _authState = AuthState.unauthenticated;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Network error. Please check your connection and try again.';
      _authState = AuthState.error;
      notifyListeners();
      return false;
    }
  }
  
  /// Logout user
  Future<void> logout() async {
    _authState = AuthState.loading;
    notifyListeners();
    
    try {
      // Call logout API (invalidates tokens on server)
      await _apiService.logout();
    } catch (e) {
      // Ignore API errors during logout
      if (kDebugMode) {
        debugPrint('Logout API error: $e');
      }
    }
    
    // Clear local tokens
    await _clearTokens();
    
    _user = null;
    _authState = AuthState.unauthenticated;
    _successMessage = 'You have been logged out successfully.';
    notifyListeners();
  }
  
  /// Forgot password - request reset
  Future<bool> forgotPassword({required String email}) async {
    _authState = AuthState.loading;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
    
    try {
      final result = await _apiService.forgotPassword(email: email);
      
      _authState = AuthState.unauthenticated;
      
      if (result['success'] == true) {
        _successMessage = result['message'] ?? 
            'If this email exists, a password reset link will be sent.';
        notifyListeners();
        return true;
      } else {
        // For security, we show same message even if email doesn't exist
        _successMessage = 'If this email exists, a password reset link will be sent.';
        notifyListeners();
        return true;
      }
    } catch (e) {
      _errorMessage = 'Network error. Please try again.';
      _authState = AuthState.error;
      notifyListeners();
      return false;
    }
  }
  
  /// Reset password with token
  Future<bool> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    _authState = AuthState.loading;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
    
    try {
      final result = await _apiService.resetPassword(
        token: token,
        newPassword: newPassword,
      );
      
      _authState = AuthState.unauthenticated;
      
      if (result['success'] == true) {
        _successMessage = 'Password reset successful! Please login with your new password.';
        notifyListeners();
        return true;
      } else {
        _errorMessage = result['message'] ?? 'Password reset failed. Please try again.';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Network error. Please try again.';
      _authState = AuthState.error;
      notifyListeners();
      return false;
    }
  }
  
  /// Update user profile
  Future<bool> updateProfile({
    String? fullName,
    String? phone,
    String? avatarUrl,
    String? address,
    String? city,
    String? district,
    String? state,
    String? pincode,
    double? latitude,
    double? longitude,
    String? language,
    bool? notificationEnabled,
  }) async {
    _authState = AuthState.loading;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
    
    try {
      final result = await _apiService.updateProfile(
        fullName: fullName,
        phone: phone,
        avatarUrl: avatarUrl,
        address: address,
        city: city,
        district: district,
        state: state,
        pincode: pincode,
        latitude: latitude,
        longitude: longitude,
        language: language,
        notificationEnabled: notificationEnabled,
      );
      
      if (result['success'] == true && result['data'] != null) {
        _user = AuthUser.fromJson(result['data']);
        _authState = AuthState.authenticated;
        _successMessage = 'Profile updated successfully!';
        notifyListeners();
        return true;
      } else {
        _errorMessage = result['message'] ?? 'Profile update failed.';
        _authState = AuthState.authenticated;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Network error. Please try again.';
      _authState = AuthState.authenticated;
      notifyListeners();
      return false;
    }
  }
  
  /// Change password
  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    _authState = AuthState.loading;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
    
    try {
      final result = await _apiService.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
      
      if (result['success'] == true) {
        // Password changed, need to re-login
        await _clearTokens();
        _user = null;
        _authState = AuthState.unauthenticated;
        _successMessage = 'Password changed successfully. Please login again.';
        notifyListeners();
        return true;
      } else {
        _errorMessage = result['message'] ?? 'Password change failed.';
        _authState = AuthState.authenticated;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Network error. Please try again.';
      _authState = AuthState.authenticated;
      notifyListeners();
      return false;
    }
  }
  
  /// Refresh tokens
  Future<bool> refreshTokens() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final refreshToken = prefs.getString(_refreshTokenKey);
      
      if (refreshToken == null || refreshToken.isEmpty) {
        return false;
      }
      
      final result = await _apiService.refreshToken(refreshToken: refreshToken);
      
      if (result['success'] == true) {
        await _saveTokens(
          result['access_token'] ?? '',
          result['refresh_token'] ?? '',
        );
        return true;
      }
      
      return false;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Token refresh error: $e');
      }
      return false;
    }
  }
  
  /// Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
  
  /// Clear success message
  void clearSuccess() {
    _successMessage = null;
    notifyListeners();
  }
  
  /// Save tokens to storage
  Future<void> _saveTokens(String accessToken, String refreshToken) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_accessTokenKey, accessToken);
    await prefs.setString(_refreshTokenKey, refreshToken);
    
    // Also update API service with new tokens
    _apiService.setAuthToken(accessToken);
  }
  
  /// Clear tokens from storage
  Future<void> _clearTokens() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_accessTokenKey);
    await prefs.remove(_refreshTokenKey);
    await prefs.remove(_userDataKey);
    
    // Clear API service token
    _apiService.clearAuthToken();
  }
  
  /// Get access token
  Future<String?> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_accessTokenKey);
  }
}
