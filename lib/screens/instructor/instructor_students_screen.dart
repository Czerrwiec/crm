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

  // Nowe filtry
  bool _showInactive = false; // ✅ Zmienione: domyślnie ukrywamy nieaktywnych
  bool _showOnlyTheoryPassed = false;

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

      // ✅ Filtr nieaktywnych (odwrotna logika)
      if (!_showInactive && !student.active) {
        return false;
      }

      // Filtr teoria zdana
      if (_showOnlyTheoryPassed && !student.theoryPassed) {
        return false;
      }

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

  Future<void> _showFiltersDialog() async {
    bool tempInactive = _showInactive; // ✅ Zmienione
    bool tempTheory = _showOnlyTheoryPassed;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Filtry'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CheckboxListTile(
                title: const Text('Pokaż nieaktywnych'), // ✅ Zmienione
                value: tempInactive, // ✅ Zmienione
                onChanged: (value) {
                  setDialogState(() {
                    tempInactive = value ?? false; // ✅ Zmienione
                  });
                },
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
              ),
              CheckboxListTile(
                title: const Text('Tylko z teorią zdaną'),
                value: tempTheory,
                onChanged: (value) {
                  setDialogState(() {
                    tempTheory = value ?? false;
                  });
                },
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Anuluj'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _showInactive = tempInactive; // ✅ Zmienione
                  _showOnlyTheoryPassed = tempTheory;
                });
                Navigator.pop(context, true);
              },
              child: const Text('Zastosuj'),
            ),
          ],
        ),
      ),
    );

    if (result == true) {
      _applyFilters();
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeFiltersCount =
        (_showInactive ? 1 : 0) + // ✅ Zmienione
        (_showOnlyTheoryPassed ? 1 : 0);

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
          // Wyszukiwarka + Filtry
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
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
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: _showFiltersDialog,
                  icon: const Icon(Icons.filter_list),
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Filtry'),
                      if (activeFiltersCount > 0)
                        Container(
                          margin: const EdgeInsets.only(left: 8),
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade700,
                            shape: BoxShape.circle,
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 16,
                            minHeight: 16,
                          ),
                          child: Text(
                            '$activeFiltersCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
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
                          _searchQuery.isEmpty && activeFiltersCount == 0
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
                                    '${student.totalHoursDrivenFormatted} wyjeżdżonych',
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
