import 'package:flutter/material.dart';
import 'events_tab.dart'; // Reusing your existing Events UI 
import '../workspace/tasks_tab.dart';
import '../workspace/meetings_tab.dart';

class WorkspaceTab extends StatelessWidget {
  const WorkspaceTab({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          Container(
            color: const Color(0xFF121212),
            child: const TabBar(
              indicatorColor: Color(0xFF10B981),
              labelColor: Color(0xFF10B981),
              unselectedLabelColor: Colors.grey,
              tabs: [
                Tab(text: 'Tasks'),
                Tab(text: 'Meetings'),
                Tab(text: 'Events'),
              ],
            ),
          ),
          const Expanded(
            child: TabBarView(
              children: [
                TasksTab(), // The To-Do app UI 
                MeetingsTab(), // The Schedule Meetings UI 
                EventsTab(), // Your existing Events UI 
              ],
            ),
          ),
        ],
      ),
    );
  }
}
