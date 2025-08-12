import 'package:flutter/material.dart';
import '../models/entity.dart';
import '../services/api_service.dart';

class EntityListPage extends StatefulWidget {
  const EntityListPage({super.key});

  @override
  State<EntityListPage> createState() => _EntityListPageState();
}

class _EntityListPageState extends State<EntityListPage> {
  late Future<List<Entity>> _entities;

  @override
  void initState() {
    super.initState();
    _entities = ApiService.fetchEntities();
  }

  void _refreshList() {
    setState(() {
      _entities = ApiService.fetchEntities();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Entities")),
      body: FutureBuilder<List<Entity>>(
        future: _entities,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("No entities found"));
          }
          final entities = snapshot.data!;
          return ListView.builder(
            itemCount: entities.length,
            itemBuilder: (context, index) {
              final e = entities[index];
              return ListTile(
                title: Text(e.title),
                subtitle: Text("${e.latitude}, ${e.longitude}"),
                trailing: IconButton(
                  icon: const Icon(Icons.map),
                  onPressed: () {
                    Navigator.pushNamed(context, '/map', arguments: e);
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final added = await Navigator.pushNamed(context, '/add');
          if (added == true) _refreshList();
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
