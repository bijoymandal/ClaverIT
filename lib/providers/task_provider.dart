import 'package:flutter/material.dart';
import '../models/task.dart';
import '../services/task_service.dart';
import 'package:uuid/uuid.dart';

class TaskProvider with ChangeNotifier {
  final TaskService _taskService = TaskService();
  final List<Task> _tasks = [];
  bool _isLoading = false;
  final _uuid = const Uuid();

  List<Task> get tasks => [..._tasks];
  bool get isLoading => _isLoading;

  Future<void> fetchTasks() async {
    _isLoading = true;
    notifyListeners();
    try {
      final taskData = await _taskService.getTasks();
      _tasks.clear();
      for (var item in taskData) {
        _tasks.add(
          Task(
            id: item['id']?.toString() ?? '',
            title: item['title'] ?? '',
            description: item['description'] ?? '',
            isCompleted: item['isCompleted'] ?? false,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error fetching tasks: $e');
      // If backend fails, we keep local list for now
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addTask(String title, {String description = ''}) async {
    final tempId = _uuid.v4();
    final newTask = Task(id: tempId, title: title, description: description);
    _tasks.add(newTask);
    notifyListeners();

    try {
      final response = await _taskService.createTask(
        title,
        description: description,
      );
      // Update local task with actual backend ID if returned
      final index = _tasks.indexWhere((t) => t.id == tempId);
      if (index != -1 && response['id'] != null) {
        _tasks[index] = _tasks[index].copyWith(id: response['id'].toString());
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error creating task: $e');
      // Keep local task anyway for UX, or handle error
    }
  }

  Future<void> toggleTaskStatus(String id) async {
    final index = _tasks.indexWhere((task) => task.id == id);
    if (index != -1) {
      final newStatus = !_tasks[index].isCompleted;
      _tasks[index] = _tasks[index].copyWith(isCompleted: newStatus);
      notifyListeners();

      try {
        await _taskService.toggleTask(id, newStatus);
      } catch (e) {
        debugPrint('Error toggling task: $e');
        // Revert on error
        _tasks[index] = _tasks[index].copyWith(isCompleted: !newStatus);
        notifyListeners();
      }
    }
  }

  Future<void> removeTask(String id) async {
    final taskToRemove = _tasks.firstWhere((t) => t.id == id);
    final index = _tasks.indexOf(taskToRemove);
    _tasks.removeAt(index);
    notifyListeners();

    try {
      await _taskService.deleteTask(id);
    } catch (e) {
      debugPrint('Error deleting task: $e');
      // Restore on error
      _tasks.insert(index, taskToRemove);
      notifyListeners();
    }
  }
}
