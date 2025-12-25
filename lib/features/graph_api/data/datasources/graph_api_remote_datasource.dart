import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:hive/hive.dart';
import '../models/auth_response_model.dart';
import '../models/graph_data_model.dart';

/// Remote data source for graph API
class GraphApiRemoteDataSource {
  static const String _baseUrl = 'https://api.milloserver.uk';
  static const String _loginEndpoint = '/api/login';
  static const String _graphEndpoint = '/api/millometer/by-controller';
  
  // Real API credentials
  static const String _email = 'jasontkh.2016@gmail.com';
  static const String _password = '1234abcd';
  
  static const String _tokenBoxName = 'apiAuthBox';
  static const String _tokenKey = 'bearerToken';
  static const String _expiryKey = 'tokenExpiry';
  
  // Mock data mode for testing when API has no data
  static const bool _useMockData = false; // Set to false to use real API

  final http.Client client;
  late Box _authBox;

  GraphApiRemoteDataSource({required this.client});

  /// Initialize Hive box for token storage
  Future<void> initialize() async {
    _authBox = await Hive.openBox(_tokenBoxName);
  }

  /// Get valid bearer token (login if needed)
  Future<String> _getValidToken() async {
    // Check if we have a cached token
    final cachedToken = _authBox.get(_tokenKey);
    final cachedExpiry = _authBox.get(_expiryKey);

    if (cachedToken != null && cachedExpiry != null) {
      final expiryDate = DateTime.parse(cachedExpiry);
      if (DateTime.now().isBefore(expiryDate.subtract(const Duration(minutes: 5)))) {
        // Token is still valid (with 5 min buffer)
        debugPrint('🔑 Using cached API token');
        return cachedToken;
      }
    }

    // Token expired or doesn't exist, login
    debugPrint('🔑 Logging in to API...');
    return await _login();
  }

  /// Login to API and get bearer token
  Future<String> _login() async {
    try {
      final response = await client.post(
        Uri.parse('$_baseUrl$_loginEndpoint'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': _email,
          'password': _password,
        }),
      );

      debugPrint('🔑 Login response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final authResponse = AuthResponseModel.fromJson(jsonDecode(response.body));
        
        if (authResponse.success) {
          // Cache token
          await _authBox.put(_tokenKey, authResponse.data.token);
          await _authBox.put(_expiryKey, authResponse.data.expiresAt);
          
          debugPrint('✅ API login successful, token cached');
          return authResponse.data.token;
        } else {
          throw Exception('Login failed: ${authResponse.message}');
        }
      } else {
        throw Exception('Login failed with status: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ Login error: $e');
      rethrow;
    }
  }

  /// Fetch graph data by controller ID
  Future<GraphDataModel> getGraphData({
    required String controllerId,
    required DateTime startTime,
    required DateTime endTime,
  }) async {
    // Mock data mode for testing when API database is empty
    if (_useMockData) {
      debugPrint('📊 Using MOCK DATA for testing (API database is empty)');
      return _generateMockData(startTime, endTime);
    }
    
    try {
      final token = await _getValidToken();
      
      // Format dates to ISO 8601 string with timezone offset
      // Get the timezone offset in hours
      final tzOffset = startTime.timeZoneOffset;
      final hours = tzOffset.inHours;
      final minutes = tzOffset.inMinutes.remainder(60).abs();
      final sign = hours >= 0 ? '+' : '-';
      final tzString = '$sign${hours.abs().toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}';
      
      final startTimeStr = '${startTime.toIso8601String()}$tzString';
      final endTimeStr = '${endTime.toIso8601String()}$tzString';

      final uri = Uri.parse('$_baseUrl$_graphEndpoint').replace(
        queryParameters: {
          'controller_id': controllerId,
          'from': startTimeStr,
          'to': endTimeStr,
          'limit': '1000', // Get up to 1000 data points for the graph
          'page': '1',
        },
      );

      debugPrint('📊 Fetching graph data: $uri');

      final response = await client.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      debugPrint('📊 Graph data response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        debugPrint('📊 Raw API response: $jsonData');
        debugPrint('📊 API response keys: ${jsonData.keys.toList()}');
        if (jsonData['data'] != null) {
          debugPrint('📊 Data array length: ${jsonData['data'].length}');
          if (jsonData['data'].length > 0) {
            debugPrint('📊 First data point structure: ${jsonData['data'][0]}');
          }
        }
        return GraphDataModel.fromJson(jsonData);
      } else if (response.statusCode == 401) {
        // Token expired, clear cache and retry once
        await _authBox.clear();
        debugPrint('⚠️ Token expired, retrying...');
        return await getGraphData(
          controllerId: controllerId,
          startTime: startTime,
          endTime: endTime,
        );
      } else {
        throw Exception('Failed to fetch graph data: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ Graph data fetch error: $e');
      rethrow;
    }
  }

  /// Clear cached token (for testing or logout)
  Future<void> clearToken() async {
    await _authBox.clear();
    debugPrint('🗑️ API token cleared');
  }
  
  /// Generate mock data for testing when API database is empty
  GraphDataModel _generateMockData(DateTime startTime, DateTime endTime) {
    final random = DateTime.now().millisecondsSinceEpoch;
    final humidityPoints = <Map<String, dynamic>>[];
    final temperaturePoints = <Map<String, dynamic>>[];
    final waterLevelPoints = <Map<String, dynamic>>[];
    
    // Generate 24 hourly data points
    for (int hour = 0; hour < 24; hour++) {
      final timestamp = startTime.add(Duration(hours: hour));
      final timeStr = timestamp.toIso8601String();
      
      // Generate realistic sensor values with some variation
      final tempBase = 25.0 + (hour / 24) * 5; // 25-30°C range
      final humidityBase = 80.0 + (hour % 12) * 1.5; // 80-98% range
      final waterBase = 70.0 - (hour / 24) * 20; // 70-50% range (decreases)
      
      temperaturePoints.add({
        'value': tempBase + ((random + hour) % 20) / 10,
        'time': timeStr,
      });
      
      humidityPoints.add({
        'value': humidityBase + ((random + hour) % 15) / 10,
        'time': timeStr,
      });
      
      waterLevelPoints.add({
        'value': waterBase + ((random + hour) % 10) / 10,
        'time': timeStr,
      });
    }
    
    debugPrint('📊 Mock data generated: ${humidityPoints.length} points per sensor');
    
    return GraphDataModel.fromJson({
      'humidity': humidityPoints,
      'temperature': temperaturePoints,
      'water_level': waterLevelPoints,
    });
  }
}

// Debug print helper
void debugPrint(String message) {
  print(message);
}
