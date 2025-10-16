import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../widgets/app_drawer.dart';

/// Seite für die Einstellungen der App.
///
/// Ermöglicht es, das aktuell gespeicherte Passwort einzusehen und ein
/// neues Passwort in der Datenbank zu speichern. Der Austausch mit dem
/// Server erfolgt über die PHP‑Skripte `get_app_password.php` und
/// `update_app_password.php`.
class SettingsPage extends StatefulWidget {
  final String baseUrl;
  const SettingsPage({Key? key, required this.baseUrl}) : super(key: key);

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String? _currentPassword;
  final TextEditingController _newPasswordController = TextEditingController();
  bool _loading = true;
  String? _message;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadCurrentPassword();
  }

  Future<void> _loadCurrentPassword() async {
    try {
      final response = await http.get(
        Uri.parse('${widget.baseUrl}/php/get_app_password.php'),
      );
      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
        setState(() {
          _currentPassword = jsonResponse['password'] as String?;
          _loading = false;
        });
      } else {
        setState(() {
          _error = 'Fehler beim Laden des Passworts.';
          _loading = false;
        });
      }
    } catch (_) {
      setState(() {
        _error = 'Fehler beim Laden des Passworts.';
        _loading = false;
      });
    }
  }

  Future<void> _updatePassword() async {
    setState(() {
      _message = null;
      _error = null;
    });
    final newPassword = _newPasswordController.text;
    if (newPassword.isEmpty) {
      setState(() {
        _error = 'Bitte gib ein neues Passwort ein.';
      });
      return;
    }
    try {
      final response = await http.post(
        Uri.parse('${widget.baseUrl}/php/update_app_password.php'),
        body: {'password': newPassword},
      );
      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
        final bool success = jsonResponse['success'] == true;
        setState(() {
          if (success) {
            _message = 'Passwort erfolgreich aktualisiert.';
            _currentPassword = newPassword;
            _newPasswordController.clear();
          } else {
            _error = jsonResponse['message'] ?? 'Fehler beim Aktualisieren des Passworts.';
          }
        });
      } else {
        setState(() {
          _error = 'Fehler beim Aktualisieren des Passworts.';
        });
      }
    } catch (_) {
      setState(() {
        _error = 'Fehler beim Aktualisieren des Passworts.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Einstellungen'),
      ),
      drawer: AppDrawer(currentRoute: '/settings'),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Aktuelles Passwort:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  SelectableText(
                    _currentPassword ?? '—',
                    style: const TextStyle(fontSize: 16),
                  ),
                  const Divider(height: 32),
                  TextField(
                    controller: _newPasswordController,
                    decoration: const InputDecoration(
                      labelText: 'Neues Passwort',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _updatePassword,
                      child: const Text('Passwort aktualisieren'),
                    ),
                  ),
                  if (_message != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      _message!,
                      style: const TextStyle(color: Colors.green),
                    ),
                  ],
                  if (_error != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      _error!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ],
                ],
              ),
            ),
    );
  }
}