import 'package:flutter/material.dart';
import '../widgets/app_drawer.dart';

/// Startseite der IRC Check‑In App.
///
/// Diese Seite gibt einen kurzen Überblick über die Funktionen der
/// Anwendung. Nutzer können von hier aus schnell zu den wichtigsten
/// Bereichen navigieren, beispielsweise zum Scanner oder zum Upload.
class HomePage extends StatelessWidget {
  final String baseUrl;
  const HomePage({Key? key, required this.baseUrl}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('IRC Indoor Regio Cup – Startseite'),
      ),
      drawer: AppDrawer(currentRoute: '/'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            Text(
              'Willkommen zum IRC Indoor Regio Cup 2025!',
              style: Theme.of(context).textTheme.headline5,
            ),
            const SizedBox(height: 12),
            Text(
              'Diese App unterstützt dich beim Check‑In der Veranstaltung.\n\n'
              '- Lade eine Gästeliste als CSV‑Datei hoch.\n'
              '- Scanne Tickets am Eingang mit dem integrierten QR‑Scanner.\n'
              '- Verschaffe dir einen Überblick über alle Tickets und deren Scan‑Status.\n'
              '- Versende QR‑Codes per E‑Mail oder setze den Scan‑Status zurück.\n'
              '- Sieh dir aktuelle Statistiken an und behalte den Überblick über die letzten Scans.\n'
              '- Durchstöbere die Galerie der bereits generierten QR‑Codes.\n\n'
              'Nutze das Menü oben links, um zu den einzelnen Funktionen zu gelangen.',
              style: Theme.of(context).textTheme.bodyText2,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/scan');
                    },
                    child: const Text('Scanner öffnen'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/upload');
                    },
                    child: const Text('CSV hochladen'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}