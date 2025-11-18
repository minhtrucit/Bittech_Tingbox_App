import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ProductApiService {
  final String baseUrl;

  ProductApiService({required this.baseUrl});

  /// Gửi ảnh lên Python API và nhận JSON product
  Future<Map<String, dynamic>?> sendImage(String imagePath) async {
    final uri = Uri.parse('$baseUrl/match');
    final request = http.MultipartRequest('POST', uri);

    request.files.add(await http.MultipartFile.fromPath('image', imagePath));

    try {
      final response = await request.send();

      if (response.statusCode == 200) {
        final respStr = await response.stream.bytesToString();
        final data = json.decode(respStr);
        return data; // JSON product
      } else {
        print('API Error: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error sending image: $e');
      return null;
    }
  }
}
