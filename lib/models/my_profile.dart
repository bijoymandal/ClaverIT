import 'package:shared_preferences/shared_preferences.dart';

class MyProfile {
  final String name;
  final String designation;
  final String organization;
  final String location;
  final String phoneNumber;

  MyProfile({
    required this.name,
    required this.designation,
    required this.organization,
    required this.location,
    required this.phoneNumber,
  });

  // Convert to JSON map
  Map<String, String> toMap() {
    return {
      'name': name,
      'designation': designation,
      'organization': organization,
      'location': location,
      'phoneNumber': phoneNumber,
    };
  }

  // Create from JSON map
  factory MyProfile.fromMap(Map<String, dynamic> map) {
    return MyProfile(
      name: map['name'] ?? '',
      designation: map['designation'] ?? '',
      organization: map['organization'] ?? '',
      location: map['location'] ?? '',
      phoneNumber: map['phoneNumber'] ?? '',
    );
  }

  // Save to SharedPreferences
  Future<bool> save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final map = toMap();
      
      await prefs.setString('profile_name', map['name']!);
      await prefs.setString('profile_designation', map['designation']!);
      await prefs.setString('profile_organization', map['organization']!);
      await prefs.setString('profile_location', map['location']!);
      await prefs.setString('profile_phoneNumber', map['phoneNumber']!);
      
      return true;
    } catch (e) {
      return false;
    }
  }

  // Load from SharedPreferences
  static Future<MyProfile> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      return MyProfile(
        name: prefs.getString('profile_name') ?? '',
        designation: prefs.getString('profile_designation') ?? '',
        organization: prefs.getString('profile_organization') ?? '',
        location: prefs.getString('profile_location') ?? '',
        phoneNumber: prefs.getString('profile_phoneNumber') ?? '',
      );
    } catch (e) {
      return MyProfile(
        name: '',
        designation: '',
        organization: '',
        location: '',
        phoneNumber: '',
      );
    }
  }

  // Clear profile
  static Future<bool> clear() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('profile_name');
      await prefs.remove('profile_designation');
      await prefs.remove('profile_organization');
      await prefs.remove('profile_location');
      await prefs.remove('profile_phoneNumber');
      return true;
    } catch (e) {
      return false;
    }
  }
}