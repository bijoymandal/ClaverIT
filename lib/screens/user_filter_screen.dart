import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/contacts_provider.dart';

class UserFilterScreen extends StatefulWidget {
  const UserFilterScreen({super.key});

  @override
  State<UserFilterScreen> createState() => _UserFilterScreenState();
}

class _UserFilterScreenState extends State<UserFilterScreen> {
  final Map<String, TextEditingController> _controllers = {
    'name': TextEditingController(),
    'location': TextEditingController(),
    'profession': TextEditingController(),
    'company': TextEditingController(),
    'email': TextEditingController(),
  };

  final Map<String, bool> _isExpanded = {
    'name': true,
    'location': true,
    'profession': true,
    'company': true,
    'email': true,
  };

  @override
  void dispose() {
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _clearAll() {
    setState(() {
      for (var controller in _controllers.values) {
        controller.clear();
      }
    });
  }

  void _applyFilters() {
    final filters = _controllers.map((key, controller) => MapEntry(key, controller.text));
    Provider.of<ContactsProvider>(context, listen: false).searchUsersInBackend(filters);
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Search Contacts',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFF1C1C1E),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const TextField(
                style: TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  icon: Icon(Icons.search, color: Colors.grey),
                  hintText: 'Search contacts...',
                  hintStyle: TextStyle(color: Colors.grey),
                  border: InputBorder.none,
                ),
              ),
            ),
          ),

          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                _buildFilterChip('All Filters', true),
                const SizedBox(width: 12),
                _buildFilterChip('Name', false),
                const SizedBox(width: 12),
                _buildFilterChip('Location', false),
                const SizedBox(width: 12),
                _buildFilterChip('Company', false),
              ],
            ),
          ),

          // Filters List
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _buildFilterSection(
                  'Name',
                  Icons.person,
                  _controllers['name']!,
                  'Enter name',
                  'name',
                ),
                _buildFilterSection(
                  'Location',
                  Icons.location_on,
                  _controllers['location']!,
                  'Enter location',
                  'location',
                ),
                _buildFilterSection(
                  'Profession',
                  Icons.business_center,
                  _controllers['profession']!,
                  'Enter profession',
                  'profession',
                ),
                _buildFilterSection(
                  'Company',
                  Icons.business,
                  _controllers['company']!,
                  'Enter company name',
                  'company',
                ),
                _buildFilterSection(
                  'Email',
                  Icons.email,
                  _controllers['email']!,
                  'Enter email',
                  'email',
                ),
                const SizedBox(height: 100), // Space for buttons
              ],
            ),
          ),
        ],
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.all(20),
        color: Colors.black,
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: _clearAll,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2C2C2E),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Clear All'),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton(
                onPressed: _applyFilters,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Apply Filters'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFF10B981) : const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : Colors.grey,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildFilterSection(
    String title,
    IconData icon,
    TextEditingController controller,
    String hint,
    String key,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          ListTile(
            onTap: () {
              setState(() {
                _isExpanded[key] = !_isExpanded[key]!;
              });
            },
            leading: Icon(icon, color: const Color(0xFF10B981)),
            title: Text(
              title,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            trailing: Icon(
              _isExpanded[key]! ? Icons.expand_less : Icons.expand_more,
              color: Colors.grey,
            ),
          ),
          if (_isExpanded[key]!)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFF2C2C2E),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TextField(
                  controller: controller,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: hint,
                    hintStyle: TextStyle(color: Colors.grey.withValues(alpha: 0.5)),
                    border: InputBorder.none,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
