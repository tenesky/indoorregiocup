import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:http/http.dart' as http;
import '../widgets/app_drawer.dart';

/// Scanner‑Seite für das Einlesen von QR‑Codes.
///
/// Diese Seite nutzt die [mobile_scanner]‑Bibliothek, um QR‑Codes mit der
/// Gerätekamera zu erkennen. Wird ein Code erkannt, so wird dessen
/// Ticketnummer extrahiert und eine Anfrage an die Server‑API
/// `php/check_ticket.php` gesendet. Das Ergebnis bestimmt die
/// Hintergrundfarbe sowie den angezeigten Text. Ein kurzer Cooldown
/// verhindert Mehrfachscans desselben Tickets innerhalb weniger Sekunden.
class ScanPage extends StatefulWidget {
  final String baseUrl;
  const ScanPage({Key? key, required this.baseUrl}) : super(key: key);

  @override
  State<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanPage> {
  // Zustandsvariablen für die Anzeige
  bool _overlayVisible = false;
  Color _overlayColor = Colors.transparent;
  String _overlayText = '';
  Timer? _overlayTimer;

  // Zur Vermeidung von Doppelscans
  DateTime? _cooldownUntil;
  String? _lastDisplayedCode;
  DateTime? _lastDisplayedTime;

  // Farbe des Rahmens um das Videobild
  Color _borderColor = Colors.grey;

  /// Extrahiert die Ticketnummer aus dem gescannten QR‑Code. Wenn der
  /// gescannte String eine URL darstellt, wird der letzte Teil des
  /// Pfades genutzt. Andernfalls wird der ursprüngliche String
  /// zurückgegeben.
  String _extractTicketNumber(String data) {
    String ticketNumber = data.trim();
    try {
      final uri = Uri.parse(data);
      // Nur wenn ein Pfad vorhanden ist und nicht nur ein Protokoll
      if (uri.path.isNotEmpty) {
        final parts = uri.path.split('/').where((p) => p.isNotEmpty).toList();
        if (parts.isNotEmpty) {
          ticketNumber = parts.last;
        }
      }
    } catch (_) {
      // keine gültige URL, Originalstring verwenden
    }
    return ticketNumber;
  }

  /// Verarbeitet den gescannten QR‑Code. Ruft die API auf und aktualisiert
  /// die Anzeige entsprechend dem Ergebnis.
  Future<void> _handleScan(String data) async {
    final ticketNumber = _extractTicketNumber(data);
    if (ticketNumber.isEmpty) {
      _showResult(
        status: 'invalid',
        category: null,
        firstName: null,
        lastName: null,
        code: ticketNumber,
      );
      return;
    }
    final now = DateTime.now();
    // Cooldown: Wenn sich der aktuelle Zeitpunkt innerhalb der Cooldown‑Phase befindet, wird ignoriert.
    if (_cooldownUntil != null && now.isBefore(_cooldownUntil!)) {
      return;
    }
    // Wenn derselbe Code innerhalb von vier Sekunden erneut erkannt wird, zeige nur erneut das Overlay.
    if (_lastDisplayedCode != null && _lastDisplayedCode == ticketNumber) {
      if (_lastDisplayedTime != null && now.difference(_lastDisplayedTime!) < const Duration(seconds: 4)) {
        _overlayTimer?.cancel();
        setState(() {
          _overlayVisible = true;
        });
        _overlayTimer = Timer(const Duration(seconds: 4), () {
          setState(() {
            _overlayVisible = false;
          });
        });
        return;
      }
    }
    // Setze Cooldown auf 2 Sekunden ab jetzt
    _cooldownUntil = now.add(const Duration(seconds: 2));
    _lastDisplayedCode = ticketNumber;
    _lastDisplayedTime = now;
    try {
      final uri = Uri.parse(
        '${widget.baseUrl}/php/check_ticket.php?ticket_number=${Uri.encodeComponent(ticketNumber)}',
      );
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final Map<String, dynamic> json = jsonDecode(response.body);
        final status = json['status'] as String? ?? 'invalid';
        final category = json['category'] as String?;
        final firstName = json['first_name'] as String?;
        final lastName = json['last_name'] as String?;
        _showResult(
          status: status,
          category: category,
          firstName: firstName,
          lastName: lastName,
          code: ticketNumber,
        );
      } else {
        _showResult(
          status: 'invalid',
          category: null,
          firstName: null,
          lastName: null,
          code: ticketNumber,
        );
      }
    } catch (_) {
      // Bei Fehlern zeigt die App ebenfalls „ungültig“ an
      _showResult(
        status: 'invalid',
        category: null,
        firstName: null,
        lastName: null,
        code: ticketNumber,
      );
    }
  }

