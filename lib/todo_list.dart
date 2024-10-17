// ignore_for_file: library_private_types_in_public_api, camel_case_types, unused_element, empty_catches

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';

class Event {
  final int id;
  String title;
  String? address;
  final List<Task> tasks;
  bool isExpanded;

  Event({
    required this.id,
    required this.title,
    this.address,
    required this.tasks,
    this.isExpanded = false,
  });
}

class Task {
  final int id;
  String title;
  bool isCompleted;
  final List<Subtask> subtasks;

  Task({
    required this.id,
    required this.title,
    required this.isCompleted,
    required this.subtasks,
  });

  factory Task.fromMap(Map<String, dynamic> map) {
    return Task(
      id: map['id'],
      title: map['title'],
      isCompleted: map['is_completed'],
      subtasks: [],
    );
  }
}

class Subtask {
  final int id;
  String title;
  bool isCompleted;

  Subtask({
    required this.id,
    required this.title,
    required this.isCompleted,
  });

  factory Subtask.fromMap(Map<String, dynamic> map) {
    return Subtask(
      id: map['id'],
      title: map['title'],
      isCompleted: map['is_completed'],
    );
  }
}

class TodoListWithEvents extends StatefulWidget {
  const TodoListWithEvents({super.key});

  @override
  _TodoListWithEventsState createState() => _TodoListWithEventsState();
}

class _TodoListWithEventsState extends State<TodoListWithEvents> {
  final SupabaseClient supabase = Supabase.instance.client;
  final List<Event> _events = [];

  // Google Maps Controller
  late GoogleMapController mapController;
  final LatLng _initialCameraPosition =
      const LatLng(-21.110637, 55.531684); // Position initiale (La Reunion)

  // Liste des marqueurs
  final Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    final List<Map<String, dynamic>> eventsResponse =
        await supabase.from('events').select();
    final List<Map<String, dynamic>> tasksResponse =
        await supabase.from('tasks').select();
    final List<Map<String, dynamic>> subtasksResponse =
        await supabase.from('subtasks').select();

