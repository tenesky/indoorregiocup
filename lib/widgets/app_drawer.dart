import 'package:flutter/material.dart';

/// Gemeinsamer Drawer für die Navigation innerhalb der App.
///
/// Enthält die Menüpunkte Startseite, Scanner, Ticketübersicht, QR-Codes,
/// Statistiken und Einstellungen. Der Header zeigt jetzt das App-Logo
/// aus `assets/logo.png` statt nur Text an.
class AppDrawer extends StatelessWidget {
  final String currentRoute;

  const AppDrawer({Key? key, required this.currentRoute}) : super(key: key);

  @override
  Widget build(BuildContext context) {
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
            decoration: const BoxDecoration(color: Colors.blue),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: Image.asset(
                    'assets/logo.png',
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Indoor Regio Cup',
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
              ],
            ),
          ),
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
