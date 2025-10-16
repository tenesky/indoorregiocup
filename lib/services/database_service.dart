import 'package:mysql1/mysql1.dart';

/// A helper class for interacting with the MySQL database.
///
/// This service manages creating connections to the database and exposes
/// convenience methods to perform the queries required by the app. All
/// credentials and connection parameters are defined as static fields.
/// Update these values to point to your MySQL server. Exposing database
/// credentials in a client application is generally discouraged, but
/// this implementation reflects the user's request to connect directly
/// from the Flutter app. Consider using a secure backend API in
/// production environments instead.
class DatabaseService {
  // TODO: Configure these settings with your actual database details.
  static const String host = '80.152.153.30';
  static const int port = 3306;
  static const String user = 'irc';
  static const String password = 'irc2025!';
  static const String dbName = 'irc25';

  /// Creates a new connection to the database.
  static Future<MySqlConnection> _connect() {
    final settings = ConnectionSettings(
      host: host,
      port: port,
      user: user,
      password: password,
      db: dbName,
    );
    return MySqlConnection.connect(settings);
  }

  /// Fetches the application password from the `app_settings` table.
  static Future<String?> fetchAppPassword() async {
    final conn = await _connect();
    try {
      final results = await conn.query(
        'SELECT app_password FROM app_settings WHERE id = 1 LIMIT 1',
      );
      if (results.isNotEmpty) {
        final row = results.first;
        final value = row[0];
        return value?.toString();
      }
    } finally {
      await conn.close();
    }
    return null;
  }

  /// Updates the application password in the `app_settings` table.
  static Future<bool> updateAppPassword(String newPassword) async {
    final conn = await _connect();
    try {
      final result = await conn.query(
        'UPDATE app_settings SET app_password = ? WHERE id = 1',
        [newPassword],
      );
      return (result.affectedRows ?? 0) > 0;
    } finally {
      await conn.close();
    }
  }

  /// Retrieves all tickets from the `tickets` table.
  static Future<List<Map<String, dynamic>>> fetchTickets() async {
    final conn = await _connect();
    try {
      final results = await conn.query(
        'SELECT first_name, last_name, ticket_type, ticket_number, category, scanned FROM tickets',
      );
      return results.map((row) {
        return {
          'first_name': row[0],
          'last_name': row[1],
          'ticket_type': row[2],
          'ticket_number': row[3].toString(),
          'category': row[4],
          'scanned': row[5] == 1 || row[5] == true,
        };
      }).toList();
    } finally {
      await conn.close();
    }
  }

  /// Checks the status of a ticket in the database.
  static Future<Map<String, dynamic>> checkTicket(String ticketNumber) async {
    final conn = await _connect();
    try {
      final results = await conn.query(
        'SELECT first_name, last_name, category, scanned FROM tickets WHERE ticket_number = ?',
        [ticketNumber],
      );
      if (results.isEmpty) {
        return {'status': 'invalid'};
      }
      final row = results.first;
      final firstName = row[0]?.toString();
      final lastName = row[1]?.toString();
      final category = row[2]?.toString();
      final scanned = row[3] == 1 || row[3] == true;
      if (scanned) {
        return {
          'status': 'already_scanned',
          'first_name': firstName,
          'last_name': lastName,
          'category': category,
        };
      }
      await conn.query(
        'UPDATE tickets SET scanned = 1 WHERE ticket_number = ?',
        [ticketNumber],
      );
      await conn.query(
        'INSERT INTO scans (ticket_number, scanned_at, first_name, last_name, category) VALUES (?, NOW(), ?, ?, ?)',
        [ticketNumber, firstName, lastName, category],
      );
      return {
        'status': 'valid',
        'first_name': firstName,
        'last_name': lastName,
        'category': category,
      };
    } finally {
      await conn.close();
    }
  }

  /// Retrieves summary statistics and last scans.
  static Future<Map<String, dynamic>> fetchStats() async {
    final conn = await _connect();
    try {
      final categories = ['vollzahler', 'ermäßigt', 'vip', 'mannschaft', 'frei'];
      final summary = <String, Map<String, int>>{};
      for (final cat in categories) {
        final totalResult = await conn.query(
          'SELECT COUNT(*) FROM tickets WHERE category = ?',
          [cat],
        );
        final scannedResult = await conn.query(
          'SELECT COUNT(*) FROM tickets WHERE category = ? AND scanned = 1',
          [cat],
        );
        summary[cat] = {
          'total': totalResult.first[0] as int,
          'scanned': scannedResult.first[0] as int,
        };
      }
      final totalTicketsResult = await conn.query('SELECT COUNT(*) FROM tickets');
      final totalScannedResult = await conn.query('SELECT COUNT(*) FROM tickets WHERE scanned = 1');
      final totalTickets = totalTicketsResult.first[0] as int;
      final totalScanned = totalScannedResult.first[0] as int;

      final lastScansResult = await conn.query(
        'SELECT scanned_at, first_name, last_name, category, ticket_number FROM scans ORDER BY scanned_at DESC LIMIT 10',
      );
      final lastScans = lastScansResult.map((row) {
        return {
          'scanned_at': row[0]?.toString(),
          'first_name': row[1]?.toString(),
          'last_name': row[2]?.toString(),
          'category': row[3]?.toString(),
          'ticket_number': row[4]?.toString(),
        };
      }).toList();
      return {
        'summary': summary,
        'total_scanned': totalScanned,
        'total_tickets': totalTickets,
        'last_scans': lastScans,
      };
    } finally {
      await conn.close();
    }
  }

  /// Resets the scanned flag for all tickets in the `tickets` table.
  static Future<int> resetAllScans() async {
    final conn = await _connect();
    try {
      final result = await conn.query('UPDATE tickets SET scanned = 0');
      return result.affectedRows ?? 0;
    } finally {
      await conn.close();
    }
  }
}
