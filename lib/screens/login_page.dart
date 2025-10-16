import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/database_service.dart';

/// Login‑Seite für das App‑Passwort.
///
/// Diese Seite wird angezeigt, wenn der Benutzer die App startet und noch
/// kein gültiges Passwort eingegeben hat. Das Passwort wird aus der
/// Datenbank geladen (über die Backend‑API) und lokal überprüft. Bei
/// erfolgreicher Eingabe wird ein Flag in den SharedPreferences gesetzt und
/// zur Startseite navigiert.
class LoginPage extends StatefulWidget {
  final String baseUrl;
  const LoginPage({Key? key, required this.baseUrl}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _passwordController = TextEditingController();
  bool _loading = false;
  String? _error;

  /// Lädt das aktuell in der Datenbank gespeicherte Passwort.
  Future<String?> _getStoredPassword() async {
    try {
      // Direkt aus der MySQL‑Datenbank über den DatabaseService laden.
      return await DatabaseService.fetchAppPassword();
    } catch (_) {
      // Fehler ignorieren – null zurückgeben
      return null;
    }
  }

  Future<void> _login() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final entered = _passwordController.text;
    final storedPassword = await _getStoredPassword();
    if (storedPassword != null && entered == storedPassword) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', true);
      // Navigiere zur Startseite und entferne die Loginseite vom Stack
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/');
    } else {
      setState(() {
        _error = 'Falsches Passwort.';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('App‑Passwort'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Bitte gib das App‑Passwort ein, um fortzufahren.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Passwort',
                border: OutlineInputBorder(),
              ),
              onSubmitted: (_) => _login(),
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(
                _error!,
                style: const TextStyle(color: Colors.red),
              ),
            ],
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _login,
                child: _loading
                    ? const SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text('Einloggen'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}