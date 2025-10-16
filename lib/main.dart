import 'package:flutter/material.dart';
import 'screens/home_page.dart';
import 'screens/upload_page.dart';
import 'screens/scan_page.dart';
import 'screens/tickets_page.dart';
import 'screens/stats_page.dart';
import 'screens/gallery_page.dart';
import 'screens/login_page.dart';
import 'screens/settings_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Haupteinstiegspunkt der Anwendung.
///
/// Hier wird das [MaterialApp] konfiguriert und die Routen für die
/// verschiedenen Seiten registriert. Die Konstante [baseUrl] definiert die
/// Basis‑URL des Backends. Soll die App mit einem anderen Server
/// verwendet werden, kann dieser Wert angepasst werden.
/// Einstiegspunkt der Anwendung.
///
/// Bevor die App gestartet wird, werden die SharedPreferences geladen, um zu
/// prüfen, ob der Nutzer bereits eingeloggt ist. So kann entschieden werden,
/// ob die Login‑Seite oder direkt die Startseite angezeigt werden soll.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
  runApp(MyApp(isLoggedIn: isLoggedIn));
}

class MyApp extends StatelessWidget {
  /// Gibt an, ob der Nutzer bereits eingeloggt ist. Wird beim Start in main()
  /// aus den SharedPreferences gelesen.
  final bool isLoggedIn;

  const MyApp({Key? key, required this.isLoggedIn}) : super(key: key);

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
      // Zeige je nach Login‑Status die passende Startseite
      initialRoute: isLoggedIn ? '/' : '/login',
      routes: {
        '/login': (context) => const LoginPage(baseUrl: baseUrl),
        '/': (context) => const HomePage(baseUrl: baseUrl),
        '/upload': (context) => const UploadPage(baseUrl: baseUrl),
        '/scan': (context) => const ScanPage(baseUrl: baseUrl),
        '/tickets': (context) => const TicketsPage(baseUrl: baseUrl),
        '/stats': (context) => const StatsPage(baseUrl: baseUrl),
        '/gallery': (context) => const GalleryPage(baseUrl: baseUrl),
        '/settings': (context) => const SettingsPage(baseUrl: baseUrl),
      },
    );
  }
}