import 'package:claverit/services/sim_service.dart';
import 'package:flutter/material.dart';
import 'package:call_log/call_log.dart' as call_log_package;
import 'package:permission_handler/permission_handler.dart';
import '../models/call_log_entry.dart';
import '../services/native_call_service.dart';
import '../utils/color_utils.dart';

import '../widgets/app_drawer.dart';
import '../models/my_profile.dart';
import 'profile_screen.dart';
import 'login_screen.dart';

class RecentScreen extends StatefulWidget {
  const RecentScreen({super.key});

  @override
  State<RecentScreen> createState() => _RecentScreenState();
}

class _RecentScreenState extends State<RecentScreen>
    with AutomaticKeepAliveClientMixin {
  List<CallLogEntry> _callLogs = [];
  List<String> _simNames = [];
  bool _isLoading = true;
  bool _permissionDenied = false;
  String _selectedSimFilter = 'Both';
  String _selectedCallType = 'All';
  String? _error;
  bool _permissionGranted = false;

  // Search State
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadCallLogs();
    _loadSimNames();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadSimNames() async {
    try {
      final status = await Permission.phone.request();

      if (!status.isGranted) return;

      final sims = await SimService.getSimProviders();

      setState(() {
        _simNames = sims;
      });
    } catch (e) {
      debugPrint("SIM load error: $e");
    }
  }

  List<CallLogEntry> get _filteredLogs {
    List<CallLogEntry> logs = _callLogs;

    /// SIM FILTER
    if (_selectedSimFilter.isNotEmpty) {
      // Normalize label (strip counts like 'SIM1 (3)' or 'CarrierName (2)')
      final filterLabel = _selectedSimFilter.split('(').first.trim();
      if (filterLabel != 'Both') {
        if (filterLabel.startsWith('SIM')) {
          final slot = int.tryParse(filterLabel.replaceAll('SIM', '')) ?? 0;
          logs = logs.where((log) => log.simSlot == slot).toList();
        } else {
          // Match by sim display name
          logs = logs
              .where(
                (log) => (log.simDisplayName ?? '').toLowerCase().contains(
                  filterLabel.toLowerCase(),
                ),
              )
              .toList();
        }
      }
    }

    /// CALL TYPE FILTER
    if (_selectedCallType != 'All') {
      logs = logs.where((log) {
        switch (_selectedCallType) {
          case 'Missed':
            return log.callType == CallType.missed;

          case 'Received':
            return log.callType == CallType.incoming;

          case 'Outgoing':
            return log.callType == CallType.outgoing;

          case 'Rejected':
            return log.callType == CallType.rejected;

          default:
            return true;
        }
      }).toList();
    }

    /// SEARCH
    if (_searchQuery.isNotEmpty) {
      logs = logs.where((log) {
        final name = log.displayName.toLowerCase();
        final number = (log.number ?? '').replaceAll(RegExp(r'\D'), '');

        return name.contains(_searchQuery.toLowerCase()) ||
            number.contains(_searchQuery);
      }).toList();
    }

    return logs;
  }

  Future<void> _loadCallLogs() async {
    setState(() {
      _isLoading = true;
      _permissionDenied = false;
      _error = null;
    });

    try {
      // Request phone and contacts permissions to ensure READ_CALL_LOG access
      final statuses = await [Permission.phone, Permission.contacts].request();
      final phoneGranted = statuses[Permission.phone]?.isGranted ?? false;
      final contactsGranted = statuses[Permission.contacts]?.isGranted ?? false;

      if (!phoneGranted) {
        setState(() {
          _permissionDenied = true;
          _permissionGranted = false;
          _isLoading = false;
          _error = 'Phone permission required to read call history';
        });
        return;
      }

      setState(() {
        _permissionGranted = true;
      });

      final Iterable<call_log_package.CallLogEntry> entries =
          await call_log_package.CallLog.get();

      final List<CallLogEntry> logs =
          entries.map((entry) => CallLogEntry.fromCallLog(entry)).toList()
            ..sort((a, b) => (b.timestamp ?? 0).compareTo(a.timestamp ?? 0));

      setState(() {
        _callLogs = logs;
        _permissionDenied = false;
        _isLoading = false;
      });

      debugPrint('Loaded ${logs.length} call log entries');
    } catch (e) {
      debugPrint('Error loading call logs: $e');
      setState(() {
        _error = 'Failed to load call history: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _makeCall(String? phoneNumber) async {
    if (phoneNumber == null || phoneNumber.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid phone number'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      await NativeCallService().startCall(
        phoneNumber,
        0,
      ); // Default to SIM 1 for now
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to call: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    // Diagnostic counts for SIM filtering
    final int _totalCount = _callLogs.length;
    final int _sim1Count = _callLogs.where((l) => l.simSlot == 1).length;
    final int _sim2Count = _callLogs.where((l) => l.simSlot == 2).length;
    return Scaffold(
      backgroundColor: Colors.black,
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
                  hintText: 'Search recents...',
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
                'Recents',
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
      body: Column(
        children: [
          // SIM Filter Row
          // Debug / Info Row
          // if (_isLoading == false)
          //   Padding(
          //     padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          //     child: Row(
          //       mainAxisAlignment: MainAxisAlignment.spaceBetween,
          //       children: [
          //         Text(
          //           'Entries: ${_callLogs.length}',
          //           style: const TextStyle(color: Colors.grey),
          //         ),
          //         Row(
          //           children: [
          //             Text(
          //               'Permission: ${_permissionGranted ? 'Granted' : 'Denied'}',
          //               style: TextStyle(
          //                 color: _permissionGranted ? Colors.green : Colors.red,
          //               ),
          //             ),
          //             const SizedBox(width: 8),
          //             ElevatedButton(
          //               onPressed: _loadCallLogs,
          //               style: ElevatedButton.styleFrom(
          //                 backgroundColor: const Color(0xFF10B981),
          //               ),
          //               child: const Text('Refresh'),
          //             ),
          //           ],
          //         ),
          //       ],
          //     ),
          //   ),
          // Call Type Row
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _buildCallTypeChip("All"),
                _buildCallTypeChip("Missed"),
                _buildCallTypeChip("Received"),
                _buildCallTypeChip("Outgoing"),
                _buildCallTypeChip("Rejected"),
              ],
            ),
          ),

          // Call Log List
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    final bool isSelected = _selectedSimFilter == label;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedSimFilter = label;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF10B981) : const Color(0xFF1C1C1E),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected ? const Color(0xFF10B981) : Colors.grey.shade700,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildCallTypeChip(String label) {
    final isSelected = _selectedCallType == label;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedCallType = label;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF10B981) : const Color(0xFF1C1C1E),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(color: isSelected ? Colors.white : Colors.grey),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Color(0xFF10B981)),
            SizedBox(height: 16),
            Text(
              'Loading call history...',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    if (_permissionDenied) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.phone_disabled, size: 64, color: Colors.grey),
              const SizedBox(height: 24),
              const Text(
                'Call Log Permission Required',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              const Text(
                'ClaverIT needs permission to access your call history to display recent calls.',
                style: TextStyle(color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () async {
                  await openAppSettings();
                  if (mounted) {
                    _loadCallLogs();
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                ),
                child: const Text(
                  'Grant Permission',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 24),
              Text(
                _error!,
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _loadCallLogs,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                ),
                child: const Text(
                  'Retry',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final logs = _filteredLogs;

    if (logs.isEmpty) {
      if (_isSearching) {
        return const Center(
          child: Text(
            'No results found',
            style: TextStyle(color: Colors.grey, fontSize: 16),
          ),
        );
      }
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.phone_disabled, size: 64, color: Colors.grey),
            SizedBox(height: 24),
            Text(
              'No recent calls',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Your recent calls will appear here',
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: logs.length,
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemBuilder: (context, index) {
        final log = logs[index];
        // ✅ Wrap with Dismissible for swipe-to-delete
        return _buildDismissibleCallLogItem(log, index);
      },
    );
  }

  // ✅ NEW: Dismissible wrapper with confirmation
  Widget _buildDismissibleCallLogItem(CallLogEntry log, int index) {
    return Dismissible(
      key: Key(
        '${log.number}_${log.timestamp}',
      ), // Unique key using number and timestamp
      direction: DismissDirection.endToStart, // Swipe left only
      // ✅ Confirmation dialog before dismissal
      confirmDismiss: (direction) async {
        return await showDialog<bool>(
              context: context,
              barrierDismissible: false,
              builder: (context) => AlertDialog(
                backgroundColor: const Color(0xFF2A2A2A),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                title: const Row(
                  children: [
                    Icon(Icons.delete_outline, color: Colors.orange, size: 28),
                    SizedBox(width: 12),
                    Text(
                      'Clear Call Log?',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Are you sure you want to remove this call from the history?',
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E1E1E),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(log.icon, color: log.color, size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  log.displayName,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Text(
                                  '${log.formattedDate} • ${log.formattedDuration}',
                                  style: TextStyle(
                                    color: Colors.grey.withValues(alpha: 0.7),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () =>
                        Navigator.pop(context, false), // Don't delete
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                    ),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () =>
                        Navigator.pop(context, true), // Confirm delete
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.delete_forever, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Clear',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ) ??
            false; // Return false if dialog dismissed
      },
      // ✅ Swipe background (Red with delete icon)
      background: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.delete_sweep, color: Colors.white, size: 32),
            SizedBox(height: 4),
            Text(
              'Clear',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
      // ✅ On dismissed (after confirmation)
      onDismissed: (direction) {
        _deleteLogEntry(index, log);
      },
      // ✅ The actual call log item
      child: _buildCallLogItem(log, index),
    );
  }

  void _deleteLogEntry(int index, CallLogEntry log) {
    // Remove from local list
    setState(() {
      _callLogs.removeAt(index);
    });

    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            Text('Call log cleared for ${log.displayName}'),
          ],
        ),
        backgroundColor: const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        action: SnackBarAction(
          label: 'UNDO',
          textColor: Colors.white,
          onPressed: () {
            // Restore the deleted item
            setState(() {
              _callLogs.insert(index, log);
            });
          },
        ),
      ),
    );

    // TODO: If you have a local database for call logs, delete from there too
    // Example: await _callHistoryProvider.deleteCallLog(log.id);
  }

  void _showOptionsBottomSheet(CallLogEntry log, int index) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF2A2A2A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey[600],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.block, color: Colors.red),
            title: const Text(
              'Block Number',
              style: TextStyle(color: Colors.white),
            ),
            onTap: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Number added to block list (Simulated)'),
                  backgroundColor: Colors.red,
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.report_problem, color: Colors.orange),
            title: const Text(
              'Report Spam',
              style: TextStyle(color: Colors.white),
            ),
            onTap: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Number reported as spam'),
                  backgroundColor: Colors.orange,
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete, color: Colors.white),
            title: const Text(
              'Delete Log',
              style: TextStyle(color: Colors.white),
            ),
            onTap: () async {
              Navigator.pop(context);
              // Show confirmation dialog before deleting
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  backgroundColor: const Color(0xFF2A2A2A),
                  title: const Text(
                    'Delete Log?',
                    style: TextStyle(color: Colors.white),
                  ),
                  content: const Text(
                    'Are you sure you want to delete this call log?',
                    style: TextStyle(color: Colors.white70),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text(
                        'Delete',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              );

              if (confirm == true) {
                _deleteLogEntry(index, log);
              }
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildCallLogItem(CallLogEntry log, int index) {
    // Generate a gradient based on the name
    final gradient = ColorUtils.getAvatarGradient(log.displayName);
    // Count how many times this number appears in the current filtered logs
    final int callCount = _filteredLogs.where((l) {
      final a = (l.number ?? '').replaceAll(RegExp(r'\D'), '');
      final b = (log.number ?? '').replaceAll(RegExp(r'\D'), '');
      if (a.isNotEmpty && b.isNotEmpty) return a == b;
      return l.displayName == log.displayName;
    }).length;

    final String displayNameWithCount = callCount > 1
        ? '${log.displayName} (${callCount})'
        : log.displayName;

    return InkWell(
      onLongPress: () => _showOptionsBottomSheet(log, index),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF1C1C1E),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          children: [
            // Avatar (tap to view profile or prompt to register)
            GestureDetector(
              onTap: () => _onAvatarTap(log),
              child: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  gradient: gradient,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  _getInitials(log.displayName),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayNameWithCount,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(log.icon, size: 16, color: log.color),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          '• ${log.formattedDate} • SIM${log.simSlot} ${log.simDisplayName ?? ''}',
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 13,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Call Button
            IconButton(
              icon: const Icon(Icons.phone, color: Color(0xFF10B981), size: 24),
              onPressed: () => _makeCall(log.number),
              tooltip: 'Call',
            ),
          ],
        ),
      ),
    );
  }

  String _getInitials(String name) {
    if (name.isEmpty) return '?';
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name[0].toUpperCase();
  }

  Future<void> _onAvatarTap(CallLogEntry log) async {
    try {
      final profile = await MyProfile.load();
      final bool registered =
          (profile.name.isNotEmpty || profile.phoneNumber.isNotEmpty);

      if (registered) {
        if (!mounted) return;
        Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (context) => const ProfileScreen()));
      } else {
        if (!mounted) return;
        // Not registered - prompt to register / login
        final goToRegister = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: const Color(0xFF2A2A2A),
            title: const Text(
              'Not Registered',
              style: TextStyle(color: Colors.white),
            ),
            content: const Text(
              'This app profile is not set up. Would you like to register or login now?',
              style: TextStyle(color: Colors.white70),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                ),
                onPressed: () => Navigator.pop(context, true),
                child: const Text(
                  'Register',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        );

        if (goToRegister == true) {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const PhoneInputScreen()),
          );
        }
      }
    } catch (e) {
      debugPrint('Error checking profile: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to open profile'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
