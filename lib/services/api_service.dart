import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  String _baseUrl = 'http://127.0.0.1:8000';
  String? _sessionCookie;
  String? _csrfToken;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Auto-detect base URL based on platform
    if (Platform.isAndroid) {
      _baseUrl = 'http://10.0.2.2:8000';
    } else {
      _baseUrl = 'http://127.0.0.1:8000';
    }

    // Load custom base URL if configured by user
    final customUrl = prefs.getString('api_custom_base_url');
    if (customUrl != null && customUrl.isNotEmpty) {
      _baseUrl = customUrl;
    }

    // Load credentials
    _sessionCookie = prefs.getString('api_session_cookie');
    _csrfToken = prefs.getString('api_csrf_token');
  }

  String get baseUrl => _baseUrl;

  Future<void> setCustomBaseUrl(String url) async {
    _baseUrl = url;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('api_custom_base_url', url);
  }

  Map<String, String> _headers() {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    List<String> cookies = [];
    if (_sessionCookie != null) {
      cookies.add(_sessionCookie!);
    }
    if (_csrfToken != null) {
      cookies.add('csrftoken=$_csrfToken');
      headers['X-CSRFToken'] = _csrfToken!;
    }

    if (cookies.isNotEmpty) {
      headers['Cookie'] = cookies.join('; ');
    }

    return headers;
  }

  void _updateCookies(http.Response response) async {
    final rawCookie = response.headers['set-cookie'];
    if (rawCookie != null) {
      final prefs = await SharedPreferences.getInstance();

      // Extract sessionid
      final sessionMatch = RegExp(r'sessionid=([^;]+)').firstMatch(rawCookie);
      if (sessionMatch != null) {
        _sessionCookie = 'sessionid=${sessionMatch.group(1)}';
        await prefs.setString('api_session_cookie', _sessionCookie!);
      }

      // Extract csrftoken
      final csrfMatch = RegExp(r'csrftoken=([^;]+)').firstMatch(rawCookie);
      if (csrfMatch != null) {
        _csrfToken = csrfMatch.group(1);
        await prefs.setString('api_csrf_token', _csrfToken!);
      }
    }
  }

  Future<void> clearSession() async {
    _sessionCookie = null;
    _csrfToken = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('api_session_cookie');
    await prefs.remove('api_csrf_token');
    await prefs.remove('profile_name');
    await prefs.remove('profile_email');
    await prefs.remove('profile_avatar_color');
  }

  // ==========================================
  // AUTHENTICATION APIs
  // ==========================================

  Future<Map<String, dynamic>> login(String email, String password) async {
    final url = Uri.parse('$_baseUrl/api/auth/login');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    if (response.statusCode == 200) {
      _updateCookies(response);
      final data = jsonDecode(response.body);
      
      // Save profile info locally
      final user = data['user'];
      if (user != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('profile_name', user['name'] ?? '');
        await prefs.setString('profile_email', user['email'] ?? '');
        await prefs.setString('profile_avatar_color', user['avatar_color'] ?? '#7c3aed');
      }
      return data;
    } else {
      final data = jsonDecode(response.body);
      throw Exception(data['error'] ?? 'Gagal login.');
    }
  }

  Future<Map<String, dynamic>> register(String name, String email, String password) async {
    final url = Uri.parse('$_baseUrl/api/auth/register');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'name': name, 'email': email, 'password': password}),
    );

    if (response.statusCode == 201) {
      _updateCookies(response);
      final data = jsonDecode(response.body);
      
      final user = data['user'];
      if (user != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('profile_name', user['name'] ?? '');
        await prefs.setString('profile_email', user['email'] ?? '');
        await prefs.setString('profile_avatar_color', user['avatar_color'] ?? '#7c3aed');
      }
      return data;
    } else {
      final data = jsonDecode(response.body);
      throw Exception(data['error'] ?? 'Gagal registrasi.');
    }
  }

  Future<void> logout() async {
    try {
      final url = Uri.parse('$_baseUrl/api/auth/logout');
      await http.post(url, headers: _headers());
    } finally {
      await clearSession();
    }
  }

  // ==========================================
  // PROJECT APIs (Grid 1)
  // ==========================================

  Future<List<Map<String, dynamic>>> getProjects() async {
    final url = Uri.parse('$_baseUrl/api/ic_projects/');
    final response = await http.get(url, headers: _headers());

    if (response.statusCode == 200) {
      final List<dynamic> decoded = jsonDecode(response.body);
      return decoded.map((e) => Map<String, dynamic>.from(e)).toList();
    } else {
      throw Exception('Gagal memuat daftar project dari server.');
    }
  }

  Future<Map<String, dynamic>> createProject(String name, String description, bool isPublic) async {
    final url = Uri.parse('$_baseUrl/api/v2/collaboration/');
    final response = await http.post(
      url,
      headers: _headers(),
      body: jsonEncode({
        'project_name': name,
        'description': description,
        'visibility': isPublic ? 'public' : 'private',
        'status': 'active',
        'members': [],
      }),
    );

    if (response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Gagal membuat project baru di server.');
    }
  }

  Future<void> deleteProject(int id) async {
    final url = Uri.parse('$_baseUrl/api/v2/collaboration/$id/');
    final response = await http.delete(url, headers: _headers());

    if (response.statusCode != 204 && response.statusCode != 200) {
      throw Exception('Gagal menghapus project di server.');
    }
  }

  // ==========================================
  // INCOMING SUBMISSIONS APIs (Grid 2 & 3)
  // ==========================================

  Future<Map<String, dynamic>> getSubmissions() async {
    final url = Uri.parse('$_baseUrl/api/submissions/list/');
    final response = await http.get(url, headers: _headers());

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Gagal memuat data masuk dari server.');
    }
  }

  Future<Map<String, dynamic>> updateSubmissionStage({
    required int submissionId,
    required int stage,
    required Map<String, dynamic> pipelineData,
  }) async {
    final url = Uri.parse('$_baseUrl/api/submissions/$submissionId/stage/');
    final stageKey = 'stage_$stage';
    final stageData = pipelineData[stageKey] ?? {};
    
    final response = await http.post(
      url,
      headers: _headers(),
      body: jsonEncode({
        'stage_index': stage,
        'stage_data': stageData,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Gagal memperbarui progress tahap di server.');
    }
  }

  Future<Map<String, dynamic>> updateSubmissionDataType({
    required int submissionId,
    required String dataType,
  }) async {
    final url = Uri.parse('$_baseUrl/api/v2/submissions/$submissionId/');
    final response = await http.patch(
      url,
      headers: _headers(),
      body: jsonEncode({
        'detected_data_type': dataType,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 204) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Gagal memperbarui tipe data di server.');
    }
  }

  String _getStageCategory(int stage) {
    const stages = [
      'Planning', // Stage 0
      'Planning', // Stage 1
      'Development', // Stage 2
      'Development', // Stage 3
      'Testing', // Stage 4
      'Testing', // Stage 5
      'Maintenance', // Stage 6
      'Maintenance', // Stage 7
    ];
    if (stage >= 0 && stage < stages.length) {
      return stages[stage];
    }
    return 'Development';
  }
}