    setState(() {
      _events.clear();
      for (var event in eventsResponse) {
        List<Task> tasks = tasksResponse
            .where((task) => task['event_id'] == event['id'])
            .map<Task>((task) {
          List<Subtask> subtasks = subtasksResponse
              .where((subtask) => subtask['task_id'] == task['id'])
              .map<Subtask>((subtask) => Subtask.fromMap(subtask))
              .toList();

          return Task(
            id: task['id'],
            title: task['title'],
            isCompleted: task['is_completed'],
            subtasks: subtasks,
          );
        }).toList();

        _events.add(Event(
          id: event['id'],
          title: event['title'],
          address: event['address'],
          tasks: tasks,
          isExpanded: false,
        ));
      }
    });
  }

  Future<void> _addEvent(String title, String address) async {
    if (title.isNotEmpty) {
      await supabase.from('events').insert({
        'title': title,
        'address': address,
      });
      _loadEvents();
    }
  }

  Future<void> _removeEvent(int eventId) async {
    await supabase.from('events').delete().eq('id', eventId);
    _loadEvents();
  }

  Future<void> _updateEvent(
      int eventId, String title, String? address) async {
    if (title.isNotEmpty) {
      await supabase.from('events').update({
        'title': title,
        'address': address,
      }).eq('id', eventId);
      _loadEvents();
    }
  }

  Future<void> _addTask(int eventId, String taskTitle) async {
    if (taskTitle.isNotEmpty) {
      await supabase.from('tasks').insert({
        'event_id': eventId,
        'title': taskTitle,
        'is_completed': false,
      });
      _loadEvents();
    }
  }

  Future<void> _removeTask(int taskId) async {
    await supabase.from('tasks').delete().eq('id', taskId);
    _loadEvents();
  }

  Future<void> _addSubtask(int taskId, String subtaskTitle) async {
    if (subtaskTitle.isNotEmpty) {
      await supabase.from('subtasks').insert({
        'task_id': taskId,
        'title': subtaskTitle,
        'is_completed': false,
      });
      _loadEvents();
    }
  }

  Future<void> _removeSubtask(int subtaskId) async {
    await supabase.from('subtasks').delete().eq('id', subtaskId);
    _loadEvents();
  }

  Future<void> _updateTask(Task task) async {
    await supabase.from('tasks').update({
      'title': task.title,
      'is_completed': task.isCompleted,
    }).eq('id', task.id);
    _loadEvents();
  }

  Future<void> _updateSubtask(Subtask subtask) async {
    await supabase.from('subtasks').update({
      'title': subtask.title,
      'is_completed': subtask.isCompleted,
    }).eq('id', subtask.id);
    _loadEvents();
  }

  Future<void> _goToLocation(String address) async {
    try {
      List<Location> locations = await locationFromAddress(address);
      if (locations.isNotEmpty) {
        final LatLng newLocation =
            LatLng(locations.first.latitude, locations.first.longitude);

        _markers.clear();

        mapController.animateCamera(CameraUpdate.newLatLng(newLocation));

        _markers.add(
          Marker(
            markerId: MarkerId(address),
            position: newLocation,
            infoWindow: InfoWindow(title: address),
          ),
        );

        setState(() {});
      }
    } catch (e) {}
  }

  void _promptAddEvent() {
    String title = '';
    String address = '';
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Ajouter un nouvel événement'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration:
                    const InputDecoration(hintText: 'Titre de l\'événement'),
                onChanged: (value) => title = value,
              ),
              TextField(
                decoration: const InputDecoration(hintText: 'Adresse'),
                onChanged: (value) => address = value,
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Annuler'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('Ajouter'),
              onPressed: () {
                Navigator.of(context).pop();
                _addEvent(title, address);
              },
            ),
          ],
        );
      },
    );
  }

  void _toggleEventExpansion(Event event) {
    setState(() {
      event.isExpanded = !event.isExpanded;
    });
  }

  void _toggleTaskCompletion(Task task) {
    setState(() {
      task.isCompleted = !task.isCompleted;
      _updateTask(task);
    });
  }

  void _toggleSubtaskCompletion(Subtask subtask) {
    setState(() {
      subtask.isCompleted = !subtask.isCompleted;
      _updateSubtask(subtask);
    });
  }

  void _promptAddTask(Event event) {
    String taskTitle = '';
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Ajouter une nouvelle tâche'),
          content: TextField(
            decoration: const InputDecoration(hintText: 'Titre de la tâche'),
            onChanged: (value) => taskTitle = value,
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Annuler'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('Ajouter'),
              onPressed: () {
                Navigator.of(context).pop();
                _addTask(event.id, taskTitle);
              },
            ),
          ],
        );
      },
    );
  }

  void _promptAddSubtask(Task task) {
    String subtaskTitle = '';
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Ajouter une nouvelle sous-tâche'),
          content: TextField(
            decoration: const InputDecoration(hintText: 'Titre de la sous-tâche'),
            onChanged: (value) => subtaskTitle = value,
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Annuler'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('Ajouter'),
              onPressed: () {
                Navigator.of(context).pop();
                _addSubtask(task.id, subtaskTitle);
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'EventWise',
          style: TextStyle(
            color: Colors.white,
            fontFamily: 'Roboto',
            fontSize: 20.0,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color.fromARGB(255, 0, 0, 0),
        centerTitle: true,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color.fromARGB(255, 0, 0, 0),
              Colors.purple,
            ],
          ),
        ),
        child: Column(
          children: [
            SizedBox(
              height: 250, // Limiter la hauteur de la carte
              width: 380,
              child: GoogleMap(
                onMapCreated: (GoogleMapController controller) {
                  mapController = controller;
                },
                initialCameraPosition:
                    CameraPosition(target: _initialCameraPosition, zoom: 10),
                markers: _markers,
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: _events.length,
                itemBuilder: (context, index) {
                  final event = _events[index];
                  return Card(
                    child: ExpansionTile(
                      title: Text(event.title),
                      subtitle: Text(event.address ?? ''),
                      trailing: IconButton(
                        icon: const Icon(Icons.location_on),
                        onPressed: () {
                          if (event.address != null) {
                            _goToLocation(event.address!);
                          }
                        },
                      ),
                      initiallyExpanded: event.isExpanded,
                      onExpansionChanged: (expanded) {
                        _toggleEventExpansion(event);
                      },
                      children: [
                        ...event.tasks.map((task) {
                          return ListTile(
                            title: Text(task.title),
                            trailing: Checkbox(
                              value: task.isCompleted,
                              onChanged: (bool? value) {
                                _toggleTaskCompletion(task);
                              },
                            ),
                            onTap: () => _promptAddSubtask(task),
                            subtitle: Column(
                              children: [
                                ...task.subtasks.map((subtask) {
                                  return ListTile(
                                    title: Text(subtask.title),
                                    trailing: Checkbox(
                                      value: subtask.isCompleted,
                                      onChanged: (bool? value) {
                                        _toggleSubtaskCompletion(subtask);
                                      },
                                    ),
                                  );
                                }),
                                TextButton.icon(
                                  onPressed: () {
                                    _promptAddSubtask(task);
                                  },
                                  icon: const Icon(Icons.add),
                                  label: const Text('Ajouter une sous-tâche'),
                                ),
                              ],
                            ),
                          );
                        }),
                        TextButton.icon(
                          onPressed: () {
                            _promptAddTask(event);
                          },
                          icon: const Icon(Icons.add),
                          label: const Text('Ajouter une tâche'),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _promptAddEvent,
        child: const Icon(Icons.add),
      ),
    );
  }
}
