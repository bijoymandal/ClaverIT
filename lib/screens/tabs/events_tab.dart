import 'package:flutter/material.dart';
import '../../widgets/section_header.dart';
import '../schedule_meeting_screen.dart';

class EventsTab extends StatefulWidget {
  const EventsTab({super.key});

  @override
  State<EventsTab> createState() => _EventsTabState();
}

class _EventsTabState extends State<EventsTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          // Padding(
          //   padding: const EdgeInsets.symmetric(horizontal: 16),
          //   // child: SizedBox(
          //   //   width: double.infinity,
          //   //   child: ElevatedButton(
          //   //     onPressed: () {
          //   //       Navigator.of(context).push(
          //   //         MaterialPageRoute(
          //   //           builder: (context) => const ScheduleMeetingScreen(),
          //   //         ),
          //   //       );
          //   //     },
          //   //     style: ElevatedButton.styleFrom(
          //   //       backgroundColor: const Color(0xFF10B981),
          //   //       padding: const EdgeInsets.symmetric(vertical: 14),
          //   //       shape: RoundedRectangleBorder(
          //   //         borderRadius: BorderRadius.circular(24),
          //   //       ),
          //   //     ),
          //   //     // child: const Text(
          //   //     //   'Schedule Meeting',
          //   //     //   style: TextStyle(
          //   //     //     color: Colors.white,
          //   //     //     fontWeight: FontWeight.bold,
          //   //     //   ),
          //   //     // ),
          //   //   ),
          //   ),
          // ),
          const SizedBox(height: 16),
          const SectionHeader(title: 'Upcoming Events', action: 'See All'),
          // Event 1
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1C1C1E),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.calendar_month,
                            color: Colors.green,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Community Health Camp',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Free health checkup for all residents',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const Icon(Icons.close, color: Colors.white, size: 20),
                  ],
                ),
                const SizedBox(height: 12),
                const Row(
                  children: [
                    Icon(Icons.calendar_today, color: Colors.grey, size: 14),
                    SizedBox(width: 4),
                    Text(
                      'Dec 30, 2024',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    SizedBox(width: 16),
                    Icon(Icons.access_time, color: Colors.grey, size: 14),
                    SizedBox(width: 4),
                    Text(
                      '9:00 AM',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: _buildActionButton('Reject', Colors.red)),
                    const SizedBox(width: 8),
                    Expanded(child: _buildActionButton('Maybe', Colors.amber)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildActionButton(
                        'Register Now',
                        const Color(0xFF10B981),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Event 2
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.purple.shade900, Colors.purple.shade700],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Team Meeting',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      'Project Discussion',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          color: Colors.white70,
                          size: 14,
                        ),
                        SizedBox(width: 4),
                        Text(
                          '2:30 PM',
                          style: TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
                CircleAvatar(
                  backgroundColor: Colors.white24,
                  child: Icon(Icons.video_call, color: Colors.white),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildActionButton(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        border: Border.all(color: color),
        borderRadius: BorderRadius.circular(8),
        color: color.withValues(alpha: 0.1),
      ),
      alignment: Alignment.center,
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }
}
