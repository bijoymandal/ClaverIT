import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/contact.dart';
import '../providers/contacts_provider.dart';

class AddContactScreen extends StatefulWidget {
  final Contact? existingContact;

  const AddContactScreen({super.key, this.existingContact});

  @override
  State<AddContactScreen> createState() => _AddContactScreenState();
}

class _AddContactScreenState extends State<AddContactScreen> {
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _companyController;
  late TextEditingController _titleController;
  late TextEditingController _emailController;

  // Extra fields (hidden by default)
  bool _showExtraFields = false;
  late TextEditingController _locationController;
  late TextEditingController _noteController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.existingContact?.name ?? '',
    );
    _phoneController = TextEditingController(
      text: widget.existingContact?.phoneNumber ?? '',
    );
    _companyController = TextEditingController(
      text: widget.existingContact?.organization ?? '',
    );
    _titleController = TextEditingController(
      text: widget.existingContact?.designation ?? '',
    );
    _emailController = TextEditingController(
      text: widget.existingContact?.email ?? '',
    );
    _locationController = TextEditingController(
      text: widget.existingContact?.location ?? '',
    );
    _noteController = TextEditingController(
      text: widget.existingContact?.note ?? '',
    );

    // If editing a contact with extra fields populated, show them by default
    if (widget.existingContact != null) {
      if (_locationController.text.isNotEmpty ||
          _noteController.text.isNotEmpty) {
        _showExtraFields = true;
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _companyController.dispose();
    _titleController.dispose();
    _emailController.dispose();
    _locationController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _saveContact() async {
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();

    if (name.isEmpty || phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Name and Phone Number are required'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final newContact = Contact(
      id: widget.existingContact?.id,
      name: name,
      phoneNumber: phone,
      organization: _companyController.text.trim(),
      designation: _titleController.text.trim(),
      email: _emailController.text.trim(),
      location: _locationController.text.trim(),
      note: _noteController.text.trim(),
      profileImagePath: widget.existingContact?.profileImagePath ?? '',
    );

    final provider = Provider.of<ContactsProvider>(context, listen: false);

    bool success;
    if (widget.existingContact != null) {
      success = await provider.updateContact(newContact);
    } else {
      success = await provider.addContact(newContact);
    }

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.existingContact != null
                  ? 'Contact updated'
                  : 'Contact saved',
            ),
            backgroundColor: const Color(0xFF10B981),
          ),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${provider.error}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.existingContact != null ? 'Edit Contact' : 'Create Contact',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.check, color: Color(0xFF10B981)),
            onPressed: _saveContact,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Avatar Placeholder (Optional, can be expanded later)
            Center(
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: const Color(0xFF1C1C1E),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.grey.shade800),
                ),
                child: const Icon(
                  Icons.add_a_photo_outlined,
                  color: Colors.grey,
                  size: 30,
                ),
              ),
            ),
            const SizedBox(height: 30),

            _buildTextField(
              controller: _nameController,
              label: 'Name',
              icon: Icons.person_outline,
              inputType: TextInputType.name,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _companyController,
              label: 'Company',
              icon: Icons.business_outlined,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _titleController,
              label: 'Title',
              icon: Icons.work_outline,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _phoneController,
              label: 'Mobile',
              icon: Icons.phone_outlined,
              inputType: TextInputType.phone,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _emailController,
              label: 'Email',
              icon: Icons.email_outlined,
              inputType: TextInputType.emailAddress,
            ),

            // Add another field option
            if (!_showExtraFields) ...[
              const SizedBox(height: 24),
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    _showExtraFields = true;
                  });
                },
                icon: const Icon(
                  Icons.add_circle_outline,
                  color: Color(0xFF10B981),
                ),
                label: const Text(
                  'Add another field',
                  style: TextStyle(color: Color(0xFF10B981), fontSize: 16),
                ),
              ),
            ] else ...[
              const SizedBox(height: 16),
              _buildTextField(
                controller: _locationController,
                label: 'Location',
                icon: Icons.location_on_outlined,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _noteController,
                label: 'Note',
                icon: Icons.note_outlined,
                maxLines: 3,
              ),
            ],

            // Extra spacing at bottom
            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType inputType = TextInputType.text,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      keyboardType: inputType,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white, fontSize: 16),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.grey),
        prefixIcon: Icon(icon, color: Colors.grey),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade800),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF10B981), width: 2),
        ),
        filled: true,
        fillColor: const Color(0xFF1C1C1E),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
    );
  }
}
