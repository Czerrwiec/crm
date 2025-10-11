import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/student_service.dart';
import '../../models/student_display.dart';
import '../../models/list_settings.dart';
import '../student/student_detail_screen.dart';
import '../student/add_student_screen.dart';
import 'settings_screen.dart';

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
  SortOption _sortOption = SortOption.lastNameAsc;
  Set<DisplayColumn> _selectedColumns = {DisplayColumn.phone};
  Set<FilterOption> _selectedFilters = {};

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

      // Filtr "Nieaktwyni"
      if (!_selectedFilters.contains(FilterOption.showInactive) &&
          !student.active) {
        return false;
      }

      // Filtr "Teoria zdana"
      if (_selectedFilters.contains(FilterOption.theoryPassed) &&
          !student.theoryPassed) {
        return false;
      }

      // Filtr "Kurs opłacony"
      if (_selectedFilters.contains(FilterOption.coursePaid) &&
          !student.coursePaid) {
        return false;
      }

      // Filtr "Kurs nieopłacony"
      if (_selectedFilters.contains(FilterOption.courseUnpaid) &&
          student.coursePaid) {
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
        case SortOption.lastNameAsc:
          return a.student.lastName.compareTo(b.student.lastName);
        case SortOption.lastNameDesc:
          return b.student.lastName.compareTo(a.student.lastName);
        case SortOption.firstNameAsc:
          return a.student.firstName.compareTo(b.student.firstName);
        case SortOption.firstNameDesc:
          return b.student.firstName.compareTo(a.student.firstName);
        case SortOption.courseStartAsc:
          final aDate = a.student.courseStartDate ?? DateTime(1900);
          final bDate = b.student.courseStartDate ?? DateTime(1900);
          return aDate.compareTo(bDate);
        case SortOption.courseStartDesc:
          final aDate = a.student.courseStartDate ?? DateTime(1900);
          final bDate = b.student.courseStartDate ?? DateTime(1900);
          return bDate.compareTo(aDate);
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

  Future<void> _showFiltersDialog() async {
    final result = await showDialog<Set<FilterOption>>(
      context: context,
      builder: (context) => _FiltersDialog(selectedFilters: _selectedFilters),
    );

    if (result != null) {
      setState(() {
        _selectedFilters = result;
        _applyFiltersAndSort();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kursanci!'),
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
                // Filtry
                OutlinedButton.icon(
                  onPressed: _showFiltersDialog,
                  icon: const Icon(Icons.filter_list),
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Filtry'),
                      if (_selectedFilters.isNotEmpty)
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
                            '${_selectedFilters.length}',
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  AddStudentScreen(onStudentAdded: _loadStudents),
            ),
          );
        },
        icon: const Icon(Icons.person_add),
        label: const Text('Dodaj kursanta'),
      ),
    );
  }

  // Budowanie subtitle z wybranymi kolumnami
  Widget? _buildSubtitle(StudentDisplay studentDisplay) {
    final student = studentDisplay.student;
    final lines = <String>[];

    if (_selectedColumns.contains(DisplayColumn.phone) &&
        student.phone != null) {
      lines.add('📱 ${student.phone}');
    }
    if (_selectedColumns.contains(DisplayColumn.email) &&
        student.email != null) {
      lines.add('✉️ ${student.email}');
    }
    if (_selectedColumns.contains(DisplayColumn.pkk) &&
        student.pkkNumber != null) {
      lines.add('PKK: ${student.pkkNumber}');
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

// Dialog wyboru filtrów
class _FiltersDialog extends StatefulWidget {
  final Set<FilterOption> selectedFilters;

  const _FiltersDialog({required this.selectedFilters});

  @override
  State<_FiltersDialog> createState() => _FiltersDialogState();
}

class _FiltersDialogState extends State<_FiltersDialog> {
  late Set<FilterOption> _tempSelected;

  @override
  void initState() {
    super.initState();
    _tempSelected = Set.from(widget.selectedFilters);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Wybierz filtry'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: FilterOption.values.map((filter) {
            return CheckboxListTile(
              title: Text(filter.label),
              value: _tempSelected.contains(filter),
              onChanged: (checked) {
                setState(() {
                  if (checked == true) {
                    _tempSelected.add(filter);
                  } else {
                    _tempSelected.remove(filter);
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
          child: const Text('Zastosuj'),
        ),
      ],
    );
  }
}