  /// Zeigt das Ergebnis eines Scans als Overlay an.
  void _showResult({
    required String status,
    required String? category,
    required String? firstName,
    required String? lastName,
    required String code,
  }) {
    String text;
    Color overlayColor;
    Color borderColor;
    if (status == 'invalid') {
      text = 'Ticket ungültig oder nicht gefunden.';
      overlayColor = const Color.fromRGBO(220, 53, 69, 0.5);
      borderColor = Colors.red;
    } else if (status == 'already_scanned') {
      final name = '${firstName ?? ''} ${lastName ?? ''}'.trim();
      text = 'Ticket für $name wurde bereits eingecheckt.';
      overlayColor = const Color.fromRGBO(220, 53, 69, 0.5);
      borderColor = Colors.red;
    } else {
      final name = '${firstName ?? ''} ${lastName ?? ''}'.trim();
      String typeDesc;
      switch (category) {
        case 'vollzahler':
          typeDesc = 'Vollzahler';
          overlayColor = const Color.fromRGBO(40, 167, 69, 0.5);
          borderColor = Colors.green;
          break;
        case 'ermäßigt':
          typeDesc = 'Ermäßigt';
          overlayColor = const Color.fromRGBO(240, 173, 78, 0.5);
          borderColor = Colors.orange;
          break;
        case 'vip':
          typeDesc = 'VIP';
          overlayColor = const Color.fromRGBO(111, 66, 193, 0.5);
          borderColor = Colors.purple;
          break;
        case 'mannschaft':
          typeDesc = 'Mannschaft';
          overlayColor = const Color.fromRGBO(0, 123, 255, 0.5);
          borderColor = Colors.blue;
          break;
        case 'frei':
        default:
          typeDesc = category ?? '';
          overlayColor = const Color.fromRGBO(108, 117, 125, 0.5);
          borderColor = Colors.grey;
          break;
      }
      text = 'Willkommen $name! Kategorie: $typeDesc.';
    }
    _overlayTimer?.cancel();
    setState(() {
      _overlayColor = overlayColor;
      _borderColor = borderColor;
      _overlayText = text;
      _overlayVisible = true;
    });
    _overlayTimer = Timer(const Duration(seconds: 4), () {
      if (mounted) {
        setState(() {
          _overlayVisible = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _overlayTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('QR‑Scanner'),
      ),
      drawer: AppDrawer(currentRoute: '/scan'),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                // Videostream zur Anzeige der Kamera
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: _borderColor, width: 4),
                  ),
                  child: MobileScanner(
                    fit: BoxFit.cover,
                    // Erkennung von QR‑Codes
                    onDetect: (capture) {
                      for (final barcode in capture.barcodes) {
                        final rawValue = barcode.rawValue;
                        if (rawValue != null) {
                          _handleScan(rawValue);
                          break;
                        }
                      }
                    },
                  ),
                ),
                // Overlay mit Ergebnis
                if (_overlayVisible)
                  Positioned.fill(
                    child: Container(
                      color: _overlayColor,
                      alignment: Alignment.center,
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        _overlayText,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: const Text(
              'Richte die Kamera auf einen QR‑Code, um den Check‑In zu starten. Ein kurzer Cooldown verhindert Mehrfachscans.',
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}