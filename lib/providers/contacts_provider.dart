import 'package:flutter/foundation.dart';
import 'package:flutter_contacts/flutter_contacts.dart' as fc;
import 'package:permission_handler/permission_handler.dart';
import '../models/contact.dart';
import '../data/database_helper.dart';
import '../services/contact_service.dart';
import '../services/user_service.dart';

class ContactsProvider extends ChangeNotifier {
  final ContactService _contactService = ContactService();
  final UserService _userService = UserService();

  // Private list of contacts
  List<Contact> _contacts = [];
  List<Contact> _searchResults = [];
  bool _isLoading = false;
  bool _isSearchingBackend = false;
  String? _error;
  bool _isSyncing = false;
  bool _hasSynced = false;

  // Getters
  List<Contact> get contacts => _contacts;
  List<Contact> get searchResults => _searchResults;
  bool get isLoading => _isLoading;
  bool get isSearchingBackend => _isSearchingBackend;
  String? get error => _error;
  bool get isSyncing => _isSyncing;
  bool get hasSynced => _hasSynced;
  int get contactCount => _contacts.length;

  final DatabaseHelper _dbHelper = DatabaseHelper();

  // Initialize and load contacts from database
  ContactsProvider() {
    loadContacts();
  }

  // Load all contacts from database
  Future<void> loadContacts() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      _contacts = await _dbHelper.getAllContacts();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load contacts: $e';
      _isLoading = false;
      notifyListeners();
      debugPrint('Error loading contacts: $e');
    }
  }

  // Fetch and sync contacts from device
  Future<bool> syncDeviceContacts() async {
    try {
      _isSyncing = true;
      _error = null;
      notifyListeners();

      // Request permission
      PermissionStatus permission = await Permission.contacts.request();

      if (!permission.isGranted) {
        _error = 'Contact permission denied';
        _isSyncing = false;
        notifyListeners();
        return false;
      }

      // Fetch contacts from device using FlutterContacts (prefixed as fc)
      debugPrint('Fetching device contacts...');
      // FIX: Use fc.Contact and fc.FlutterContacts
      List<fc.Contact> deviceContacts = await fc.FlutterContacts.getContacts(
        withProperties: true,
        withPhoto: false,
      );

      debugPrint('Found ${deviceContacts.length} contacts on device');

      // Get existing contacts from database
      final existingContacts = await _dbHelper.getAllContacts();
      final existingNumbers = existingContacts
          .map((c) => _normalizePhoneNumber(c.phoneNumber))
          .toSet();

      int addedCount = 0;

      // Convert and add new contacts
      List<Contact> newContacts = [];
      for (var deviceContact in deviceContacts) {
        if (deviceContact.phones.isNotEmpty) {
          final phoneNumber = deviceContact.phones.first.number;
          final normalizedNumber = _normalizePhoneNumber(phoneNumber);

          // Skip if contact already exists
          if (existingNumbers.contains(normalizedNumber)) {
            continue;
          }

          // Create new contact from device contact
          final contact = Contact(
            name: deviceContact.displayName,
            phoneNumber: phoneNumber,
            designation: deviceContact.organizations.isNotEmpty
                ? deviceContact.organizations.first.title
                : '',
            organization: deviceContact.organizations.isNotEmpty
                ? deviceContact.organizations.first.company
                : '',
            expertise: '',
            location: deviceContact.addresses.isNotEmpty
                ? '${deviceContact.addresses.first.city}, ${deviceContact.addresses.first.state}'
                : '',
            email: deviceContact.emails.isNotEmpty
                ? deviceContact.emails.first.address
                : '',
            note: deviceContact.notes.isNotEmpty
                ? deviceContact.notes.first.note
                : '',
            profileImagePath: '',
          );

          newContacts.add(contact);
        }
      }

      if (newContacts.isNotEmpty) {
        await _dbHelper.insertContactsBatch(newContacts);
        addedCount = newContacts.length;
      }

      debugPrint('Added $addedCount new contacts to database');

      // Reload contacts
      await loadContacts();

      // Sync with backend (upload all local contacts)
      await syncWithBackend();

      _isSyncing = false;
      _hasSynced = true;
      notifyListeners();

      return true;
    } catch (e) {
      _error = 'Failed to sync contacts: $e';
      _isSyncing = false;
      notifyListeners();
      debugPrint('Error syncing contacts: $e');
      return false;
    }
  }

  // Sync local contacts with backend
  Future<void> syncWithBackend() async {
    try {
      if (_contacts.isEmpty) return;

      final contactsToUpload = _contacts
          .map(
            (c) => {
              'name': c.name,
              'phone': c.phoneNumber,
              'email': c.email,
              'organization': c.organization,
              'designation': c.designation,
            },
          )
          .toList();

      await _contactService.uploadContacts(contactsToUpload);
      debugPrint(
        'Successfully uploaded ${_contacts.length} contacts to backend',
      );
    } catch (e) {
      debugPrint('Failed to sync contacts with backend: $e');
    }
  }

  // Normalize phone number for comparison
  String _normalizePhoneNumber(String phoneNumber) {
    // Remove all non-digit characters
    return phoneNumber.replaceAll(RegExp(r'[^\d]'), '');
  }

  // Add a new contact
  Future<bool> addContact(Contact contact) async {
    try {
      _error = null;

      // Insert into database
      await _dbHelper.insertContact(contact);

      // Reload the contact list from database
      await loadContacts();

      return true;
    } catch (e) {
      _error = 'Failed to add contact: $e';
      notifyListeners();
      debugPrint('Error adding contact: $e');
      return false;
    }
  }

  // Search users in backend
  Future<void> searchUsersInBackend(Map<String, String> filters) async {
    try {
      _isSearchingBackend = true;
      _error = null;
      notifyListeners();

      final results = await _userService.searchUsers(filters);

      _searchResults = results.map((u) {
        return Contact(
          name: u['name'] ?? u['fullName'] ?? 'Unknown',
          phoneNumber: u['phone'] ?? u['phoneNumber'] ?? '',
          designation: u['designation'] ?? u['profession'] ?? '',
          organization: u['organization'] ?? u['company'] ?? '',
          location: u['location'] ?? '',
          email: u['email'] ?? '',
          profileImagePath: u['profileImage'] ?? u['avatar'] ?? '',
        );
      }).toList();

      _isSearchingBackend = false;
      notifyListeners();
    } catch (e) {
      _error = 'Backend search failed: $e';
      _isSearchingBackend = false;
      _searchResults = [];
      notifyListeners();
      debugPrint('Error searching backend: $e');
    }
  }

  // Clear search results
  void clearSearchResults() {
    _searchResults = [];
    notifyListeners();
  }

  // Find contact for incoming call by phone number
  Future<Contact?> findContactForCall(String phoneNumber) async {
    try {
      _error = null;

      // Try exact match first
      Contact? contact = await _dbHelper.getContactByPhone(phoneNumber);

      // If not found, try normalized match
      if (contact == null) {
        final normalized = _normalizePhoneNumber(phoneNumber);
        for (var c in _contacts) {
          if (_normalizePhoneNumber(c.phoneNumber).contains(normalized) ||
              normalized.contains(_normalizePhoneNumber(c.phoneNumber))) {
            return c;
          }
        }
      }

      return contact;
    } catch (e) {
      _error = 'Failed to find contact: $e';
      notifyListeners();
      debugPrint('Error finding contact: $e');
      return null;
    }
  }

  // Search contacts
  Future<List<Contact>> searchContacts(String query) async {
    try {
      _error = null;

      if (query.isEmpty) {
        return _contacts;
      }

      final results = await _dbHelper.searchContacts(query);
      return results;
    } catch (e) {
      _error = 'Failed to search contacts: $e';
      notifyListeners();
      debugPrint('Error searching contacts: $e');
      return [];
    }
  }

  // Delete contact
  Future<bool> deleteContact(int id) async {
    try {
      _error = null;

      await _dbHelper.deleteContact(id);

      // Reload the contact list
      await loadContacts();

      return true;
    } catch (e) {
      _error = 'Failed to delete contact: $e';
      notifyListeners();
      debugPrint('Error deleting contact: $e');
      return false;
    }
  }

  // Update contact
  Future<bool> updateContact(Contact contact) async {
    try {
      _error = null;

      if (contact.id != null) {
        await _dbHelper.updateContact(contact);
        await loadContacts();
      }

      return true;
    } catch (e) {
      _error = 'Failed to update contact: $e';
      notifyListeners();
      debugPrint('Error updating contact: $e');
      return false;
    }
  }

  // Clear error message
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Get contact by ID
  Contact? getContactById(int id) {
    try {
      return _contacts.firstWhere((contact) => contact.id == id);
    } catch (e) {
      return null;
    }
  }
}
