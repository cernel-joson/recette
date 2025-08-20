import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:recette/core/services/database_helper.dart';

void main() {
  // Use sqflite_common_ffi for testing on a desktop environment
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('DatabaseHelper', () {
    test('database creates all tables on new install', () async {
      // Arrange: Use an in-memory database for the test
      final db = await databaseFactory.openDatabase(inMemoryDatabasePath);

      // Act: Call the onCreate method directly
      await DatabaseHelper.instance.onCreate(db, 11); // Use the latest version

      // Assert: Verify that the job_history table and its columns exist
      final tableInfo = await db.rawQuery(
        "PRAGMA table_info(job_history);",
      );

      final columnNames = tableInfo.map((col) => col['name']).toList();

      expect(columnNames, contains('id'));
      expect(columnNames, contains('job_type'));
      expect(columnNames, contains('status'));
      expect(columnNames, contains('priority'));
      expect(columnNames, contains('request_fingerprint'));
      expect(columnNames, contains('request_payload'));
      expect(columnNames, contains('prompt_text'));
      expect(columnNames, contains('response_payload'));
      expect(columnNames, contains('created_at'));
      expect(columnNames, contains('completed_at'));

      await db.close();
    });
  });
}