import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = "https://misinfocheckapp-production.up.railway.app";


  /// Health check → returns JSON
  static Future<Map<String, dynamic>> healthCheck() async {
    final url = Uri.parse("$baseUrl/health");
    final response = await http.get(url);

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception(
        "Health check failed → ${response.statusCode}: ${response.body}",
      );
    }
  }

  /// Categorize text → returns JSON
  static Future<Map<String, dynamic>> categorizeText(String text) async {
    final url = Uri.parse("$baseUrl/categorize");
    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"text": text}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception(
        "Categorize failed → ${response.statusCode}: ${response.body}",
      );
    }
  }

  /// Upload file → returns JSON
  static Future<Map<String, dynamic>> uploadFile(String filePath) async {
    final url = Uri.parse("$baseUrl/upload");
    var request = http.MultipartRequest('POST', url);

    request.files.add(await http.MultipartFile.fromPath('file', filePath));

    final response = await request.send();
    final body = await response.stream.bytesToString();

    if (response.statusCode == 200) {
      return jsonDecode(body) as Map<String, dynamic>;
    } else {
      throw Exception("File upload failed → ${response.statusCode}: $body");
    }
  }
}
