
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'entity.dart';
import 'api_service.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'OpenStreetMap CRUD',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const MapScreen(),
    );
  }
}

enum ScreenView { map, list, add }

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});
  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  List<Entity> _locations = [];
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

  Future<void> fetchLocations() async {
    setState(() => _loading = true);
    try {
      final data = await ApiService.fetchAll();
      setState(() {
        _locations = data;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Load failed: $e')),
      );
    }
  }

  double? parseCoordinate(String input) {
    final decimal = double.tryParse(input);
    if (decimal != null) return decimal;
    return dmsToDecimal(input);
  }

  double? dmsToDecimal(String dms) {
    final regex = RegExp(r"""(\d+)[°\s]+(\d+)[\'\s]+([\d.]+)"?\s*([NSEW])""");
    final match = regex.firstMatch(dms.trim());
    if (match == null) return null;
    double deg = double.parse(match.group(1)!);
    double min = double.parse(match.group(2)!);
    double sec = double.parse(match.group(3)!);
    String dir = match.group(4)!.toUpperCase();
    double dec = deg + (min / 60) + (sec / 3600);
    if (dir == 'S' || dir == 'W') dec = -dec;
    return dec;
  }

  String? validateCoordinate(String? value) {
    if (value == null || value.isEmpty) return "Enter coordinate";
    if (parseCoordinate(value) == null) return "Invalid coordinate";
    return null;
  }

  void _moveMap(LatLng p) => _mapController.move(p, 12);

  Future<void> _addEntity() async {
    if (!_formKey.currentState!.validate()) return;
    final title = _titleController.text.trim();
    final lat = parseCoordinate(_latController.text.trim())!;
    final lon = parseCoordinate(_lonController.text.trim())!;
    final imageUrl = _imageController.text.trim().isEmpty
        ? null
        : _imageController.text.trim();

    try {
      final created = await ApiService.create(
        title: title,
        lat: lat,
        lon: lon,
        imageFile: null,
        imageUrl: imageUrl,
      );
      setState(() {
        _locations.add(created);
        _currentView = ScreenView.map;
      });
      _titleController.clear();
      _latController.clear();
      _lonController.clear();
      _imageController.clear();

      _moveMap(LatLng(lat, lon)); // Center map on new marker

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Entity "$title" added')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Create failed: $e')),
      );
    }
  }

  Future<void> _deleteEntity(int index) async {
    try {
      await ApiService.deleteById(_locations[index].id);
      setState(() => _locations.removeAt(index));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Delete failed: $e')),
      );
    }
  }

  Future<void> _updateEntity(int index, Entity e) async {
    try {
      await ApiService.update(
        id: e.id,
        title: e.title,
        lat: e.lat,
        lon: e.lon,
        imageFile: null,
        imageUrl: e.image,
      );
      setState(() => _locations[index] = e);
    } catch (err) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Update failed: $err')),
      );
    }
  }

  void _showUpdateDialog(int index) {
    final t = TextEditingController(text: _locations[index].title);
    final la = TextEditingController(text: _locations[index].lat.toString());
    final lo = TextEditingController(text: _locations[index].lon.toString());
    final im = TextEditingController(text: _locations[index].image ?? '');
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Update Entity"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: t, decoration: const InputDecoration(labelText: "Title")),
            TextField(controller: la, decoration: const InputDecoration(labelText: "Latitude")),
            TextField(controller: lo, decoration: const InputDecoration(labelText: "Longitude")),
            TextField(controller: im, decoration: const InputDecoration(labelText: "Image URL")),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          TextButton(
            onPressed: () {
              final lat = parseCoordinate(la.text.trim()) ?? 0;
              final lon = parseCoordinate(lo.text.trim()) ?? 0;
              final entity = Entity(
                id: _locations[index].id,
                title: t.text.trim(),
                lat: lat,
                lon: lon,
                image: im.text.trim().isEmpty ? null : im.text.trim(),
              );
              _updateEntity(index, entity);
              Navigator.pop(context);
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }






  Widget _buildMap() {
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: LatLng(23.6850, 90.3563),
        initialZoom: 6,
        onTap: (tapPosition, point) {
          // Pre-fill lat/lon when user taps map
          _latController.text = point.latitude.toStringAsFixed(6);
          _lonController.text = point.longitude.toStringAsFixed(6);
          _titleController.clear();
          _imageController.clear();
          setState(() {
            _currentView = ScreenView.add;
          });
        },
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.example.app',
        ),
        MarkerLayer(
          markers: _locations.map((loc) {
            return Marker(
              point: LatLng(loc.lat, loc.lon),
              width: 40,
              height: 40,
              child: GestureDetector(
                onTap: () => showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: Text(loc.title),
                    content: loc.image != null
                        ? Image.network(loc.image!)
                        : const Text("No image"),
                  ),
                ),
                child: const Icon(Icons.location_pin, color: Colors.red, size: 40),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildList() {
    return ListView.builder(
      itemCount: _locations.length,
      itemBuilder: (context, i) {
        final loc = _locations[i];
        return ListTile(
          title: Text(loc.title),
          subtitle: Text("Lat: ${loc.lat}, Lon: ${loc.lon}"),
          leading: loc.image != null
              ? Image.network(loc.image!, width: 40, height: 40, fit: BoxFit.cover)
              : const Icon(Icons.location_on),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(icon: const Icon(Icons.edit), onPressed: () => _showUpdateDialog(i)),
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () => _deleteEntity(i),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAddForm() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: ListView(
          children: [
            TextFormField(
              autofocus: true,
              controller: _titleController,
              decoration: const InputDecoration(labelText: "Title"),
              validator: (v) => v!.isEmpty ? "Required" : null,
            ),
            const SizedBox(height: 8),
            TextFormField(controller: _latController, decoration: const InputDecoration(labelText: "Latitude"), validator: validateCoordinate),
            const SizedBox(height: 8),
            TextFormField(controller: _lonController, decoration: const InputDecoration(labelText: "Longitude"), validator: validateCoordinate),
            const SizedBox(height: 8),
            TextFormField(controller: _imageController, decoration: const InputDecoration(labelText: "Image URL")),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _addEntity, child: const Text("Add Entity")),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {


    return Scaffold(


      appBar: AppBar(title: const Text("BANGLADESH centered MAP")),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.blue),
              child: Center(child: Text("Menu", style: TextStyle(color: Colors.white, fontSize: 24))),
            ),
            ListTile(title: const Text("Map"), onTap: () => setState(() => _currentView = ScreenView.map)),
            ListTile(title: const Text("Entity List"), onTap: () => setState(() => _currentView = ScreenView.list)),
            ListTile(title: const Text("Add Entity"), onTap: () => setState(() => _currentView = ScreenView.add)),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _currentView == ScreenView.map
          ? _buildMap()
          : _currentView == ScreenView.list
          ? _buildList()
          : _buildAddForm(),
    );
  }
}
