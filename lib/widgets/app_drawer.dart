import 'package:flutter/material.dart';

class AppDrawer extends StatelessWidget {
  final String currentRoute;
  const AppDrawer({super.key, required this.currentRoute});

  @override
  Widget build(BuildContext context) {
    Widget _buildTile(String title, IconData icon, String routeName) {
      return ListTile(
        leading: Icon(icon),
        title: Text(title),
        selected: currentRoute == routeName,
        onTap: () {
          if (currentRoute != routeName) {
            Navigator.pushReplacementNamed(context, routeName);
          } else {
            Navigator.pop(context);
          }
        },
      );
    }

    return Drawer(
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
          _buildTile("Map", Icons.map, '/'),
          _buildTile("Entity List", Icons.list, '/entity-list'),
          _buildTile("Add Entity", Icons.add, '/add-entity'),
        ],
      ),
    );
  }
}
