// removed: no JSON decoding needed

import 'package:flutter/material.dart';
// http import removed: not used, QR images are loaded directly by Image.network
import '../widgets/app_drawer.dart';
import '../services/database_service.dart';

/// Seite, die eine Galerie aller generierten QR‑Codes anzeigt.
///
/// Die QR‑Codes werden nicht direkt aus dem Dateisystem geladen, sondern
/// dynamisch über `php/generate_qr.php` generiert oder bereitgestellt.
/// Die Liste der Tickets wird von `php/get_tickets.php` geladen. Über
/// Dropdown‑Felder kann nach Kategorie und Scan‑Status gefiltert werden.
class GalleryPage extends StatefulWidget {
  final String baseUrl;
  const GalleryPage({Key? key, required this.baseUrl}) : super(key: key);

  @override
  State<GalleryPage> createState() => _GalleryPageState();
}

class _GalleryPageState extends State<GalleryPage> {
  List<dynamic> _tickets = [];
  bool _loading = false;
  String _filterCategory = '';
  String _filterScanned = '';

  @override
  void initState() {
    super.initState();
    _fetchTickets();
  }

  /// Lädt alle Tickets vom Server für die Galerie.
  Future<void> _fetchTickets() async {
    setState(() {
      _loading = true;
    });
    try {
      final data = await DatabaseService.fetchTickets();
      setState(() {
        _tickets = data;
      });
    } catch (_) {
      // ignorieren
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  /// Gibt die gefilterten Tickets zurück.
  List<dynamic> get _filteredTickets {
    return _tickets.where((t) {
      final category = (t['category'] ?? '').toString();
      final scanned = t['scanned'] == 1 || t['scanned'] == true;
      if (_filterCategory.isNotEmpty && category != _filterCategory) return false;
      if (_filterScanned == 'scanned' && !scanned) return false;
      if (_filterScanned == 'not_scanned' && scanned) return false;
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('QR‑Codes'),
      ),
      drawer: AppDrawer(currentRoute: '/gallery'),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Filter‑Kontrollen
            Row(
              children: [
                const Text('Tickettyp:'),
                const SizedBox(width: 8),
                DropdownButton<String>(
                  value: _filterCategory.isEmpty ? null : _filterCategory,
                  hint: const Text('Alle'),
                  items: const [
                    DropdownMenuItem(value: 'vollzahler', child: Text('Vollzahler')),
                    DropdownMenuItem(value: 'ermäßigt', child: Text('Ermäßigt')),
                    DropdownMenuItem(value: 'vip', child: Text('VIP')),
                    DropdownMenuItem(value: 'mannschaft', child: Text('Mannschaft')),
                    DropdownMenuItem(value: 'frei', child: Text('Frei/Staff')),
                  ],
                  onChanged: (val) {
                    setState(() {
                      _filterCategory = val ?? '';
                    });
                  },
                ),
                const SizedBox(width: 16),
                const Text('Status:'),
                const SizedBox(width: 8),
                DropdownButton<String>(
                  value: _filterScanned.isEmpty ? null : _filterScanned,
                  hint: const Text('Alle'),
                  items: const [
                    DropdownMenuItem(value: 'scanned', child: Text('Gescannt')),
                    DropdownMenuItem(value: 'not_scanned', child: Text('Nicht gescannt')),
                  ],
                  onChanged: (val) {
                    setState(() {
                      _filterScanned = val ?? '';
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _filteredTickets.isEmpty
                      ? const Center(child: Text('Keine QR‑Codes gefunden.'))
                      : GridView.builder(
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 0.8,
                          ),
                          itemCount: _filteredTickets.length,
                          itemBuilder: (context, index) {
                            final ticket = _filteredTickets[index];
                            final ticketNumber = (ticket['ticket_number'] ?? '').toString();
                            final category = ticket['category']?.toString() ?? '';
                            final scanned = ticket['scanned'] == 1 || ticket['scanned'] == true;
                            final imgUrl = '${widget.baseUrl}/php/generate_qr.php?ticket_number=${Uri.encodeComponent(ticketNumber)}';
                            return Card(
                              elevation: 2,
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Image.network(
                                        imgUrl,
                                        fit: BoxFit.contain,
                                        loadingBuilder: (context, child, loadingProgress) {
                                          if (loadingProgress == null) return child;
                                          return const Center(child: CircularProgressIndicator());
                                        },
                                        errorBuilder: (context, error, stackTrace) {
                                          return const Center(child: Icon(Icons.broken_image));
                                        },
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      ticketNumber,
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 4),
                                    if (category.isNotEmpty)
                                      Text(
                                        '$category${scanned ? ', gescannt' : ', nicht gescannt'}',
                                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                                        textAlign: TextAlign.center,
                                      ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}