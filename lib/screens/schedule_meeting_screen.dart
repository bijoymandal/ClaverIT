import 'package:flutter/material.dart';
import '../services/event_service.dart';

class ScheduleMeetingScreen extends StatefulWidget {
  const ScheduleMeetingScreen({super.key});

  @override
  State<ScheduleMeetingScreen> createState() => _ScheduleMeetingScreenState();
}

class _ScheduleMeetingScreenState extends State<ScheduleMeetingScreen> {
  final TextEditingController _notesController = TextEditingController();
  final EventService _eventService = EventService();

  final List<Map<String, dynamic>> _meetingTypes = [
    {
      'title': 'Video Consultation',
      'subtitle': '30 minutes',
      'duration': 30,
      'icon': Icons.videocam,
      'location': 'Video call',
    },
    {
      'title': 'In-Person Visit',
      'subtitle': '45 minutes',
      'duration': 45,
      'icon': Icons.business_center,
      'location': 'In-person',
    },
    {
      'title': 'Phone Call',
      'subtitle': '20 minutes',
      'duration': 20,
      'icon': Icons.phone,
      'location': 'Phone call',
    },
  ];

  List<Map<String, dynamic>> _timeSlots = [];

  int _selectedMeetingIndex = 1;
  final DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDate;
  int? _selectedTimeIndex;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _generateTimeSlots();
  }

  void _generateTimeSlots() {
    _timeSlots = [];
    // Generate slots from 9:00 AM to 6:00 PM in 30-minute intervals
    for (int hour = 9; hour <= 18; hour++) {
      for (int minute in [0, 30]) {
        if (hour == 18 && minute > 0) break; // Stop at 6:00 PM

        String period = hour >= 12 ? 'PM' : 'AM';
        int displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
        String label = '${displayHour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')} $period';

        _timeSlots.add({
          'label': label,
          'hour': hour,
          'minute': minute,
          'enabled': true,
        });
      }
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submitAppointment() async {
    if (_selectedDate == null || _selectedTimeIndex == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select date and time')),
      );
      return;
    }

    final slot = _timeSlots[_selectedTimeIndex!];
    if (slot['enabled'] == false) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selected time is not available')),
      );
      return;
    }

    final meeting = _meetingTypes[_selectedMeetingIndex];
    final DateTime startTime = DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
      slot['hour'] as int,
      slot['minute'] as int,
    );
    final DateTime endTime = startTime.add(
      Duration(minutes: meeting['duration'] as int),
    );

    final payload = {
      'title': meeting['title'] as String,
      'description': _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
      'eventType': 'health',
      'visibility': 'private',
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'allDay': false,
      'location': meeting['location'] as String,
      'color': '#10B981',
    };

    setState(() {
      _isSubmitting = true;
    });

    try {
      await _eventService.createEvent(payload);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Appointment scheduled successfully')),
      );

      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to schedule meeting: $e')));
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
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
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Schedule Meeting',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: RepaintBoundary(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 160,
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF00C853), Color(0xFF1DE9B6)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 16),
                    const Icon(
                      Icons.event_available,
                      color: Colors.white,
                      size: 64,
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Text(
                        'SCHEDULE MEETING',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              _buildMeetingTypeCard(),
              const SizedBox(height: 24),
              const Text(
                'Select Date',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF1C1C1E),
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.all(8),
                child: CalendarDatePicker(
                  initialDate: _selectedDate ?? DateTime.now(),
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                  currentDate: _focusedDay,
                  onDateChanged: (date) {
                    setState(() {
                      _selectedDate = date;
                    });
                  },
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Select Time',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  childAspectRatio: 2.5,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemCount: _timeSlots.length,
                itemBuilder: (context, index) {
                  final slot = _timeSlots[index];
                  final bool isSelected = _selectedTimeIndex == index;
                  final bool isEnabled = slot['enabled'] as bool;

                  return InkWell(
                    onTap: isEnabled
                        ? () {
                            setState(() {
                              _selectedTimeIndex = index;
                            });
                          }
                        : null,
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFF10B981)
                            : isEnabled
                            ? const Color(0xFF1C1C1E)
                            : Colors.grey.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFF10B981)
                              : Colors.grey.shade800,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        slot['label'] as String,
                        style: TextStyle(
                          color: isSelected
                              ? Colors.white
                              : isEnabled
                              ? Colors.white
                              : Colors.grey,
                          fontWeight: isSelected ? FontWeight.bold : null,
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),
              const Text(
                'Additional Notes',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _notesController,
                maxLines: 4,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Add any special requests or information...',
                  hintStyle: const TextStyle(color: Colors.grey),
                  filled: true,
                  fillColor: const Color(0xFF1C1C1E),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade800),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF10B981)),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitAppointment,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : const Text(
                          'Confirm Appointment',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMeetingTypeCard() {
    return Column(
      children: List.generate(_meetingTypes.length, (index) {
        final meeting = _meetingTypes[index];
        final bool isSelected = _selectedMeetingIndex == index;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF1C1C1E),
            borderRadius: BorderRadius.circular(16),
          ),
          child: ListTile(
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                meeting['icon'] as IconData,
                color: const Color(0xFF10B981),
              ),
            ),
            title: Text(
              meeting['title'] as String,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Text(
              meeting['subtitle'] as String,
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
            trailing: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? const Color(0xFF10B981) : Colors.grey,
                ),
              ),
              child: Center(
                child: Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected
                        ? const Color(0xFF10B981)
                        : Colors.transparent,
                  ),
                ),
              ),
            ),
            onTap: () {
              setState(() {
                _selectedMeetingIndex = index;
              });
            },
          ),
        );
      }),
    );
  }
}

