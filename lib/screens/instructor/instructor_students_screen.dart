import 'package:flutter/material.dart';
import '../../services/student_service.dart';
import '../../services/auth_service.dart';
import '../../models/student_display.dart';
import '../student/student_detail_screen.dart';

class InstructorStudentsScreen extends StatefulWidget {
  const InstructorStudentsScreen({super.key});

  @override
  State<InstructorStudentsScreen> createState() =>
      _InstructorStudentsScreenState();
}

class _InstructorStudentsScreenState extends State<InstructorStudentsScreen> {
  final _studentService = StudentService();
  final _authService = AuthService();

  List<StudentDisplay> _allStudents = [];
  List<StudentDisplay> _filteredStudents = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String? _instructorId;

  @override
  void initState() {
    super.initState();
    _initInstructor();
  }

  Future<void> _initInstructor() async {
    final user = _authService.currentUser;
    if (user != null) {
      setState(() {
        _instructorId = user.id;
      });
      await _loadStudents();
    }
  }

  Future<void> _loadStudents() async {
    if (_instructorId == null) return;

    setState(() => _isLoading = true);
    try {
      final response = await _studentService.getStudentsWithInstructors();

      // Filtruj tylko kursantów przypisanych do tego instruktora
      final myStudents = response
          .map((json) => StudentDisplay.fromJson(json))
          .where((sd) => sd.student.instructorId == _instructorId)
          .toList();

      setState(() {
        _allStudents = myStudents;
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
    _filteredStudents = _allStudents.where((studentDisplay) {
      final student = studentDisplay.student;

      // Wyszukiwanie
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final matchesName = student.fullName.toLowerCase().contains(query);
        final matchesPhone =
            student.phone?.toLowerCase().contains(query) ?? false;
        final matchesPkk =
            student.pkkNumber?.toLowerCase().contains(query) ?? false;

        if (!matchesName && !matchesPhone && !matchesPkk) {
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
        title: const Text('Moi kursanci'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await _authService.signOut();
            },
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
                hintText: 'Imię, nazwisko, telefon, PKK',
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

          // Lista kursantów
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredStudents.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.people_outline,
                          size: 64,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _searchQuery.isEmpty
                              ? 'Nie masz przypisanych kursantów'
                              : 'Brak wyników wyszukiwania',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: _filteredStudents.length,
                    itemBuilder: (context, index) {
                      final studentDisplay = _filteredStudents[index];
                      final student = studentDisplay.student;

                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 4,
                        ),
                        color: student.active ? null : Colors.grey.shade200,
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: student.active
                                ? null
                                : Colors.grey,
                            child: Text(student.firstName[0]),
                          ),
                          title: Text(
                            student.fullName,
                            style: TextStyle(
                              color: student.active
                                  ? null
                                  : Colors.grey.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (student.phone != null)
                                Text('📱 ${student.phone}'),
                              Row(
                                children: [
                                  if (student.theoryPassed)
                                    const Padding(
                                      padding: EdgeInsets.only(right: 8),
                                      child: Icon(
                                        Icons.school,
                                        color: Colors.green,
                                        size: 16,
                                      ),
                                    ),
                                  if (student.coursePaid)
                                    const Padding(
                                      padding: EdgeInsets.only(right: 8),
                                      child: Icon(
                                        Icons.payment,
                                        color: Colors.green,
                                        size: 16,
                                      ),
                                    ),
                                  Text(
                                    '${student.totalHoursDriven}h wyjeżdżonych',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          trailing: Icon(
                            Icons.chevron_right,
                            color: student.active ? null : Colors.grey,
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => StudentDetailScreen(
                                  student: student,
                                  onStudentUpdated: _loadStudents,
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
    );
  }
}
