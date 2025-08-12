import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/entity.dart';

class ApiService {
  static const String baseUrl = 'https://labs.anontech.info/cse489/t3/api.php';

  static Future<List<Entity>> fetchEntities() async {
    final response = await http.get(Uri.parse('$baseUrl?action=list'));
    if (response.statusCode == 200) {
      List data = jsonDecode(response.body);
      return data.map((e) => Entity.fromJson(e)).toList();
    } else {
      throw Exception('Failed to load entities');
    }
  }

  static Future<bool> addEntity(Entity entity) async {
    final response = await http.post(
      Uri.parse('$baseUrl?action=add'),
      body: {
        'title': entity.title,
        'latitude': entity.latitude.toString(),
        'longitude': entity.longitude.toString(),
        'image': entity.imageUrl ?? '',
      },
    );
    return response.statusCode == 200;
  }
}
