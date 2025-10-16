import 'package:flutter/material.dart';

/// Gemeinsamer Drawer für die Navigation innerhalb der App.
///
/// Die Seiten der Web‑Anwendung wurden in einzelne Routen abgebildet. Über
/// diesen Drawer können Anwender schnell zwischen den Bereichen
/// Startseite, CSV‑Upload, Scanner, Ticketübersicht, QR‑Galerie und
/// Statistiken wechseln. Die aktuelle Route wird hervorgehoben.
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
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(
              color: Colors.blue,
            ),
            child: const Text(
              'IRC Check‑In',
              style: TextStyle(color: Colors.white, fontSize: 24),
            ),
          ),
          // Die Reihenfolge und Benennung der Menüpunkte wurde zur besseren
          // Übersichtlichkeit angepasst.
          _item('Startseite', '/'),
          _item('Scanner', '/scan'),
          _item('Ticketübersicht', '/tickets'),
          _item('QR‑Codes', '/gallery'),
          _item('Statistiken', '/stats'),
          _item('Einstellungen', '/settings'),
        ],
      ),
    );
  }
}