import 'package:flutter/material.dart';
import 'package:study_mentor_prototype/services/data_service.dart';
import '../../data/data_models.dart';

class ChildStatsScreen extends StatelessWidget {
  final DataService dataService; // ✅ added this field
  final Child child;

  const ChildStatsScreen({
    super.key,
    required this.dataService, // ✅ added this parameter
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final strengths = child.analysis.strengths;
    final weaknesses = child.analysis.weaknesses;

    return Scaffold(
      appBar: AppBar(
        title: Text('${child.userInfo.username} Stats'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Strengths', style: TextStyle(fontSize: 20)),
            const SizedBox(height: 8),
            if (strengths.isEmpty)
              const Text('No strengths recorded yet.')
            else
              ...strengths.map(
                (s) => ListTile(
                  leading: const Icon(Icons.trending_up, color: Colors.green),
                  title: Text(s),
                ),
              ),
            const SizedBox(height: 16),
            const Text('Weaknesses', style: TextStyle(fontSize: 20)),
            const SizedBox(height: 8),
            if (weaknesses.isEmpty)
              const Text('No weaknesses recorded yet.')
            else
              ...weaknesses.map(
                (w) => ListTile(
                  leading: const Icon(Icons.trending_down, color: Colors.red),
                  title: Text(w),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
