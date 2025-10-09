import 'package:flutter/material.dart';
import '../data/data_models.dart';

class ChildCard extends StatelessWidget {
  final Child child;
  final VoidCallback onViewStats;
  final VoidCallback onEdit;

  const ChildCard({
    super.key,
    required this.child,
    required this.onViewStats,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final info = child.userInfo;
    return Card(
      child: ListTile(
        title: Text(info.username),
        subtitle: Text('Grade ${child.config.grade}'),
        trailing: Wrap(
          spacing: 8,
          children: [
            IconButton(
              icon: const Icon(Icons.bar_chart),
              onPressed: onViewStats,
              tooltip: 'View Stats',
            ),
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: onEdit,
              tooltip: 'Edit',
            ),
          ],
        ),
      ),
    );
  }
}
