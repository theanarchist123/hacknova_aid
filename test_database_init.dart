import 'dart:io';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'lib/core/services/community_pin_database.dart';

void main() async {
  print('🧪 Testing database initialization...');
  
  try {
    // Initialize the database
    CommunityPinDatabase.initialize();
    
    print('✅ Database factory initialized');
    
    // Test database access
    final db = await CommunityPinDatabase.instance.database;
    print('✅ Database opened successfully');
    
    // Test a simple query
    final tables = await db.rawQuery("SELECT name FROM sqlite_master WHERE type='table'");
    print('✅ Database query successful. Tables: ${tables.map((t) => t['name']).toList()}');
    
    print('🎉 All database tests passed!');
    
  } catch (e, stackTrace) {
    print('❌ Database test failed: $e');
    print('Stack trace: $stackTrace');
  }
}