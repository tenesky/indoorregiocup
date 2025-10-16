import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../services/database_service.dart';
import '../widgets/app_drawer.dart';

/// Seite mit der Ticketübersicht.
///
/// Die App ruft die Liste aller Tickets von `php/get_tickets.php` ab und
/// stellt sie in einer Tabelle dar. Über Suchfeld und Dropdown
/// kann nach Namen, Tickettyp oder Ticketnummer gefiltert werden. Mit
/// Checkboxen lassen sich Tickets auswählen, um QR‑Codes zu generieren,
/// E‑Mails zu versenden oder den Scan‑Status zurückzusetzen.
class TicketsPage extends StatefulWidget {
  final String baseUrl;
  const TicketsPage({Key? key, required this.baseUrl}) : super(key: key);

  @override
  State<TicketsPage> createState() => _TicketsPageState();
}

class _TicketsPageState extends State<TicketsPage> {
  List<dynamic> _tickets = [];
  bool _loading = false;
  String _searchText = '';
  String _filterCategory = '';
  final Set<String> _selected = {};

  @override
  void initState() {
    super.initState();
    _fetchTickets();
  }

  /// Lädt alle Tickets vom Server.
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
      // Fehler werden durch die Anzeige des Ladezustands signalisiert
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  /// Gibt die Liste der Tickets zurück, gefiltert nach Suchtext und Kategorie.
  List<dynamic> get _filteredTickets {
    final lowerSearch = _searchText.trim().toLowerCase();
    return _tickets.where((t) {
      final category = (t['category'] ?? '').toString();
      if (_filterCategory.isNotEmpty && category != _filterCategory) {
        return false;
      }
      if (lowerSearch.isEmpty) return true;
      final fullText = '${t['first_name'] ?? ''} ${t['last_name'] ?? ''} ${t['ticket_type'] ?? ''} ${t['ticket_number'] ?? ''}'
          .toLowerCase();
      return fullText.contains(lowerSearch);
    }).toList();
  }

