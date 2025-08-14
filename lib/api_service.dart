
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'entity.dart';

class ApiService {
  static const String baseUrl = 'https://labs.anontech.info/cse489/t3/api.php';

  // -------------------- GET --------------------
  static Future<List<Entity>> fetchAll() async {
    final res = await http.get(Uri.parse(baseUrl));
    if (res.statusCode != 200) throw Exception('GET failed: ${res.statusCode}');
    final data = jsonDecode(res.body) as List;
    return data.map((e) => Entity.fromJson(e)).toList();
  }

  // -------------------- POST --------------------
  static Future<Entity> create({
    required String title,
    required double lat,
    required double lon,
    File? imageFile,
    String? imageUrl,
  }) async {
    if (imageFile != null) {
      final m = http.MultipartRequest('POST', Uri.parse(baseUrl));
      m.fields['title'] = title;
      m.fields['lat'] = lat.toString();
      m.fields['lon'] = lon.toString();
      m.files.add(await http.MultipartFile.fromPath(
        'image',
        imageFile.path,
        contentType: MediaType('image', _ext(imageFile.path)),
      ));
      final streamed = await m.send();
      final res = await http.Response.fromStream(streamed);
      if (res.statusCode != 200) throw Exception('POST failed: ${res.body}');
      final j = jsonDecode(res.body);
      return Entity(
        id: int.tryParse(j['id'].toString()) ?? 0,
        title: title,
        lat: lat,
        lon: lon,
        image: j['image']?.toString(),
      );
    }

    final res = await http.post(Uri.parse(baseUrl), body: {
      'title': title,
      'lat': lat.toString(),
      'lon': lon.toString(),
      if (imageUrl != null) 'image': imageUrl,
    });
    if (res.statusCode != 200) throw Exception('POST failed: ${res.body}');
    final j = jsonDecode(res.body);
    return Entity(
      id: int.tryParse(j['id'].toString()) ?? 0,
      title: title,
      lat: lat,
      lon: lon,
      image: j['image']?.toString(),
    );
  }

  // -------------------- PUT --------------------
  static Future<void> update({
    required int id,
    required String title,
    required double lat,
    required double lon,
    File? imageFile,
    String? imageUrl,
  }) async {
    if (imageFile == null && (imageUrl == null || imageUrl.isEmpty)) {
      // Text-only update
      final res = await http.put(
        Uri.parse(baseUrl),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'id': id.toString(),
          'title': title,
          'lat': lat.toString(),
          'lon': lon.toString(),
        },
      );
      if (res.statusCode != 200) {
        throw Exception('PUT failed: ${res.body}');
      }
      return;
    }

    // Update with image using POST + _method=PUT
    final m = http.MultipartRequest('POST', Uri.parse(baseUrl));
    m.fields['id'] = id.toString();
    m.fields['title'] = title;
    m.fields['lat'] = lat.toString();
    m.fields['lon'] = lon.toString();
    m.fields['_method'] = 'PUT'; // Let backend know this is a PUT operation

    if (imageFile != null) {
      m.files.add(await http.MultipartFile.fromPath(
        'image',
        imageFile.path,
        contentType: MediaType('image', _ext(imageFile.path)),
      ));
    } else if (imageUrl != null && imageUrl.isNotEmpty) {
      m.fields['image'] = imageUrl;
    }

    final streamed = await m.send();
    final res = await http.Response.fromStream(streamed);
    if (res.statusCode != 200) {
      throw Exception('PUT failed: ${res.body}');
    }
  }

  // -------------------- DELETE --------------------
  static Future<void> deleteById(int id) async {
    final req = http.Request('DELETE', Uri.parse(baseUrl))
      ..bodyFields = {'id': id.toString()};
    final streamed = await req.send();
    final res = await http.Response.fromStream(streamed);
    if (res.statusCode != 200) throw Exception('DELETE failed: ${res.body}');
  }
}

String _ext(String path) {
  final e = path.split('.').last.toLowerCase();
  switch (e) {
    case 'jpg':
    case 'jpeg':
      return 'jpeg';
    case 'png':
      return 'png';
    default:
      return 'jpeg';
  }
}
