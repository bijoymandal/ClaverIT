import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

// Screens
import 'keypad_screen.dart';
import 'recent_screen.dart';
import 'contacts_screen.dart';
import 'profile_screen.dart';

// Services & Providers
import '../providers/contacts_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  int _currentIndex = 0;
  bool _permissionsGranted = false;
  bool _isCheckingPermissions = true;

  late PageController _pageController;

  final List<Widget> _screens = [
    const KeypadScreen(),
    const RecentScreen(),
    const ContactsScreen(),
    const ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentIndex);

    // Check permissions after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndRequestPermissions();
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _checkAndRequestPermissions() async {
    if (!mounted) return;
    setState(() => _isCheckingPermissions = true);

    // Check status of all required permissions
    final phoneStatus = await Permission.phone.status;
    final contactsStatus = await Permission.contacts.status;
    final microphoneStatus = await Permission.microphone.status;

    if (!phoneStatus.isGranted ||
        !contactsStatus.isGranted ||
        !microphoneStatus.isGranted) {
      Map<Permission, PermissionStatus> statuses = await [
        Permission.phone,
        Permission.contacts,
        Permission.microphone,
      ].request();

      if (!mounted) return;

      final allGranted = statuses.values.every((status) => status.isGranted);

      if (allGranted) {
        await _onPermissionsGranted();
      } else {
        _showPermissionDeniedDialog();
      }
    } else {
      await _onPermissionsGranted();
    }

    if (mounted) {
      setState(() => _isCheckingPermissions = false);
    }
  }

  Future<void> _onPermissionsGranted() async {
    setState(() => _permissionsGranted = true);

    if (mounted) {
      final contactsProvider = Provider.of<ContactsProvider>(
        context,
        listen: false,
      );
      await contactsProvider.loadContacts();
    }
  }

  void _showPermissionDeniedDialog() {
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A2A),
        title: const Text(
          'Permissions Required',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Pro Dialer needs Phone, Contacts, and Microphone permissions to function properly. Please grant these permissions in Settings.',
          style: TextStyle(color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _checkAndRequestPermissions();
            },
            child: const Text(
              'Try Again',
              style: TextStyle(color: Color(0xFF10B981)),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              await openAppSettings();
              if (mounted) {
                if (!context.mounted) return;
                Navigator.pop(context);
                _checkAndRequestPermissions();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
            ),
            child: const Text(
              'Open Settings',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // ✅ SHOW LOADING DURING CHECKS
    if (_isCheckingPermissions) {
      return Scaffold(
        backgroundColor: const Color(0xFF121212),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(color: Color(0xFF10B981)),
              const SizedBox(height: 24),
              Text(
                'Checking permissions...',
                style: const TextStyle(color: Colors.grey, fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }

    // ✅ SHOW PERMISSION DENIED STATE
    if (!_permissionsGranted) {
      return Scaffold(
        backgroundColor: const Color(0xFF121212),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                size: 80,
                color: Colors.orange,
              ),
              const SizedBox(height: 24),
              const Text(
                'Permissions Required',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 40),
                child: Text(
                  'Please grant all required permissions to use Pro Dialer',
                  style: TextStyle(color: Colors.grey, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _checkAndRequestPermissions,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                ),
                child: const Text(
                  'Grant Permissions',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // ✅ NORMAL APP UI
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() => _currentIndex = index);
        },
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() => _currentIndex = index);
          _pageController.animateToPage(
            index,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: const Color(0xFF1E1E1E),
        selectedItemColor: const Color(0xFF10B981),
        unselectedItemColor: Colors.grey,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dialpad), label: 'Keypad'),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'Recent'),
          BottomNavigationBarItem(
            icon: Icon(Icons.contacts),
            label: 'Contacts',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
