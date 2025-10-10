import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/student_service.dart';
import '../../models/student_display.dart';
import '../../models/list_settings.dart';
import '../student/student_detail_screen.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  final _studentService = StudentService();
  List<StudentDisplay> _allStudents = [];
  List<StudentDisplay> _filteredStudents = [];
  bool _isLoading = true;
  String _searchQuery = '';

  // Sortowanie i kolumny
  SortOption _sortOption = SortOption.lastName;
  Set<DisplayColumn> _selectedColumns = {
    DisplayColumn.phone,
    DisplayColumn.activeOnly,
  }; //domyślne kolumny

  @override
  void initState() {
    super.initState();
    _loadStudents();
  }

  Future<void> _loadStudents() async {
    setState(() => _isLoading = true);
    try {
      final response = await _studentService.getStudentsWithInstructors();
      setState(() {
        _allStudents = response
            .map((json) => StudentDisplay.fromJson(json))
            .toList();
        _applyFiltersAndSort();
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

  void _applyFiltersAndSort() {
    // Filtrowanie
    var filtered = _allStudents.where((studentDisplay) {
      final student = studentDisplay.student;

      // Filtr "Tylko aktywni"
      if (_selectedColumns.contains(DisplayColumn.activeOnly) &&
          !student.active) {
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

    // Sortowanie
    filtered.sort((a, b) {
      switch (_sortOption) {
        case SortOption.lastName:
          return a.student.lastName.compareTo(b.student.lastName);
        case SortOption.firstName:
          return a.student.firstName.compareTo(b.student.firstName);
        case SortOption.courseDuration:
          final aDays = a.student.courseDurationDays ?? 0;
          final bDays = b.student.courseDurationDays ?? 0;
          return bDays.compareTo(aDays); // Malejąco
      }
    });

    setState(() {
      _filteredStudents = filtered;
    });
  }

  // Dialog wyboru kolumn
  Future<void> _showColumnsDialog() async {
    final result = await showDialog<Set<DisplayColumn>>(
      context: context,
      builder: (context) => _ColumnsDialog(selectedColumns: _selectedColumns),
    );

    if (result != null) {
      setState(() {
        _selectedColumns = result;
        _applyFiltersAndSort();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lista kursantów'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await AuthService().signOut();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Pasek filtrów
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Wyszukiwarka
                Expanded(
                  flex: 2,
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
                        _applyFiltersAndSort();
                      });
                    },
                  ),
                ),
                const SizedBox(width: 12),

                // Sortowanie
                Expanded(
                  child: DropdownButtonFormField<SortOption>(
                    value: _sortOption,
                    decoration: const InputDecoration(
                      labelText: 'Sortuj',
                      border: OutlineInputBorder(),
                    ),
                    items: SortOption.values.map((option) {
                      return DropdownMenuItem(
                        value: option,
                        child: Text(
                          option.label,
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _sortOption = value;
                          _applyFiltersAndSort();
                        });
                      }
                    },
                  ),
                ),
                const SizedBox(width: 12),

                // Kolumny
                OutlinedButton.icon(
                  onPressed: _showColumnsDialog,
                  icon: const Icon(Icons.view_column),
                  label: const Text('Kolumny'),
                ),
              ],
            ),
          ),

          // Lista kursantów
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredStudents.isEmpty
                ? const Center(child: Text('Brak kursantów'))
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
                        // Wyszarzenie nieaktywnych
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
                            ),
                          ),
                          subtitle: _buildSubtitle(studentDisplay),
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

  // Budowanie subtitle z wybranymi kolumnami
  Widget? _buildSubtitle(StudentDisplay studentDisplay) {
    final student = studentDisplay.student;
    final lines = <String>[];

    if (_selectedColumns.contains(DisplayColumn.phone) &&
        student.phone != null) {
      lines.add('${student.phone}');
    }
    if (_selectedColumns.contains(DisplayColumn.email) &&
        student.email != null) {
      lines.add('✉️ ${student.email}');
    }
    if (_selectedColumns.contains(DisplayColumn.pkk) &&
        student.pkkNumber != null) {
      lines.add('PKK: ${student.pkkNumber}');
    }
    if (_selectedColumns.contains(DisplayColumn.theoryPassed)) {
      lines.add('Teoria: ${student.theoryPassed ? "✅ Zdana" : "❌ Nie zdana"}');
    }
    if (_selectedColumns.contains(DisplayColumn.coursePaid)) {
      lines.add('Kurs: ${student.coursePaid ? "✅ Opłacony" : "❌ Nieopłacony"}');
    }
    if (_selectedColumns.contains(DisplayColumn.hoursDriven)) {
      lines.add('🚗 ${student.totalHoursDriven}h');
    }
    if (_selectedColumns.contains(DisplayColumn.instructor) &&
        studentDisplay.instructorName != null) {
      lines.add('👨‍🏫 ${studentDisplay.instructorName}');
    }
    if (_selectedColumns.contains(DisplayColumn.courseDuration) &&
        student.courseDurationDays != null) {
      lines.add('📅 ${student.courseDurationDays} dni');
    }

    if (lines.isEmpty) {
      return null;
    }

    return Text(lines.join(' • '), style: const TextStyle(fontSize: 13));
  }
}

// Dialog wyboru kolumn
class _ColumnsDialog extends StatefulWidget {
  final Set<DisplayColumn> selectedColumns;

  const _ColumnsDialog({required this.selectedColumns});

  @override
  State<_ColumnsDialog> createState() => _ColumnsDialogState();
}

class _ColumnsDialogState extends State<_ColumnsDialog> {
  late Set<DisplayColumn> _tempSelected;

  @override
  void initState() {
    super.initState();
    _tempSelected = Set.from(widget.selectedColumns);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Wybierz kolumny'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: DisplayColumn.values.map((column) {
            return CheckboxListTile(
              title: Text(column.label),
              value: _tempSelected.contains(column),
              onChanged: (checked) {
                setState(() {
                  if (checked == true) {
                    _tempSelected.add(column);
                  } else {
                    _tempSelected.remove(column);
                  }
                });
              },
            );
          }).toList(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Anuluj'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, _tempSelected),
          child: const Text('Zapisz'),
        ),
      ],
    );
  }
}