  /// Öffnet ein Dialogfenster mit dem QR‑Code für die angegebene Ticketnummer.
  void _openQr(String ticketNumber) {
    showDialog(
      context: context,
      builder: (context) {
        final imgUrl = '${widget.baseUrl}/php/generate_qr.php?ticket_number=${Uri.encodeComponent(ticketNumber)}';
        return AlertDialog(
          title: Text('QR‑Code für $ticketNumber'),
          content: Image.network(imgUrl, width: 250, height: 250, fit: BoxFit.contain),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Schließen'),
            ),
          ],
        );
      },
    );
  }

  /// Generiert QR‑Codes für alle Tickets.
  Future<void> _generateAllQRCodes() async {
    final ticketsToProcess = _tickets.map((e) => e['ticket_number']?.toString() ?? '').where((n) => n.isNotEmpty).toList();
    await _processBatch(ticketsToProcess, (number) async {
      final uri = Uri.parse('${widget.baseUrl}/php/generate_qr.php?ticket_number=${Uri.encodeComponent(number)}');
      await http.get(uri);
    });
  }

  /// Generiert QR‑Codes für ausgewählte Tickets.
  Future<void> _generateSelectedQRCodes() async {
    final ticketsToProcess = _selected.toList();
    if (ticketsToProcess.isEmpty) return;
    await _processBatch(ticketsToProcess, (number) async {
      final uri = Uri.parse('${widget.baseUrl}/php/generate_qr.php?ticket_number=${Uri.encodeComponent(number)}');
      await http.get(uri);
    });
  }

  /// Sendet E‑Mails für ausgewählte Tickets.
  Future<void> _sendEmails() async {
    final ticketsToProcess = _selected.toList();
    if (ticketsToProcess.isEmpty) return;
    // Bestätigen
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('E‑Mails senden'),
        content: Text('Möchtest du die E‑Mails für ${ticketsToProcess.length} ausgewählte Tickets senden?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Abbrechen')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Senden')),
        ],
      ),
    );
    if (confirm != true) return;
    // Zeige Fortschritt
    int processed = 0;
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            Future<void> _send() async {
              try {
                final uri = Uri.parse('${widget.baseUrl}/php/send_emails.php');
                final response = await http.post(
                  uri,
                  headers: {'Content-Type': 'application/json'},
                  body: jsonEncode({'ticket_numbers': ticketsToProcess}),
                );
                if (response.statusCode == 200) {
                  final json = jsonDecode(response.body);
                  processed = json['processed'] ?? ticketsToProcess.length;
                }
              } catch (_) {
                processed = ticketsToProcess.length;
              }
              if (mounted) {
                setStateDialog(() {});
                await Future.delayed(const Duration(seconds: 2));
                if (mounted) Navigator.pop(context);
              }
            }
            // Trigger den Versand, sobald der Dialog gebaut wurde
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _send();
            });
            return AlertDialog(
              title: const Text('E‑Mails werden gesendet'),
              content: SizedBox(
                height: 60,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    Text('0 / ${ticketsToProcess.length} verarbeitet'),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
    // Nach dem Versand eine Meldung ausgeben
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('E‑Mails wurden versendet für $processed Ticket(s).'),
      ),
    );
  }

  /// Setzt den Scan‑Status aller Tickets zurück.
  Future<void> _resetScans() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Scan‑Status zurücksetzen'),
        content: const Text('Möchtest du wirklich den Scan‑Status aller Tickets zurücksetzen?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Abbrechen')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Zurücksetzen')),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      final affected = await DatabaseService.resetAllScans();
      await _fetchTickets();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Scan‑Status für $affected Ticket(s) zurückgesetzt.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Fehler beim Zurücksetzen: $e')),
      );
    }
  }

  /// Führt eine Batch‑Verarbeitung mit Fortschrittsdialog durch.
  Future<void> _processBatch(List<String> items, Future<void> Function(String) action) async {
    if (items.isEmpty) return;
    int processed = 0;
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            Future<void> _run() async {
              for (final item in items) {
                try {
                  await action(item);
                } catch (_) {
                  // Fehler ignorieren
                }
                processed++;
                setStateDialog(() {});
              }
              await Future.delayed(const Duration(seconds: 1));
              if (mounted) Navigator.pop(context);
            }
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _run();
            });
            final percent = (processed / items.length * 100).round();
            return AlertDialog(
              title: const Text('Bitte warten'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  LinearProgressIndicator(value: processed / items.length),
                  const SizedBox(height: 16),
                  Text('$percent% ($processed/${items.length})'),
                ],
              ),
            );
          },
        );
      },
    );
    // Nach Abschluss die Liste neu laden
    await _fetchTickets();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ticketübersicht'),
      ),
      drawer: AppDrawer(currentRoute: '/tickets'),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Such‑ und Filterleiste
            Row(
              children: [
                // Suchfeld
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(
                      labelText: 'Suchen (Name, Ticketnummer…) ',
                    ),
                    onChanged: (val) {
                      setState(() {
                        _searchText = val;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 12),
                // Kategorie‑Filter
                DropdownButton<String>(
                  value: _filterCategory.isEmpty ? null : _filterCategory,
                  hint: const Text('Alle Tickettypen'),
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
              ],
            ),
            const SizedBox(height: 16),
            // Aktionsbuttons
            Wrap(
              spacing: 8.0,
              runSpacing: 8.0,
              children: [
                ElevatedButton(
                  onPressed: _loading || _tickets.isEmpty ? null : _generateAllQRCodes,
                  child: const Text('Alle QR‑Codes generieren'),
                ),
                ElevatedButton(
                  onPressed: _loading || _selected.isEmpty ? null : _generateSelectedQRCodes,
                  child: const Text('Ausgewählte QR generieren'),
                ),
                ElevatedButton(
                  onPressed: _loading || _selected.isEmpty ? null : _sendEmails,
                  child: const Text('E‑Mails senden'),
                ),
                ElevatedButton(
                  onPressed: _loading || _tickets.isEmpty ? null : _resetScans,
                  child: const Text('Scan‑Status zurücksetzen'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Tabelle oder Ladespinner
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _filteredTickets.isEmpty
                      ? const Center(child: Text('Keine Tickets gefunden.'))
                      : SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: DataTable(
                            columnSpacing: 16,
                            headingRowHeight: 40,
                            dataRowHeight: 48,
                            columns: const [
                              DataColumn(label: Text('Auswahl')),
                              DataColumn(label: Text('Vorname')),
                              DataColumn(label: Text('Nachname')),
                              DataColumn(label: Text('Tickettyp')),
                              DataColumn(label: Text('Ticketnummer')),
                              DataColumn(label: Text('Kategorie')),
                              DataColumn(label: Text('Gescannt')),
                              DataColumn(label: Text('QR‑Code')),
                            ],
                            rows: _filteredTickets.map((t) {
                              final ticketNumber = (t['ticket_number'] ?? '').toString();
                              final selected = _selected.contains(ticketNumber);
                              return DataRow(
                                cells: [
                                  DataCell(
                                    Checkbox(
                                      value: selected,
                                      onChanged: (val) {
                                        setState(() {
                                          if (val == true) {
                                            _selected.add(ticketNumber);
                                          } else {
                                            _selected.remove(ticketNumber);
                                          }
                                        });
                                      },
                                    ),
                                  ),
                                  DataCell(Text(t['first_name']?.toString() ?? '')),
                                  DataCell(Text(t['last_name']?.toString() ?? '')),
                                  DataCell(Text(t['ticket_type']?.toString() ?? '')),
                                  DataCell(Text(ticketNumber)),
                                  DataCell(Text(t['category']?.toString() ?? '')),
                                  DataCell(Text((t['scanned'] == 1 || t['scanned'] == true) ? 'Ja' : 'Nein')),
                                  DataCell(
                                    InkWell(
                                      onTap: () {
                                        _openQr(ticketNumber);
                                      },
                                      child: const Text(
                                        'QR anzeigen',
                                        style: TextStyle(color: Colors.blue, decoration: TextDecoration.underline),
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            }).toList(),
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}