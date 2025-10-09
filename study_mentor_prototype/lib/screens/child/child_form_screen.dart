import 'package:flutter/material.dart';
import '../../services/data_service.dart';
import '../../data/data_models.dart';
import 'package:uuid/uuid.dart';

class ChildFormScreen extends StatefulWidget {
  final DataService dataService;
  final Parent parent;
  final Child? existingChild;

  const ChildFormScreen({
    super.key,
    required this.dataService,
    required this.parent,
    this.existingChild,
  });

  @override
  State<ChildFormScreen> createState() => _ChildFormScreenState();
}

class _ChildFormScreenState extends State<ChildFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _gradeCtrl = TextEditingController();
  final _sessionCtrl = TextEditingController();
  List<String> _subjects = [];

  @override
  void initState() {
    super.initState();
    final existing = widget.existingChild;
    if (existing != null) {
      _usernameCtrl.text = existing.userInfo.username;
      _passwordCtrl.text = existing.userInfo.password;
      _gradeCtrl.text = existing.config.grade.toString();
      _sessionCtrl.text = existing.config.sessionTimeMinutes.toString();
      _subjects = List<String>.from(existing.config.subjects);
    }
  }

  Future<void> _saveChild() async {
    if (!_formKey.currentState!.validate()) return;

    final config = ChildConfig(
      grade: int.parse(_gradeCtrl.text),
      subjects: _subjects,
      sessionTimeMinutes: int.parse(_sessionCtrl.text),
    );

    if (widget.existingChild == null) {
      // new child
      final newId = const Uuid().v4();
      final newChild = Child(
        userInfo: User(
          id: newId,
          username: _usernameCtrl.text,
          password: _passwordCtrl.text,
          role: UserRole.child,
        ),
        config: config,
        quizzes: [],
        analysis: Analysis(strengths: [], weaknesses: []),
      );
      await widget.dataService.addChild(widget.parent.userInfo.id, newChild);
    } else {
      // update existing
      await widget.dataService.updateChildConfig(
        widget.existingChild!.userInfo.id,
        config,
      );
    }

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existingChild == null
            ? 'Create Child'
            : 'Edit Child'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _usernameCtrl,
                decoration: const InputDecoration(labelText: 'Child Username'),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Enter a username' : null,
              ),
              TextFormField(
                controller: _passwordCtrl,
                decoration: const InputDecoration(labelText: 'Password'),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Enter a password' : null,
              ),
              TextFormField(
                controller: _gradeCtrl,
                decoration: const InputDecoration(labelText: 'Grade'),
                keyboardType: TextInputType.number,
              ),
              TextFormField(
                controller: _sessionCtrl,
                decoration:
                    const InputDecoration(labelText: 'Session Time (minutes)'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                children: ['Math', 'Science', 'English']
                    .map(
                      (s) => FilterChip(
                        label: Text(s),
                        selected: _subjects.contains(s),
                        onSelected: (val) {
                          setState(() {
                            val
                                ? _subjects.add(s)
                                : _subjects.remove(s);
                          });
                        },
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _saveChild,
                child: const Text('Save'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
