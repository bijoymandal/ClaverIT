import 'package:flutter/material.dart';
import '../data/database_helper.dart';
import '../data/contacts_data.dart';

class DatabaseSeeder {
  static Future<void> seedDatabase() async {
    final dbHelper = DatabaseHelper();
    
    try {
      // Check if database is already seeded
      final existingContacts = await dbHelper.getAllContacts();
      
      if (existingContacts.isEmpty) {
        debugPrint('Seeding database with initial contacts...');
        
        // Insert sample contacts from contacts_data.dart
        for (var contact in contactsList) {
          await dbHelper.insertContact(contact);
        }
        
        debugPrint('Database seeded successfully with ${contactsList.length} contacts');
      } else {
        debugPrint('Database already contains ${existingContacts.length} contacts');
      }
    } catch (e) {
      debugPrint('Error seeding database: $e');
    }
  }
}
