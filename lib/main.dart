import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'todo_list.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://hbmzpkbzloojzfytztyx.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImhibXpwa2J6bG9vanpmeXR6dHl4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3MTk5ODMxNDAsImV4cCI6MjAzNTU1OTE0MH0.HxY4dpFZcGiokkx-SwhuvVfPPpTGlvfZpv3t047i0H8',
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'To-Do List with Supabase',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const TodoListWithEvents(),
    );
  }
}