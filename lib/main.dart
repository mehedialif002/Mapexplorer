
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';


////////////////////////////////////////////////////////////////////


void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'OpenStreetMap Demo with DMS Input',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const MapScreen(),
    );
  }
}

enum ScreenView { map, entityList, addEntity }

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});
  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  List<dynamic> _locations = [];
  bool _loading = true;
  ScreenView _currentView = ScreenView.map;

  final MapController _mapController = MapController();

  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _latController = TextEditingController();
  final _lonController = TextEditingController();
  final _imageController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchLocations();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _latController.dispose();
    _lonController.dispose();
    _imageController.dispose();
    super.dispose();
  }

  Future<void> fetchLocations() async {
    const url = 'https://labs.anontech.info/cse489/t3/api.php';
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _locations = data;
          _loading = false;
        });
      } else {
        throw Exception("Failed to load data");
      }
    } catch (e) {
      debugPrint("Error fetching locations: $e");
      setState(() => _loading = false);
    }
  }

  void _moveMapToLocation(LatLng point) {
    _mapController.move(point, 12);
  }

  /// Parse decimal or DMS coordinate string to decimal degrees double
  double? parseCoordinate(String input) {
    // Try decimal parse first
    final decimal = double.tryParse(input);
    if (decimal != null) return decimal;

    // Try DMS parse
    return dmsToDecimal(input);
  }

  /// Convert DMS string (e.g. 22° 32' 41.64" N) to decimal degrees
  double? dmsToDecimal(String dms) {
    final regex = RegExp(
        r"""(\d+)[°\s]+(\d+)[\'\s]+([\d.]+)"?\s*([NSEW])""",
        caseSensitive: false);
    final match = regex.firstMatch(dms.trim());

    if (match == null) return null;

    final degrees = double.tryParse(match.group(1) ?? '') ?? 0;
    final minutes = double.tryParse(match.group(2) ?? '') ?? 0;
    final seconds = double.tryParse(match.group(3) ?? '') ?? 0;
    final direction = (match.group(4) ?? '').toUpperCase();

    double decimal = degrees + (minutes / 60) + (seconds / 3600);

    if (direction == 'S' || direction == 'W') {
      decimal = -decimal;
    }

    return decimal;
  }

  String? validateCoordinate(String? value) {
    if (value == null || value.trim().isEmpty) {
      return "Enter coordinate";
    }
    if (parseCoordinate(value.trim()) == null) {
      return "Enter valid decimal or DMS (e.g. 22° 32' 41.64\" N)";
    }
    return null;
  }

  void _addEntity() {
    if (_formKey.currentState!.validate()) {
      final title = _titleController.text.trim();

      final latInput = _latController.text.trim();
      final lonInput = _lonController.text.trim();

      final lat = parseCoordinate(latInput);
      final lon = parseCoordinate(lonInput);

      if (lat == null || lon == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid latitude or longitude format')),
        );
        return;
      }

      final image = _imageController.text.trim().isEmpty
          ? null
          : _imageController.text.trim();

      setState(() {
        _locations.add({
          "title": title,
          "lat": lat.toString(),
          "lon": lon.toString(),
          "image": image,
        });
        _currentView = ScreenView.map;
      });

      _titleController.clear();
      _latController.clear();
      _lonController.clear();
      _imageController.clear();

      _moveMapToLocation(LatLng(lat, lon));

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Entity "$title" added!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("OpenStreetMap Demo")),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.blue),
              child: Center(
                child: Text(
                  "Menu",
                  style: TextStyle(color: Colors.white, fontSize: 24),
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.map),
              title: const Text("Map"),
              selected: _currentView == ScreenView.map,
              onTap: () {
                Navigator.pop(context);
                setState(() => _currentView = ScreenView.map);
              },
            ),
            ListTile(
              leading: const Icon(Icons.list),
              title: const Text("Entity List"),
              selected: _currentView == ScreenView.entityList,
              onTap: () {
                Navigator.pop(context);
                setState(() => _currentView = ScreenView.entityList);
              },
            ),
            ListTile(
              leading: const Icon(Icons.add),
              title: const Text("Add Entity"),
              selected: _currentView == ScreenView.addEntity,
              onTap: () {
                Navigator.pop(context);
                setState(() => _currentView = ScreenView.addEntity);
              },
            ),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _buildBody(),
    );
  }

  Widget _buildBody() {
    switch (_currentView) {
      case ScreenView.map:
        return _buildMap();
      case ScreenView.entityList:
        return _buildEntityList();
      case ScreenView.addEntity:
        return _buildAddEntityForm();
    }
  }

  Widget _buildMap() {
    final centerPoint = LatLng(23.6850, 90.3563);

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: centerPoint,
        initialZoom: 6,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.example.app',
        ),
        MarkerLayer(
          markers: _locations.map((loc) {
            final lat = double.tryParse(loc['lat'].toString()) ?? 0.0;
            final lon = double.tryParse(loc['lon'].toString()) ?? 0.0;
            if (lat == 0.0 && lon == 0.0) return null;

            return Marker(
              width: 40,
              height: 40,
              point: LatLng(lat, lon),
              child: GestureDetector(
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: Text(loc['title'] ?? "No title"),
                      content: loc['image'] != null
                          ? Image.network(
                        loc['image'],
                        height: 150,
                        fit: BoxFit.cover,
                      )
                          : const Text("No image available"),
                      actions: [
                        TextButton(
                          child: const Text("Close"),
                          onPressed: () => Navigator.pop(context),
                        )
                      ],
                    ),
                  );
                },
                child: const Icon(
                  Icons.location_pin,
                  color: Colors.red,
                  size: 40,
                ),
              ),
            );
          }).where((m) => m != null).cast<Marker>().toList(),
        ),
      ],
    );
  }
