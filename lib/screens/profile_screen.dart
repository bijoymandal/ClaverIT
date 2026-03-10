import 'package:claverit/screens/chat_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/my_profile.dart';
import '../providers/user_provider.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';
import 'schedule_meeting_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<UserProvider>(context, listen: false).loadUserData();
    });
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A2A),
        title: const Text('Logout', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Are you sure you want to logout?',
          style: TextStyle(color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Logout', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _authService.logout();
        if (mounted) {
          Provider.of<UserProvider>(context, listen: false).clearData();
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const PhoneInputScreen()),
            (route) => false,
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Logout failed: $e')));
        }
      }
    }
  }

  Future<void> _showEditProfileDialog() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final profile = userProvider.profile;

    final nameController = TextEditingController(text: profile?.name ?? '');
    final designationController = TextEditingController(
      text: profile?.designation ?? '',
    );
    final organizationController = TextEditingController(
      text: profile?.organization ?? '',
    );
    final phoneController = TextEditingController(
      text: profile?.phoneNumber ?? '',
    );

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A2A),
        title: const Text(
          'Edit Profile',
          style: TextStyle(color: Colors.white),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildTextField(nameController, 'Name', Icons.person),
              const SizedBox(height: 12),
              _buildTextField(
                phoneController,
                'Phone Number',
                Icons.phone,
                keyboardType: TextInputType.phone,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
              const SizedBox(height: 12),
              _buildTextField(designationController, 'Designation', Icons.work),
              const SizedBox(height: 12),
              _buildTextField(
                organizationController,
                'Organization',
                Icons.business,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00BFA5),
            ),
            onPressed: () async {
              try {
                final updatedData = {
                  'fullName': nameController.text.trim(),
                  'designation': designationController.text.trim(),
                  'organization': organizationController.text.trim(),
                  'phone': phoneController.text.trim(),
                };

                await userProvider.updateProfile(updatedData);

                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Profile updated successfully'),
                      backgroundColor: Color(0xFF00BFA5),
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Update failed: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon, {
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.grey),
        prefixIcon: Icon(icon, color: const Color(0xFF00BFA5)),
        filled: true,
        fillColor: const Color(0xFF1A1A1A),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _logout,
            icon: const Icon(Icons.logout, color: Colors.white),
          ),
        ],
      ),
      body: SafeArea(
        child: Consumer<UserProvider>(
          builder: (context, userProvider, child) {
            if (userProvider.isLoading && userProvider.profile == null) {
              return const Center(
                child: CircularProgressIndicator(color: Color(0xFF10B981)),
              );
            }

            final profile = userProvider.profile;
            if (profile == null) {
              return const Center(
                child: Text(
                  'Failed to load profile',
                  style: TextStyle(color: Colors.white),
                ),
              );
            }

            return SingleChildScrollView(
              child: Column(
                children: [
                  _buildProfileHeader(userProvider),
                  const SizedBox(height: 20),
                  _buildContactInfoSection(profile),
                  _buildSectionGap(),
                  _buildAppointmentSection(),
                  _buildSectionGap(),
                  _buildShareContactSection(userProvider),
                  _buildSectionGap(),
                  _buildReferralSection(userProvider),
                  const SizedBox(height: 40),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSectionGap() => const SizedBox(height: 16);

  // Widget _buildProfileHeader(UserProvider userProvider) {
  //   final profile = userProvider.profile!;
  //   return Column(
  //     children: [
  //       Stack(
  //         clipBehavior: Clip.none,
  //         alignment: Alignment.bottomCenter,
  //         children: [
  //           // Banner
  //           Container(
  //             height: 120,
  //             width: double.infinity,
  //             decoration: const BoxDecoration(color: Color(0xFF2A2A2A)),
  //             child: Container(
  //               decoration: BoxDecoration(
  //                 gradient: LinearGradient(
  //                   begin: Alignment.topCenter,
  //                   end: Alignment.bottomCenter,
  //                   colors: [Colors.transparent, Colors.black.withValues(alpha: 0.7)],
  //                 ),
  //               ),
  //             ),
  //           ),
  //           // Avatar
  //           Positioned(
  //             bottom: -40,
  //             left: 24,
  //             child: Container(
  //               padding: const EdgeInsets.all(4),
  //               decoration: const BoxDecoration(
  //                 color: Colors.black,
  //                 shape: BoxShape.circle,
  //               ),
  //               child: CircleAvatar(
  //                 radius: 40,
  //                 backgroundColor: const Color(0xFF10B981),
  //                 child: Text(
  //                   userProvider.initials,
  //                   style: const TextStyle(
  //                     color: Colors.white,
  //                     fontSize: 32,
  //                     fontWeight: FontWeight.bold,
  //                   ),
  //                 ),
  //               ),
  //             ),
  //           ),
  //           // Edit Button
  //           Positioned(
  //             top: 16,
  //             right: 16,
  //             child: Container(
  //               decoration: BoxDecoration(
  //                 color: Colors.black.withValues(alpha: 0.5),
  //                 shape: BoxShape.circle,
  //               ),
  //               child: IconButton(
  //                 icon: const Icon(Icons.edit, color: Colors.white),
  //                 onPressed: _showEditProfileDialog,
  //               ),
  //             ),
  //           ),
  //         ],
  //       ),
  //       const SizedBox(height: 50),

  //       // Name & Role
  //       Padding(
  //         padding: const EdgeInsets.symmetric(horizontal: 24),
  //         child: Column(
  //           crossAxisAlignment: CrossAxisAlignment.start,
  //           children: [
  //             Text(
  //               profile.name,
  //               style: const TextStyle(
  //                 color: Colors.white,
  //                 fontSize: 22,
  //                 fontWeight: FontWeight.bold,
  //               ),
  //             ),
  //             const SizedBox(height: 4),
  //             if (profile.designation.isNotEmpty)
  //               Text(
  //                 profile.designation,
  //                 style: const TextStyle(
  //                   color: Color(0xFF10B981),
  //                   fontSize: 16,
  //                   fontWeight: FontWeight.w600,
  //                 ),
  //               ),
  //             if (profile.organization.isNotEmpty)
  //               Text(
  //                 profile.organization,
  //                 style: const TextStyle(color: Colors.grey, fontSize: 14),
  //               ),
  //             const SizedBox(height: 24),
  //           ],
  //         ),
  //       ),
  //     ],
  //   );
  // }

  Widget _buildProfileHeader(UserProvider userProvider) {
    final profile = userProvider.profile!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            // Banner Image
            Container(
              height: 180,
              width: double.infinity,
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage("assets/images/profile_background.png"),
                  fit: BoxFit.cover,
                ),
              ),
            ),

            // Dark gradient overlay
            Container(
              height: 180,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black.withOpacity(0.7)],
                ),
              ),
            ),

            // Edit Button
            Positioned(
              top: 40,
              right: 16,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(Icons.edit, color: Colors.white),
                  onPressed: _showEditProfileDialog,
                ),
              ),
            ),

            // Chat Button
            Positioned(
              right: 16,
              bottom: -24,
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF10B981).withOpacity(0.6),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: IconButton(
                  icon: const Icon(
                    Icons.chat_bubble_outline,
                    color: Colors.white,
                  ),
                  onPressed: () {
                    // add chat action
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ChatScreen(),
                      ),
                    );
                  },
                ),
              ),
            ),

            // Avatar
            Positioned(
              left: 24,
              bottom: -50,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.black,
                  shape: BoxShape.circle,
                ),
                child: CircleAvatar(
                  radius: 50,
                  backgroundColor: const Color(0xFF10B981),
                  child: Text(
                    userProvider.initials,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 34,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 60),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Name
              Text(
                profile.name,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),

              const SizedBox(height: 6),

              // Designation
              if (profile.designation.isNotEmpty)
                Text(
                  profile.designation,
                  style: const TextStyle(
                    fontSize: 18,
                    color: Color(0xFF10B981),
                    fontWeight: FontWeight.w600,
                  ),
                ),

              const SizedBox(height: 4),

              // Organization
              if (profile.organization.isNotEmpty)
                Text(
                  profile.organization,
                  style: const TextStyle(color: Colors.grey, fontSize: 15),
                ),

              const SizedBox(height: 20),

              // Add to Contact Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(40),
                    ),
                  ),
                  child: const Text(
                    "Add to Contacts",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildContactInfoSection(MyProfile profile) {
    return _buildCard(
      title: 'Contact Information',
      children: [
        _buildContactRow(Icons.phone, profile.phoneNumber, 'Primary'),
        if (profile.location.isNotEmpty)
          _buildContactRow(Icons.location_on, profile.location, 'Location'),
      ],
    );
  }

  Widget _buildAppointmentSection() {
    return _buildCard(
      title: 'Make an Appointment',
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const ScheduleMeetingScreen(),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: const Text(
              'Schedule Meeting',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildShareContactSection(UserProvider userProvider) {
    final qrData = userProvider.qrData;
    final String? qrImageData = qrData?['qrCodeImageData'];

    return _buildCard(
      title: 'Share Contact',
      children: [
        Center(
          child: Column(
            children: [
              if (qrImageData != null)
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Image.memory(
                    Uri.parse(qrImageData).data!.contentAsBytes(),
                    width: 200,
                    height: 200,
                    errorBuilder: (context, error, stackTrace) => const Icon(
                      Icons.qr_code_2,
                      size: 100,
                      color: Colors.black,
                    ),
                  ),
                )
              else
                const Icon(Icons.qr_code_2, size: 100, color: Colors.white),
              const SizedBox(height: 8),
              const Text(
                'Scan to save contact',
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildReferralSection(UserProvider userProvider) {
    final referralLink =
        userProvider.qrData?['referralLink'] ?? 'nighatech.com/ref';

    return _buildCard(
      title: 'Refer a Friend',
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFF2C2C2E),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  referralLink,
                  style: const TextStyle(color: Colors.grey),
                ),
              ),
              IconButton(
                icon: const Icon(
                  Icons.copy,
                  size: 16,
                  color: Color(0xFF10B981),
                ),
                onPressed: () {
                  // Implement copy to clipboard
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Helper Widgets
  Widget _buildCard({required String title, required List<Widget> children}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }

  Widget _buildContactRow(
    IconData icon,
    String title,
    String subtitle, {
    IconData? trailingIcon,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF2C2C2E),
              borderRadius: BorderRadius.circular(50),
            ),
            child: Icon(
              icon,
              color: subtitle == 'Primary'
                  ? const Color(0xFF10B981)
                  : Colors.blue,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),
          if (trailingIcon != null)
            Icon(trailingIcon, color: Colors.white, size: 20),
        ],
      ),
    );
  }
}
