// lib/src/bloc/app_config/app_config_bloc.dart

import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/models/app_config_model.dart';
import 'app_config_event.dart';
import 'app_config_state.dart';

class AppConfigBloc extends Bloc<AppConfigEvent, AppConfigState> {
  final AuthRepository authRepository;

  AppConfigBloc({required this.authRepository}) : super(AppConfigInitial()) {
    on<LoadAppRulesRequested>(_onLoadAppRules);
    on<SaveAppRulesRequested>(_onSaveAppRules);
    on<RefreshStudentDataRequested>(_onRefreshStudentData);
  }

  String _unpackError(dynamic e) {
    try {
      final dynamic dynError = e;
      if (dynError.response != null && dynError.response.errors != null) {
        final List<dynamic> errorsList = dynError.response.errors;
        final messages = errorsList.map((err) {
          try {
            return err.message.toString();
          } catch (_) {
            return err.toString();
          }
        }).join('\n');
        if (messages.isNotEmpty) return messages;
      }
    } catch (_) {}
    return e.toString();
  }

  Future<void> _onLoadAppRules(
    LoadAppRulesRequested event,
    Emitter<AppConfigState> emit,
  ) async {
    emit(AppConfigLoading());
    try {
      final data = await authRepository.getAppConfigForStudent(event.studentUid);
      emit(
        AppRulesLoaded(
          studentUid: event.studentUid,
          rules: data.rules,
          config: data.config ?? StudentConfigModel(),
        ),
      );
    } catch (e) {
      emit(AppConfigError(_unpackError(e)));
    }
  }

  Future<void> _onSaveAppRules(
    SaveAppRulesRequested event,
    Emitter<AppConfigState> emit,
  ) async {
    emit(AppConfigSaving());
    try {
      await authRepository.saveAppConfigForStudent(
        studentUid: event.studentUid,
        rules: event.rules,
        config: event.config,
      );
      emit(AppConfigSaved());
      // Reload updated rules
      final data = await authRepository.getAppConfigForStudent(event.studentUid);
      emit(
        AppRulesLoaded(
          studentUid: event.studentUid,
          rules: data.rules,
          config: data.config ?? StudentConfigModel(),
        ),
      );
    } catch (e) {
      emit(AppConfigError(_unpackError(e)));
    }
  }

  Future<void> _onRefreshStudentData(
    RefreshStudentDataRequested event,
    Emitter<AppConfigState> emit,
  ) async {
    emit(StudentDataRefreshing());
    try {
      final data = await authRepository.getAppConfigForStudent(event.studentUid);
      emit(
        AppRulesLoaded(
          studentUid: event.studentUid,
          rules: data.rules,
          config: data.config ?? StudentConfigModel(),
        ),
      );
    } catch (e) {
      emit(AppConfigError(_unpackError(e)));
    }
  }
}
