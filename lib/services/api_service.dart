import 'package:http/http.dart' as http;
import 'dart:convert';

class ApiService {
  static const baseUrl = 'http://172.20.10.2:3000/api/energy';


  Future<List<dynamic>> fetchEnergyData(String type) async {
    final url = Uri.parse('$baseUrl/$type');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Erreur récupération données: ${response.statusCode}');
    }
  }
}
