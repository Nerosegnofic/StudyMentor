import 'package:flutter/material.dart';
import 'package:study_mentor_prototype/screens/auth/login_screen.dart';
import 'package:study_mentor_prototype/services/data_service.dart';
import 'package:study_mentor_prototype/data/data_models.dart';
import 'package:study_mentor_prototype/screens/child/child_form_screen.dart';
import 'package:study_mentor_prototype/screens/child/child_stats_screen.dart';

class ParentDashboardScreen extends StatefulWidget {
  final DataService dataService;

  const ParentDashboardScreen({super.key, required this.dataService});

  @override
  State<ParentDashboardScreen> createState() => _ParentDashboardScreenState();
}

class _ParentDashboardScreenState extends State<ParentDashboardScreen> {
  late Parent _parent;
  List<Child> _children = [];

  @override
  void initState() {
    super.initState();
    _loadParentAndChildren();
  }

  Future<void> _loadParentAndChildren() async {
    await widget.dataService.loadDatabase();
    final parents = widget.dataService.getParents();

    // Assuming the first parent is the logged-in one
    _parent = parents.first;
    final allChildren = widget.dataService.getChildren();
    _children = allChildren
        .where((c) => _parent.childrenIds.contains(c.userInfo.id))
        .toList();

    setState(() {});
  }

  Future<void> _openAddChildForm() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChildFormScreen(
          dataService: widget.dataService,
          parent: _parent,
        ),
      ),
    );
    _loadParentAndChildren(); // Refresh after returning
  }

  void _openChildStats(Child child) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChildStatsScreen(
          dataService: widget.dataService,
          child: child,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Parent Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              widget.dataService.logout();
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const LoginScreen()),
                (Route<dynamic> route) => false,
              );
            },
          ),
        ],
      ),
      body: _children.isEmpty
          ? const Center(
              child: Text(
                'No children yet. Add one to get started!',
                style: TextStyle(fontSize: 18),
              ),
            )
          : ListView.builder(
              itemCount: _children.length,
              itemBuilder: (context, index) {
                final child = _children[index];
                return Card(
                  margin: const EdgeInsets.all(8),
                  child: ListTile(
                    title: Text(child.userInfo.username),
                    subtitle: Text('Grade: ${child.config.grade}'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _openChildStats(child),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openAddChildForm,
        tooltip: 'Add Child',
        child: const Icon(Icons.add),
      ),
    );
  }
}
