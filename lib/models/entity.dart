class Entity {
  final String title;
  final double latitude;
  final double longitude;
  final String? imageUrl;

  Entity({
    required this.title,
    required this.latitude,
    required this.longitude,
    this.imageUrl,
  });

  factory Entity.fromJson(Map<String, dynamic> json) {
    return Entity(
      title: json['title'],
      latitude: double.parse(json['latitude'].toString()),
      longitude: double.parse(json['longitude'].toString()),
      imageUrl: json['image'],
    );
  }
}
