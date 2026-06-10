// lib/src/bloc/app_config/app_config_event.dart

import 'package:equatable/equatable.dart';
import '../../domain/models/app_config_model.dart';

abstract class AppConfigEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoadAppRulesRequested extends AppConfigEvent {
  final String studentUid;
  LoadAppRulesRequested({required this.studentUid});

  @override
  List<Object?> get props => [studentUid];
}

class SaveAppRulesRequested extends AppConfigEvent {
  final String studentUid;
  final List<PendingAppRule> rules;
  final StudentConfigModel config;

  SaveAppRulesRequested({
    required this.studentUid,
    required this.rules,
    required this.config,
  });

  @override
  List<Object?> get props => [studentUid, rules, config];
}

class RefreshStudentDataRequested extends AppConfigEvent {
  final String studentUid;
  RefreshStudentDataRequested({required this.studentUid});

  @override
  List<Object?> get props => [studentUid];
}
