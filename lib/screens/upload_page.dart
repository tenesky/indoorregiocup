import 'dart:io';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import '../widgets/app_drawer.dart';

/// Seite zum Importieren von Gästelisten im CSV‑Format.
///
/// Der Nutzer wählt eine CSV‑Datei von seinem Gerät aus. Anschließend
/// wird die Datei per Multipart‑Upload an die Server‑Schnittstelle
/// `php/upload.php` gesendet. Das Backend importiert die Datensätze
/// in die Datenbank und antwortet mit einer Weiterleitung. In der App
/// wird nach Abschluss des Uploads eine Erfolgsmeldung angezeigt.
class UploadPage extends StatefulWidget {
  final String baseUrl;
  const UploadPage({Key? key, required this.baseUrl}) : super(key: key);

  @override
  State<UploadPage> createState() => _UploadPageState();
}

class _UploadPageState extends State<UploadPage> {
  File? _selectedFile;
  bool _isUploading = false;
  String? _statusMessage;

  /// Öffnet den Datei‑Picker, um eine CSV‑Datei auszuwählen.
  Future<void> _pickCsv() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
    );
    if (result != null && result.files.isNotEmpty) {
      final path = result.files.single.path;
      if (path != null) {
        setState(() {
          _selectedFile = File(path);
          _statusMessage = null;
        });
      }
    }
  }

  /// Sendet die ausgewählte CSV‑Datei an den Server. Die Schnittstelle
  /// erwartet das Feld `file` im Multipart‑Payload. Nach dem Upload
  /// wird eine Statusmeldung in der Oberfläche angezeigt.
  Future<void> _uploadCsv() async {
    final file = _selectedFile;
    if (file == null) return;
    setState(() {
      _isUploading = true;
      _statusMessage = null;
    });
    try {
      final uri = Uri.parse('${widget.baseUrl}/php/upload.php');
      final request = http.MultipartRequest('POST', uri);
      request.files.add(
        await http.MultipartFile.fromPath(
          'file',
          file.path,
          filename: file.path.split('/').last,
          // Content‑Type wird nicht explizit gesetzt, der Server verarbeitet die Datei dennoch korrekt.
        ),
      );
      final response = await request.send();
      if (!mounted) return;
      if (response.statusCode >= 200 && response.statusCode < 400) {
        setState(() {
          _statusMessage = 'Datei erfolgreich hochgeladen.';
          _selectedFile = null;
        });
      } else {
        setState(() {
          _statusMessage = 'Upload fehlgeschlagen (Status ${response.statusCode}).';
        });
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'Fehler beim Upload: $e';
      });
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('CSV hochladen'),
      ),
      drawer: AppDrawer(currentRoute: '/upload'),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Gästeliste importieren',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: _isUploading ? null : _pickCsv,
              child: Text(
                _selectedFile == null
                    ? 'CSV‑Datei auswählen'
                    : 'Ausgewählt: ${_selectedFile!.path.split('/').last}',
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: (_selectedFile != null && !_isUploading)
                  ? _uploadCsv
                  : null,
              child: _isUploading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Importieren'),
            ),
            const SizedBox(height: 20),
            if (_statusMessage != null)
              Text(
                _statusMessage!,
                style: TextStyle(
                  color: _statusMessage!.toLowerCase().contains('fehler')
                      ? Colors.red
                      : Colors.green,
                ),
              ),
            const SizedBox(height: 20),
            const Text(
              'Hinweis: Die CSV‑Datei sollte aus dem Wix‑Export stammen und die Spalten\n'
              '„Guest first name“, „Guest last name“, „Email“, „Ticket type“ und „Ticket number“ enthalten.\n'
              'Beim Import werden vorhandene Datensätze anhand der Ticketnummer aktualisiert.',
            ),
          ],
        ),
      ),
    );
  }
}