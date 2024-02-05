import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert'; // Import for JSON encoding/decoding

void main() {
  runApp(const MyApp());
}

class TodoItem {
  final String title;
  final DateTime dateAdded;
  bool isDone;

  TodoItem({required this.title, required this.dateAdded, this.isDone = false});

  // Method to create a TodoItem from a JSON object
  factory TodoItem.fromJson(Map<String, dynamic> json) {
    return TodoItem(
      title: json['title'],
      dateAdded: DateTime.parse(json['dateAdded']),
      isDone: json['isDone'],
    );
  }

  // Method to convert a TodoItem into a JSON object
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'dateAdded': dateAdded.toIso8601String(),
      'isDone': isDone,
    };
  }
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Todo List',
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        hintColor: Colors.pink,
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            foregroundColor: Colors.white,
            backgroundColor: Colors.pink,
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: Colors.pink,
          ),
        ),
      ),
      home: const MyHomePage(title: 'Todo List'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  final String title;

  const MyHomePage({Key? key, required this.title}) : super(key: key);

  @override
  // ignore: library_private_types_in_public_api
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final List<TodoItem> _todoList = [];
  final TextEditingController _textEditingController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadTodoList();
  }

  Future<void> _loadTodoList() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? todoListJson = prefs.getStringList('todoList');
    if (todoListJson != null) {
      setState(() {
        _todoList.clear();
        _todoList.addAll(
            todoListJson.map((json) => TodoItem.fromJson(jsonDecode(json))));
      });
    }
  }

  Future<void> _saveTodoList() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> todoListJson =
        _todoList.map((todo) => jsonEncode(todo.toJson())).toList();
    await prefs.setStringList('todoList', todoListJson);
  }

  void _addTodoItem(String title) {
    setState(() {
      _todoList.add(TodoItem(title: title, dateAdded: DateTime.now()));
    });
    _textEditingController.clear();
    _saveTodoList();
  }

  void _deleteTodoItem(int index) {
    setState(() {
      _todoList.removeAt(index);
    });
    _saveTodoList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: ListView.builder(
        itemCount: _todoList.length,
        itemBuilder: (context, index) {
          final todo = _todoList[index];
          return Dismissible(
            key: Key(todo.title),
            onDismissed: (direction) {
              _deleteTodoItem(index);
            },
            background: Container(color: Colors.red),
            child: Card(
              color: Colors.lightBlueAccent,
              child: ListTile(
                title: Text(
                  todo.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Text(
                  'Added on: ${todo.dateAdded.toString().split(' ')[0]}',
                  style: const TextStyle(color: Colors.white),
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () => _deleteTodoItem(index),
                ),
                leading: Checkbox(
                  value: todo.isDone,
                  onChanged: (bool? value) {
                    setState(() {
                      todo.isDone = value ?? false;
                    });
                    _saveTodoList();
                  },
                ),
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          // ignore: unused_local_variable
          final String? newTodo = await showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: const Text('Add Todo'),
                content: TextField(
                  controller: _textEditingController,
                  autofocus: true,
                  decoration: const InputDecoration(labelText: 'Todo Title'),
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      if (_textEditingController.text.isNotEmpty) {
                        _addTodoItem(_textEditingController.text);
                        Navigator.pop(context);
                      }
                    },
                    child: const Text('Add'),
                  ),
                ],
              );
            },
          );
        },
        tooltip: 'Add Todo',
        child: const Icon(Icons.add),
      ),
    );
  }
}
