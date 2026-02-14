import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const TodoApp());
}

class TodoApp extends StatelessWidget {
  const TodoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'To-Do List',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.teal,
          brightness: Brightness.light,
        ),
        cardTheme: CardThemeData(
          elevation: 1,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 0),
        ),
        listTileTheme: const ListTileThemeData(
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        ),
      ),
      home: const TodoScreen(),
    );
  }
}

class Task {
  String title;
  bool isDone;

  Task({required this.title, this.isDone = false});

  Map<String, dynamic> toJson() => {'title': title, 'isDone': isDone};

  factory Task.fromJson(Map<String, dynamic> json) => Task(
        title: json['title'],
        isDone: json['isDone'],
      );
}

class TodoScreen extends StatefulWidget {
  const TodoScreen({super.key});

  @override
  State<TodoScreen> createState() => _TodoScreenState();
}

class _TodoScreenState extends State<TodoScreen> {
  final List<Task> _tasks = [];
  final TextEditingController _controller = TextEditingController();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final String? tasksJson = prefs.getString('tasks');

    if (tasksJson != null && tasksJson.isNotEmpty) {
      final List<dynamic> decoded = jsonDecode(tasksJson);
      setState(() {
        _tasks.addAll(decoded.map((e) => Task.fromJson(e)).toList());
        _isLoading = false;
      });
    } else {
      // Add 5 demo tasks on first launch
      setState(() {
        _tasks.addAll([
          Task(title: 'Complete assignment reading'),
          Task(title: 'Prepare presentation slides'),
          Task(title: 'Review Flutter widgets'),
          Task(title: 'Test the app on emulator'),
          Task(title: 'Commit code to GitHub'),
        ]);
        _isLoading = false;
        _saveTasks();
      });
    }
  }

  Future<void> _saveTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final String encoded = jsonEncode(_tasks.map((t) => t.toJson()).toList());
    await prefs.setString('tasks', encoded);
  }

  void _addTask() {
    if (_controller.text.trim().isEmpty) return;

    setState(() {
      _tasks.add(Task(title: _controller.text.trim()));
      _controller.clear();
    });
    _saveTasks();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Task added')),
    );
  }

  void _toggleDone(int index) {
    setState(() {
      _tasks[index].isDone = !_tasks[index].isDone;
    });
    _saveTasks();
  }

  void _deleteTask(int index) {
    setState(() {
      _tasks.removeAt(index);
    });
    _saveTasks();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Task deleted')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('To-Do List'),
        centerTitle: true,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  // Input field + button
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _controller,
                          decoration: InputDecoration(
                            hintText: 'Enter new task...',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                          ),
                          textCapitalization: TextCapitalization.sentences,
                        ),
                      ),
                      const SizedBox(width: 12),
                      FloatingActionButton.small(
                        onPressed: _addTask,
                        child: const Icon(Icons.add),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Task list
                  Expanded(
                    child: _tasks.isEmpty
                        ? const Center(
                            child: Text(
                              'No tasks yet.\nAdd one above!',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 18, color: Colors.grey),
                            ),
                          )
                        : ReorderableListView.builder(
                            itemCount: _tasks.length,
                            onReorder: (oldIndex, newIndex) {
                              setState(() {
                                if (newIndex > oldIndex) newIndex--;
                                final task = _tasks.removeAt(oldIndex);
                                _tasks.insert(newIndex, task);
                              });
                              _saveTasks();
                            },
                            itemBuilder: (context, index) {
                              final task = _tasks[index];
                              return Dismissible(
                                key: ValueKey(task.title + index.toString()),
                                direction: DismissDirection.endToStart,
                                background: Container(
                                  color: Colors.red,
                                  alignment: Alignment.centerRight,
                                  padding: const EdgeInsets.only(right: 20),
                                  child: const Icon(Icons.delete, color: Colors.white),
                                ),
                                onDismissed: (_) => _deleteTask(index),
                                child: Card(
                                  child: ListTile(
                                    leading: Checkbox(
                                      value: task.isDone,
                                      activeColor: Theme.of(context).colorScheme.primary,
                                      shape: const CircleBorder(),
                                      onChanged: (_) => _toggleDone(index),
                                    ),
                                    title: Text(
                                      task.title,
                                      style: TextStyle(
                                        decoration: task.isDone ? TextDecoration.lineThrough : null,
                                        color: task.isDone
                                            // ignore: deprecated_member_use
                                            ? Theme.of(context).colorScheme.onSurface.withOpacity(0.6)
                                            : null,
                                      ),
                                    ),
                                    trailing: IconButton(
                                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                                      onPressed: () => _deleteTask(index),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}