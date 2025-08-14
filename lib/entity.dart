
class Entity {
  final int id;
  final String title;
  final double lat;
  final double lon;
  final String? image;

  Entity({
    required this.id,
    required this.title,
    required this.lat,
    required this.lon,
    this.image,
  });

  factory Entity.fromJson(Map<String, dynamic> j) => Entity(
    id: int.tryParse(j['id'].toString()) ?? 0,
    title: j['title']?.toString() ?? '',
    lat: double.tryParse(j['lat'].toString()) ?? 0,
    lon: double.tryParse(j['lon'].toString()) ?? 0,
    image: (j['image'] == null || j['image'].toString().isEmpty)
        ? null
        : 'https://labs.anontech.info/cse489/t3/${j['image']}',
  );


  Map<String, String> toForm() => {
    'id': id.toString(),
    'title': title,
    'lat': lat.toString(),
    'lon': lon.toString(),
  };
}
