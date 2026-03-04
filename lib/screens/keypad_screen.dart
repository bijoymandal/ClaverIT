import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/contacts_provider.dart';
import '../services/native_call_service.dart';

import '../widgets/app_drawer.dart';

class KeypadScreen extends StatefulWidget {
  const KeypadScreen({super.key});

  @override
  State<KeypadScreen> createState() => _KeypadScreenState();
}

class _KeypadScreenState extends State<KeypadScreen>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  String _phoneNumber = '';
  late AnimationController _cursorController;
  bool _showCursor = true;

  @override
  bool get wantKeepAlive => true;

  // Search State
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // Keypad button configuration with alphabets
  final List<Map<String, String>> _keypadButtons = [
    {'number': '1', 'letters': ''},
    {'number': '2', 'letters': 'ABC'},
    {'number': '3', 'letters': 'DEF'},
    {'number': '4', 'letters': 'GHI'},
    {'number': '5', 'letters': 'JKL'},
    {'number': '6', 'letters': 'MNO'},
    {'number': '7', 'letters': 'PQRS'},
    {'number': '8', 'letters': 'TUV'},
    {'number': '9', 'letters': 'WXYZ'},
    {'number': '*', 'letters': ''},
    {'number': '0', 'letters': '+'},
    {'number': '#', 'letters': ''},
  ];

  @override
  void initState() {
    super.initState();
    _cursorController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..repeat(reverse: true);

    _cursorController.addListener(() {
      if (mounted) {
        setState(() {
          _showCursor = _cursorController.value > 0.5;
        });
      }
    });
  }

  @override
  void dispose() {
    _cursorController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onKeypadPressed(String value) {
    setState(() {
      _phoneNumber += value;
    });
  }

  void _onBackspace() {
    if (_phoneNumber.isNotEmpty) {
      setState(() {
        _phoneNumber = _phoneNumber.substring(0, _phoneNumber.length - 1);
      });
    }
  }

  Future<void> _makeCall() async {
    if (_phoneNumber.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a phone number'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      await NativeCallService().startCall(_phoneNumber);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to make call: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      backgroundColor: const Color(0xFF000000), // Pure black background
      drawer: const AppDrawer(),
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: Colors.white),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: 'Search to dial...',
                  hintStyle: TextStyle(color: Colors.grey),
                  border: InputBorder.none,
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
              )
            : const Text(
                'Keypad',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              _isSearching ? Icons.close : Icons.search,
              color: Colors.white,
            ),
            onPressed: () {
              setState(() {
                if (_isSearching) {
                  _isSearching = false;
                  _searchController.clear();
                  _searchQuery = '';
                } else {
                  _isSearching = true;
                }
              });
            },
          ),
        ],
      ),
      body: _isSearching
          ? _buildSearchResults()
          : Stack(
              children: [
                Column(
                  children: [
                    // Recent Contacts Section
                    Expanded(child: _buildRecentContactsList()),

                    // Spacer for Keypad
                    SizedBox(height: MediaQuery.of(context).size.height * 0.55),
                  ],
                ),

                // Keypad Overlay
                Positioned(bottom: 0, left: 0, right: 0, child: _buildKeypad()),
              ],
            ),
    );
  }

  Widget _buildSearchResults() {
    return Consumer<ContactsProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFF10B981)),
          );
        }

        var contacts = provider.contacts;
        if (_searchQuery.isNotEmpty) {
          contacts = contacts.where((contact) {
            final name = contact.name.toLowerCase();
            final number = contact.phoneNumber.replaceAll(RegExp(r'\D'), '');
            final query = _searchQuery.toLowerCase();
            return name.contains(query) || number.contains(query);
          }).toList();
        }

        if (contacts.isEmpty) {
          return const Center(
            child: Text(
              'No results found',
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          itemCount: contacts.length,
          itemBuilder: (context, index) {
            final contact = contacts[index];
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF1C1C1E),
                borderRadius: BorderRadius.circular(16),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                leading: CircleAvatar(
                  radius: 22,
                  backgroundColor: const Color(0xFF10B981),
                  child: Text(
                    contact.initials,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                title: Text(
                  contact.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                subtitle: Text(
                  contact.phoneNumber,
                  style: TextStyle(
                    color: Colors.grey.withValues(alpha: 0.7),
                    fontSize: 14,
                  ),
                ),
                trailing: const Icon(Icons.call, color: Color(0xFF10B981)),
                onTap: () {
                  NativeCallService().startCall(contact.phoneNumber);
                },
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPhoneNumberDisplay() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(24),
      ),
      margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: Text(
              _phoneNumber,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.w400,
                letterSpacing: 1,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
            ),
          ),
          if (_phoneNumber.isNotEmpty && _showCursor)
            Container(
              width: 2,
              height: 28,
              color: const Color(0xFF10B981),
              margin: const EdgeInsets.only(left: 4),
            ),
        ],
      ),
    );
  }

  Widget _buildRecentContactsList() {
    return Consumer<ContactsProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFF10B981)),
          );
        }

        final contacts = provider.contacts.take(5).toList();

        if (contacts.isEmpty) {
          return Center(
            child: Text(
              'No recent calls',
              style: TextStyle(
                color: Colors.grey.withValues(alpha: 0.5),
                fontSize: 16,
              ),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: contacts.length,
          itemBuilder: (context, index) {
            final contact = contacts[index];
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF1C1C1E),
                borderRadius: BorderRadius.circular(16),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                leading: CircleAvatar(
                  radius: 22,
                  backgroundColor: const Color(0xFF10B981),
                  child: Text(
                    contact.initials,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                title: Text(
                  contact.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                subtitle: Text(
                  contact.phoneNumber,
                  style: TextStyle(
                    color: Colors.grey.withValues(alpha: 0.7),
                    fontSize: 14,
                  ),
                ),
                trailing: const Icon(Icons.call, color: Color(0xFF10B981)),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildKeypad() {
    return Container(
      padding: const EdgeInsets.only(top: 15, bottom: 15),
      decoration: const BoxDecoration(
        color: Color(0xFF1C1C1E), // Dark container for keypad
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Colors.black54,
            blurRadius: 20,
            offset: Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Phone Number Display
          if (_phoneNumber.isNotEmpty)
            _buildPhoneNumberDisplay()
          else
            const SizedBox(height: 20), // Spacer when no number
          // Keypad Grid
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 1.4,
                crossAxisSpacing: 3,
                mainAxisSpacing: 3,
              ),
              itemCount: _keypadButtons.length,
              itemBuilder: (context, index) {
                final button = _keypadButtons[index];
                return _buildSquircleKeypadButton(
                  button['number']!,
                  button['letters']!,
                );
              },
            ),
          ),

          const SizedBox(height: 20),

          // Action Buttons Row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Video Call Button (Dummy)
                _buildCircularButton(
                  icon: Icons.videocam_rounded,
                  onPressed: () {},
                  color: const Color(0xFF2C2C2E),
                  size: 40,
                ),

                // Call Button
                _buildNeonCallButton(),

                // Backspace Button
                _buildCircularButton(
                  icon: Icons.backspace_outlined,
                  onPressed: _onBackspace,
                  color: const Color(0xFF2C2C2E),
                  size: 40,
                ),
              ],
            ),
          ),
          const SizedBox(height: 2),
        ],
      ),
    );
  }

  // ✅ SQUIRCLE KEYPAD BUTTON (Rounded Rectangle)
  Widget _buildSquircleKeypadButton(String number, String letters) {
    return Material(
      color: const Color(0xFF2C2C2E), // Solid dark grey
      borderRadius: BorderRadius.circular(13),
      child: InkWell(
        borderRadius: BorderRadius.circular(13),
        onTap: () => _onKeypadPressed(number),
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(13)),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Large Number
              Text(
                number,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w400,
                  height: 1.0,
                ),
              ),
              // Small Alphabets below number
              if (letters.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 1),
                  child: Text(
                    letters,
                    style: TextStyle(
                      color: Colors.grey.withValues(alpha: 0.6),
                      fontSize: 10,
                      fontWeight: FontWeight.w400,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ✅ NEON GLOW CALL BUTTON
  Widget _buildNeonCallButton() {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFF10B981),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF10B981).withValues(alpha: 0.4),
            blurRadius: 20,
            spreadRadius: 2,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(36),
          onTap: _makeCall,
          child: const Icon(Icons.call, color: Colors.white, size: 32),
        ),
      ),
    );
  }

  // ✅ CIRCULAR BUTTON
  Widget _buildCircularButton({
    required IconData icon,
    required VoidCallback onPressed,
    required Color color,
    double size = 56,
  }) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(size / 2),
          onTap: onPressed,
          child: Icon(icon, color: Colors.white, size: 24),
        ),
      ),
    );
  }
}
