import 'package:flutter/material.dart';
import '../../services/instructor_service.dart';
import '../../models/instructor_display.dart';
import 'settings_screen.dart';

class InstructorsScreen extends StatefulWidget {
  const InstructorsScreen({super.key});

  @override
  State<InstructorsScreen> createState() => _InstructorsScreenState();
}

class _InstructorsScreenState extends State<InstructorsScreen> {
  final _instructorService = InstructorService();
  List<InstructorDisplay> _allInstructors = [];
  List<InstructorDisplay> _filteredInstructors = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadInstructors();
  }

  Future<void> _loadInstructors() async {
    setState(() => _isLoading = true);
    try {
      final response = await _instructorService
          .getInstructorsWithStudentCount();
      setState(() {
        _allInstructors = response
            .map((json) => InstructorDisplay.fromJson(json))
            .toList();
        _applyFilters();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Błąd: $e')));
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _applyFilters() {
    _filteredInstructors = _allInstructors.where((instructorDisplay) {
      final instructor = instructorDisplay.instructor;

      // Wyszukiwanie
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final matchesName = instructor.fullName.toLowerCase().contains(query);
        final matchesEmail = instructor.email.toLowerCase().contains(query);

        if (!matchesName && !matchesEmail) {
          return false;
        }
      }

      return true;
    }).toList();

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Instruktorzy'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
            tooltip: 'Ustawienia',
          ),
        ],
      ),
      body: Column(
        children: [
          // Wyszukiwarka
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: const InputDecoration(
                labelText: 'Szukaj',
                hintText: 'Imię, nazwisko, email',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                  _applyFilters();
                });
              },
            ),
          ),

          // Lista instruktorów
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredInstructors.isEmpty
                ? const Center(child: Text('Brak instruktorów'))
                : ListView.builder(
                    itemCount: _filteredInstructors.length,
                    itemBuilder: (context, index) {
                      final instructorDisplay = _filteredInstructors[index];
                      final instructor = instructorDisplay.instructor;

                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 4,
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            child: Text(instructor.firstName?[0] ?? 'I'),
                          ),
                          title: Text(instructor.fullName),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (instructor.email.isNotEmpty)
                                Text('✉️ ${instructor.email}'),
                              if (instructor.phone != null)
                                Text('📱 ${instructor.phone}'),
                            ],
                          ),
                          trailing: Chip(
                            label: Text(
                              '${instructorDisplay.studentCount} kursantów',
                              style: const TextStyle(fontSize: 12),
                            ),
                            backgroundColor: Colors.blue.shade50,
                          ),
                          onTap: () {
                            // TODO: Szczegóły instruktora
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Szczegóły: ${instructor.fullName}',
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // TODO: Dodaj instruktora
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Dodawanie instruktora - wkrótce')),
          );
        },
        icon: const Icon(Icons.person_add),
        label: const Text('Dodaj instruktora'),
      ),
    );
  }
}
