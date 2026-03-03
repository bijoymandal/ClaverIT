import 'package:flutter/foundation.dart';
import '../services/user_service.dart';
import '../services/qr_service.dart';
import '../models/my_profile.dart';

class UserProvider extends ChangeNotifier {
  final UserService _userService = UserService();
  final QrService _qrService = QrService();

  MyProfile? _profile;
  Map<String, dynamic>? _qrData;
  bool _isLoading = false;
  String? _error;

  MyProfile? get profile => _profile;
  Map<String, dynamic>? get qrData => _qrData;
  bool get isLoading => _isLoading;
  String? get error => _error;

  String get initials {
    if (_profile == null || _profile!.name.isEmpty) return '??';
    final names = _profile!.name.trim().split(' ');
    if (names.isEmpty) return '??';
    if (names.length == 1) return names[0][0].toUpperCase();
    return '${names[0][0]}${names[names.length - 1][0]}'.toUpperCase();
  }

  Future<void> loadUserData() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final backendProfile = await _userService.getMyProfile();
      _profile = MyProfile(
        name: backendProfile['fullName'] ?? '',
        designation: backendProfile['designation'] ?? '',
        organization: backendProfile['organization'] ?? '',
        location: backendProfile['address'] != null 
            ? '${backendProfile['address']['city'] ?? ''}, ${backendProfile['address']['state'] ?? ''}'
            : '',
        phoneNumber: backendProfile['phone'] ?? '',
      );
      await _profile!.save();

      try {
        _qrData = await _qrService.getMyQr();
      } catch (e) {
        debugPrint('Failed to load QR data: $e');
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      // Try to load from local storage if backend fails
      _profile = await MyProfile.load();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateProfile(Map<String, dynamic> data) async {
    try {
      await _userService.updateProfile(data);
      await loadUserData();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  void clearData() {
    _profile = null;
    _qrData = null;
    notifyListeners();
  }
}
