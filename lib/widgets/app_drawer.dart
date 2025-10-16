import 'package:flutter/material.dart';

/// Gemeinsamer Drawer für die Navigation innerhalb der App.
///
/// Die Seiten sind über Routen abgebildet. Über diesen Drawer können
/// Anwender zwischen den Bereichen Startseite, Scanner, Ticketübersicht,
/// QR-Galerie, Statistiken und Einstellungen wechseln.
/// Der Header zeigt nur das Logo (assets/logo.png).
class AppDrawer extends StatelessWidget {
  /// Name der aktuell aktiven Route. Wird genutzt, um das passende
  /// ListTile hervorzuheben.
  final String currentRoute;

  const AppDrawer({Key? key, required this.currentRoute}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    /// Erstellt ein Navigationselement für den Drawer.
    ListTile _item(String title, String route) {
      return ListTile(
        title: Text(title),
        selected: currentRoute == route,
        onTap: () {
          Navigator.pop(context);
          if (currentRoute != route) {
            Navigator.pushReplacementNamed(context, route);
          }
        },
      );
    }

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(
              color: Colors.white, // weißer Hintergrund
            ),
            child: Center(
              child: Image.asset(
                'assets/logo.png',
                fit: BoxFit.contain,
              ),
            ),
          ),
          // Reihenfolge und Benennung der Menüpunkte
          _item('Startseite', '/'),
          _item('Scanner', '/scan'),
          _item('Ticketübersicht', '/tickets'),
          _item('QR-Codes', '/gallery'),
          _item('Statistiken', '/stats'),
          _item('Einstellungen', '/settings'),
        ],
      ),
    );
  }
}
