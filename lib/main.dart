import 'package:flutter/material.dart';
import 'screens/home_page.dart';
import 'screens/upload_page.dart';
import 'screens/scan_page.dart';
import 'screens/tickets_page.dart';
import 'screens/stats_page.dart';
import 'screens/gallery_page.dart';

/// Haupteinstiegspunkt der Anwendung.
///
/// Hier wird das [MaterialApp] konfiguriert und die Routen für die
/// verschiedenen Seiten registriert. Die Konstante [baseUrl] definiert die
/// Basis‑URL des Backends. Soll die App mit einem anderen Server
/// verwendet werden, kann dieser Wert angepasst werden.
void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  /// Basis‑URL für alle API‑Aufrufe.
  ///
  /// Standardmäßig wird die Domain „https://indoor-regio-cup.de“ genutzt. Bei
  /// einer lokalen Testumgebung kann dieser Wert entsprechend angepasst
  /// werden (z.B. `http://localhost/indoor_regio_site`).
  static const String baseUrl = 'https://indoor-regio-cup.de';

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'IRC Indoor Regio Cup',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const HomePage(baseUrl: baseUrl),
        '/upload': (context) => const UploadPage(baseUrl: baseUrl),
        '/scan': (context) => const ScanPage(baseUrl: baseUrl),
        '/tickets': (context) => const TicketsPage(baseUrl: baseUrl),
        '/stats': (context) => const StatsPage(baseUrl: baseUrl),
        '/gallery': (context) => const GalleryPage(baseUrl: baseUrl),
      },
    );
  }
}