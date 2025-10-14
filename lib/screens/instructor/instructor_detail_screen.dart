import 'package:flutter/material.dart';
import '../../models/app_user.dart';
import '../../services/instructor_service.dart';

class InstructorDetailScreen extends StatefulWidget {
  final AppUser instructor;
  final VoidCallback? onInstructorUpdated;

  const InstructorDetailScreen({
    super.key,
    required this.instructor,
    this.onInstructorUpdated,
  });

  @override
  State<InstructorDetailScreen> createState() => _InstructorDetailScreenState();
}

class _InstructorDetailScreenState extends State<InstructorDetailScreen> {
  final _instructorService = InstructorService();
  bool _isEditing = false;

  // Kontrolery
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;

  @override
  void initState() {
    super.initState();
    _firstNameController = TextEditingController(
      text: widget.instructor.firstName ?? '',
    );
    _lastNameController = TextEditingController(
      text: widget.instructor.lastName ?? '',
    );
    _emailController = TextEditingController(text: widget.instructor.email);
    _phoneController = TextEditingController(
      text: widget.instructor.phone ?? '',
    );
  }

  Future<void> _reloadInstructor() async {
    try {
      final updatedInstructor = await _instructorService.getInstructor(
        widget.instructor.id,
      );

      setState(() {
        _firstNameController.text = updatedInstructor.firstName ?? '';
        _lastNameController.text = updatedInstructor.lastName ?? '';
        _emailController.text = updatedInstructor.email;
        _phoneController.text = updatedInstructor.phone ?? '';
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Błąd odświeżania: $e')));
      }
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _cancelEditing() {
    setState(() {
      _firstNameController.text = widget.instructor.firstName ?? '';
      _lastNameController.text = widget.instructor.lastName ?? '';
      _emailController.text = widget.instructor.email;
      _phoneController.text = widget.instructor.phone ?? '';
      _isEditing = false;
    });
  }

  Future<void> _saveChanges() async {
    // Walidacja
    if (_firstNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Imię jest wymagane')));
      return;
    }

    if (_lastNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Nazwisko jest wymagane')));
      return;
    }

    if (_emailController.text.trim().isEmpty ||
        !_emailController.text.contains('@')) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Wprowadź poprawny email')));
      return;
    }

    try {
      final data = {
        'first_name': _firstNameController.text.trim(),
        'last_name': _lastNameController.text.trim(),
        'email': _emailController.text.trim(),
        'phone': _phoneController.text.trim().isEmpty
            ? null
            : _phoneController.text.trim(),
      };

      await _instructorService.updateInstructor(widget.instructor.id, data);

      await _reloadInstructor();

      // Wywołaj callback
      widget.onInstructorUpdated?.call();

      setState(() {
        _isEditing = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Zmiany zapisane'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Błąd: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.instructor.fullName),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: _showDeleteDialog,
            tooltip: 'Usuń instruktora',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Dane instruktora',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        if (!_isEditing)
                          ElevatedButton.icon(
                            onPressed: () {
                              setState(() {
                                _isEditing = true;
                              });
                            },
                            icon: const Icon(Icons.edit, size: 18),
                            label: const Text('Edytuj'),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Imię i Nazwisko
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _firstNameController,
                            decoration: InputDecoration(
                              labelText: 'Imię *',
                              border: const OutlineInputBorder(),
                              filled: !_isEditing,
                              fillColor: !_isEditing
                                  ? Colors.grey.shade50
                                  : null,
                            ),
                            enabled: _isEditing,
                            style: TextStyle(
                              color: _isEditing ? Colors.black : Colors.black87,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextField(
                            controller: _lastNameController,
                            decoration: InputDecoration(
                              labelText: 'Nazwisko *',
                              border: const OutlineInputBorder(),
                              filled: !_isEditing,
                              fillColor: !_isEditing
                                  ? Colors.grey.shade50
                                  : null,
                            ),
                            enabled: _isEditing,
                            style: TextStyle(
                              color: _isEditing ? Colors.black : Colors.black87,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Email (tylko do odczytu)
                    // Email
                    TextField(
                      controller: _emailController,
                      decoration: InputDecoration(
                        labelText: 'Email',
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.email),
                        filled: !_isEditing,
                        fillColor: !_isEditing ? Colors.grey.shade50 : null,
                        helperText: _isEditing
                            ? 'Zmiana emaila nie wpływa na login'
                            : null,
                        helperMaxLines: 2,
                      ),
                      keyboardType: TextInputType.emailAddress,
                      enabled: _isEditing,
                      style: TextStyle(
                        color: _isEditing ? Colors.black : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Telefon
                    TextField(
                      controller: _phoneController,
                      decoration: InputDecoration(
                        labelText: 'Telefon',
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.phone),
                        filled: !_isEditing,
                        fillColor: !_isEditing ? Colors.grey.shade50 : null,
                      ),
                      keyboardType: TextInputType.phone,
                      enabled: _isEditing,
                      style: TextStyle(
                        color: _isEditing ? Colors.black : Colors.black87,
                      ),
                    ),

                    // Przyciski Zapisz/Anuluj (tylko w trybie edycji)
                    if (_isEditing) ...[
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _cancelEditing,
                              icon: const Icon(Icons.close),
                              label: const Text('Anuluj'),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.all(16),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _saveChanges,
                              icon: const Icon(Icons.save),
                              label: const Text('Zapisz'),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.all(16),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Dialog usuwania instruktora
  Future<void> _showDeleteDialog() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Usuń instruktora'),
        content: Text(
          'Czy na pewno chcesz usunąć instruktora ${widget.instructor.fullName}?\n\nTa operacja jest nieodwracalna.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Anuluj'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Usuń'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _instructorService.deleteInstructor(widget.instructor.id);

        // Wywołaj callback
        widget.onInstructorUpdated?.call();

        if (mounted) {
          // Wróć do listy
          Navigator.pop(context);

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Instruktor usunięty'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                e.toString().contains('kursantów')
                    ? 'Nie można usunąć instruktora, który ma przypisanych kursantów'
                    : 'Błąd: $e',
              ),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
    }
  }
}