/*
  Widget _buildEntityList() {
    return ListView.builder(
      itemCount: _locations.length,
      itemBuilder: (context, index) {
        final loc = _locations[index];
        return ListTile(
          title: Text(loc['title'] ?? "No Title"),
          subtitle: Text("Lat: ${loc['lat']}, Lon: ${loc['lon']}"),
          leading: loc['image'] != null
              ? Image.network(
            loc['image'],
            width: 40,
            height: 40,
            fit: BoxFit.cover,
          )
              : const Icon(Icons.location_on),
          trailing: IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: () {
              showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text("Confirm Delete"),
                  content: Text('Delete "${loc['title']}"?'),
                  actions: [
                    TextButton(
                      child: const Text("Cancel"),
                      onPressed: () => Navigator.pop(context),
                    ),
                    TextButton(
                      child: const Text("Delete", style: TextStyle(color: Colors.red)),
                      onPressed: () {
                        setState(() {
                          _locations.removeAt(index);
                        });
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Deleted "${loc['title']}"')),
                        );
                      },
                    ),
                  ],
                ),
              );
            },
          ),
          onTap: () {
            final lat = double.tryParse(loc['lat'].toString()) ?? 0.0;
            final lon = double.tryParse(loc['lon'].toString()) ?? 0.0;
            if (lat != 0.0 && lon != 0.0) {
              setState(() {
                _currentView = ScreenView.map;
                _moveMapToLocation(LatLng(lat, lon));
              });
            }
          },
        );
      },
    );
  }
*/
  //////////////////////////////////////////////////////////////////////
  Widget _buildEntityList() {
    return ListView.builder(
      itemCount: _locations.length,
      itemBuilder: (context, index) {
        final loc = _locations[index];
        return ListTile(
          title: Text(loc['title'] ?? "No Title"),
          subtitle: Text("Lat: ${loc['lat']}, Lon: ${loc['lon']}"),
          leading: loc['image'] != null
              ? Image.network(
            loc['image'],
            width: 40,
            height: 40,
            fit: BoxFit.cover,
          )
              : const Icon(Icons.location_on),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.edit, color: Colors.blue),
                onPressed: () {
                  _showUpdateEntityDialog(index, loc);
                },
              ),
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text("Confirm Delete"),
                      content: Text('Delete "${loc['title']}"?'),
                      actions: [
                        TextButton(
                          child: const Text("Cancel"),
                          onPressed: () => Navigator.pop(context),
                        ),
                        TextButton(
                          child: const Text("Delete", style: TextStyle(color: Colors.red)),
                          onPressed: () {
                            setState(() {
                              _locations.removeAt(index);
                            });
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Deleted "${loc['title']}"')),
                            );
                          },
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
          onTap: () {
            final lat = double.tryParse(loc['lat'].toString()) ?? 0.0;
            final lon = double.tryParse(loc['lon'].toString()) ?? 0.0;
            if (lat != 0.0 && lon != 0.0) {
              setState(() {
                _currentView = ScreenView.map;
                _moveMapToLocation(LatLng(lat, lon));
              });
            }
          },
        );
      },
    );
  }
  void _showUpdateEntityDialog(int index, Map<String, dynamic> loc) {
    final titleController = TextEditingController(text: loc['title']);
    final latController = TextEditingController(text: loc['lat'].toString());
    final lonController = TextEditingController(text: loc['lon'].toString());
    final imageController = TextEditingController(text: loc['image'] ?? '');

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Update Entity"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: "Title"),
              ),
              TextField(
                controller: latController,
                decoration: const InputDecoration(labelText: "Latitude"),
              ),
              TextField(
                controller: lonController,
                decoration: const InputDecoration(labelText: "Longitude"),
              ),
              TextField(
                controller: imageController,
                decoration: const InputDecoration(labelText: "Image URL (optional)"),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            child: const Text("Cancel"),
            onPressed: () => Navigator.pop(context),
          ),
          TextButton(
            child: const Text("Save"),
            onPressed: () {
              final lat = parseCoordinate(latController.text.trim());
              final lon = parseCoordinate(lonController.text.trim());

              if (lat == null || lon == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Invalid coordinates")),
                );
                return;
              }

              setState(() {
                _locations[index] = {
                  "title": titleController.text.trim(),
                  "lat": lat.toString(),
                  "lon": lon.toString(),
                  "image": imageController.text.trim().isEmpty
                      ? null
                      : imageController.text.trim(),
                };
                _currentView = ScreenView.map;
              });

              _moveMapToLocation(LatLng(lat, lon));
              Navigator.pop(context);

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Entity updated!")),
              );
            },
          ),
        ],
      ),
    );
  }

  //////////////////////////////////////////////////////////////////////
  Widget _buildAddEntityForm() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: ListView(
          children: [
            const Text(
              "Add New Entity",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: "Title",
                border: OutlineInputBorder(),
              ),
              validator: (value) =>
              (value == null || value.trim().isEmpty) ? "Enter title" : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _latController,
              decoration: const InputDecoration(
                labelText: "Latitude (decimal or DMS, e.g. 22° 32' 41.64\" N)",
                border: OutlineInputBorder(),
              ),
              validator: validateCoordinate,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _lonController,
              decoration: const InputDecoration(
                labelText: "Longitude (decimal or DMS, e.g. 90° 20' 30\" E)",
                border: OutlineInputBorder(),
              ),
              validator: validateCoordinate,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _imageController,
              decoration: const InputDecoration(
                labelText: "Image URL (optional)",
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.url,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _addEntity,
              child: const Text("Add Entity"),
            ),
          ],
        ),
      ),
    );
  }
}




