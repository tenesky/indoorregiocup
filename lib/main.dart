import 'package:flutter/material.dart';
import 'screens/home_page.dart';
import 'screens/upload_page.dart';
import 'screens/scan_page.dart';
import 'screens/tickets_page.dart';
import 'screens/stats_page.dart';
import 'screens/gallery_page.dart';
import 'screens/login_page.dart';
import 'screens/settings_page.dart';

/// Haupteinstiegspunkt der Anwendung.
///
/// Beim Start wird IMMER zuerst die Login-Seite geladen.
/// Der Nutzer muss sich anmelden, bevor er in die App gelangt.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  /// Basis-URL für API-Aufrufe (falls noch benötigt).
  static const String baseUrl = 'https://indoor-regio-cup.de';

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'IRC Indoor Regio Cup',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      // App startet IMMER mit Login
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginPage(),
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
