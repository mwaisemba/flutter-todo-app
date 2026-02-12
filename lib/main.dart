import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'To-Do List',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const TodoScreen(),
    );
  }
}

class TodoScreen extends StatefulWidget {
  const TodoScreen({super.key});

  @override
  State<TodoScreen> createState() => _TodoScreenState();
}

class _TodoScreenState extends State<TodoScreen> {
  final TextEditingController _controller = TextEditingController();
  List<Map<String, dynamic>> _tasks = [];

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  // Load tasks from local storage
  Future<void> _loadTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final String? tasksString = prefs.getString('tasks');

    if (tasksString != null) {
      final List<dynamic> jsonList = jsonDecode(tasksString);
      setState(() {
        _tasks = jsonList.map((e) => Map<String, dynamic>.from(e)).toList();
      });
    } else {
      // First time: add 5 sample tasks for demo
      setState(() {
        _tasks = [
          {'title': 'Complete assignment reading', 'completed': false},
          {'title': 'Prepare presentation slides', 'completed': false},
          {'title': 'Review Flutter widgets', 'completed': false},
          {'title': 'Test the app on emulator', 'completed': false},
          {'title': 'Commit code to GitHub', 'completed': false},
        ];
      });
      _saveTasks();
    }
  }

  // Save tasks to local storage
  Future<void> _saveTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final String jsonString = jsonEncode(_tasks);
    prefs.setString('tasks', jsonString);
  }

  // Add new task
  void _addTask() {
    if (_controller.text.trim().isNotEmpty) {
      setState(() {
        _tasks.add({
          'title': _controller.text.trim(),
          'completed': false,
        });
      });
      _saveTasks();
      _controller.clear();
    }
  }

  // Toggle complete
  void _toggleComplete(int index) {
    setState(() {
      _tasks[index]['completed'] = !_tasks[index]['completed'];
    });
    _saveTasks();
  }

  // Delete task
  void _deleteTask(int index) {
    setState(() {
      _tasks.removeAt(index);
    });
    _saveTasks();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('To-Do List'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText: 'Enter new task...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _addTask,
                  child: const Icon(Icons.add),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _tasks.length,
              itemBuilder: (context, index) {
                final task = _tasks[index];
                return Dismissible(
                  key: Key(task['title']),
                  direction: DismissDirection.endToStart,
                  onDismissed: (_) => _deleteTask(index),
                  background: Container(
                    color: Colors.red,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  child: CheckboxListTile(
                    title: Text(
                      task['title'],
                      style: TextStyle(
                        decoration: task['completed']
                            ? TextDecoration.lineThrough
                            : null,
                        color: task['completed'] ? Colors.grey : null,
                      ),
                    ),
                    value: task['completed'],
                    onChanged: (_) => _toggleComplete(index),
                    secondary: IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => _deleteTask(index),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}