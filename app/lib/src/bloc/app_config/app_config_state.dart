// lib/src/bloc/app_config/app_config_state.dart

import 'package:equatable/equatable.dart';
import '../../domain/models/app_config_model.dart';

abstract class AppConfigState extends Equatable {
  @override
  List<Object?> get props => [];
}

class AppConfigInitial extends AppConfigState {}

class AppConfigLoading extends AppConfigState {}

class AppRulesLoaded extends AppConfigState {
  final String studentUid;
  final List<AppRuleModel> rules;
  final StudentConfigModel config;

  AppRulesLoaded({
    required this.studentUid,
    required this.rules,
    required this.config,
  });

  @override
  List<Object?> get props => [studentUid, rules, config];
}

class AppConfigSaving extends AppConfigState {}

class AppConfigSaved extends AppConfigState {}

class AppConfigError extends AppConfigState {
  final String message;
  AppConfigError(this.message);

  @override
  List<Object?> get props => [message];
}

class StudentDataRefreshing extends AppConfigState {}
