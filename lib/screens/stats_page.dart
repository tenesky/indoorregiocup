import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../widgets/app_drawer.dart';

/// Seite für Statistiken und aktuelle Scans.
///
/// Die App ruft periodisch Statistiken von `php/stats_data.php` ab. Angezeigt
/// werden die Gesamt‑ und Kategorie‑Zahlen (gescannt/gesamt) sowie die
/// letzten zehn Scans mit Zeit, Name, Kategorie und Ticketnummer.
/// Zusätzlich wird eine Echtzeit‑Uhr eingeblendet.
class StatsPage extends StatefulWidget {
  final String baseUrl;
  const StatsPage({Key? key, required this.baseUrl}) : super(key: key);

  @override
  State<StatsPage> createState() => _StatsPageState();
}

class _StatsPageState extends State<StatsPage> {
  Map<String, Map<String, int>> _summary = {
    'vollzahler': {'scanned': 0, 'total': 0},
    'ermäßigt': {'scanned': 0, 'total': 0},
    'vip': {'scanned': 0, 'total': 0},
    'mannschaft': {'scanned': 0, 'total': 0},
    'frei': {'scanned': 0, 'total': 0},
  };
  int _totalScanned = 0;
  int _totalTickets = 0;
  List<dynamic> _lastScans = [];
  String _currentTime = '--:--:--';
  Timer? _clockTimer;
  Timer? _statsTimer;

  @override
  void initState() {
    super.initState();
    _updateClock();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) => _updateClock());
    _fetchStats();
    _statsTimer = Timer.periodic(const Duration(seconds: 5), (_) => _fetchStats());
  }

  /// Aktualisiert die Uhrzeit im Format HH:MM:SS.
  void _updateClock() {
    final now = DateTime.now();
    setState(() {
      _currentTime = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';
    });
  }

  /// Holt Statistikdaten vom Server und aktualisiert die Ansicht.
  Future<void> _fetchStats() async {
    try {
      final uri = Uri.parse('${widget.baseUrl}/php/stats_data.php?_=${DateTime.now().millisecondsSinceEpoch}');
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final summary = json['summary'] as Map<String, dynamic>?;
        if (summary != null) {
          setState(() {
            _summary = {
              'vollzahler': {
                'scanned': summary['vollzahler']?['scanned'] ?? 0,
                'total': summary['vollzahler']?['total'] ?? 0,
              },
              'ermäßigt': {
                'scanned': summary['ermäßigt']?['scanned'] ?? 0,
                'total': summary['ermäßigt']?['total'] ?? 0,
              },
              'vip': {
                'scanned': summary['vip']?['scanned'] ?? 0,
                'total': summary['vip']?['total'] ?? 0,
              },
              'mannschaft': {
                'scanned': summary['mannschaft']?['scanned'] ?? 0,
                'total': summary['mannschaft']?['total'] ?? 0,
              },
              'frei': {
                'scanned': summary['frei']?['scanned'] ?? 0,
                'total': summary['frei']?['total'] ?? 0,
              },
            };
            _totalScanned = json['total_scanned'] ?? 0;
            _totalTickets = json['total_tickets'] ?? 0;
            _lastScans = json['last_scans'] as List<dynamic>? ?? [];
          });
        }
      }
    } catch (_) {
      // Fehler werden ignoriert, die Ansicht bleibt unverändert
    }
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    _statsTimer?.cancel();
    super.dispose();
  }

  /// Erstellt eine farbige Karte für eine Kategorie.
  Widget _summaryCard(String title, String key, Color color) {
    final data = _summary[key] ?? {'scanned': 0, 'total': 0};
    return Card(
      elevation: 2,
      color: color.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('${data['scanned']} / ${data['total']}'),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistiken'),
      ),
      drawer: AppDrawer(currentRoute: '/stats'),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _summaryCard('Vollzahler', 'vollzahler', Colors.green),
                  _summaryCard('Ermäßigt', 'ermäßigt', Colors.orange),
                  _summaryCard('VIP', 'vip', Colors.purple),
                  _summaryCard('Mannschaft', 'mannschaft', Colors.blue),
                  _summaryCard('Frei/Staff', 'frei', Colors.grey),
                  Card(
                    elevation: 2,
                    color: Colors.teal.withOpacity(0.1),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Gesamt gescannt', style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          Text('$_totalScanned / $_totalTickets'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Aktuelle Uhrzeit', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text(
                        _currentTime,
                        style: const TextStyle(fontSize: 24),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text('Letzte Scans', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              _lastScans.isEmpty
                  ? const Text('Keine Scans vorhanden.')
                  : SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        columnSpacing: 16,
                        columns: const [
                          DataColumn(label: Text('Zeit')),
                          DataColumn(label: Text('Name')),
                          DataColumn(label: Text('Kategorie')),
                          DataColumn(label: Text('Ticketnummer')),
                        ],
                        rows: _lastScans.map((item) {
                          final dtStr = item['scanned_at'];
                          String timeString = '';
                          if (dtStr != null && dtStr is String && dtStr.isNotEmpty) {
                            try {
                              final dt = DateTime.parse(dtStr);
                              timeString = '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}:${dt.second.toString().padLeft(2, '0')}';
                            } catch (_) {
                              timeString = dtStr;
                            }
                          }
                          final name = '${item['first_name'] ?? ''} ${item['last_name'] ?? ''}'.trim();
                          final category = item['category']?.toString() ?? '';
                          final ticketNumber = item['ticket_number']?.toString() ?? '';
                          return DataRow(
                            cells: [
                              DataCell(Text(timeString)),
                              DataCell(Text(name)),
                              DataCell(Text(category)),
                              DataCell(Text(ticketNumber)),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}