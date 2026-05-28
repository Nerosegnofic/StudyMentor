import 'dart:io';

void main() async {
  // get_app_config_for_student.dart
  var file = File('lib/dataconnect_generated/get_app_config_for_student.dart');
  var content = await file.readAsString();
  
  content = content.replaceAll(
    'final int cooldownMinutes;\n  GetAppConfigForStudentStudentConfig.fromJson(dynamic json):',
    'final int cooldownMinutes;\n  final String quizCount;\n  GetAppConfigForStudentStudentConfig.fromJson(dynamic json):'
  );
  content = content.replaceAll(
    'cooldownMinutes = nativeFromJson<int>(json[\'cooldownMinutes\']);',
    'cooldownMinutes = nativeFromJson<int>(json[\'cooldownMinutes\']),\n  quizCount = json[\'quizCount\']?.toString() ?? \'auto\';'
  );
  content = content.replaceAll(
    'required this.cooldownMinutes,\n  });',
    'required this.cooldownMinutes,\n    required this.quizCount,\n  });'
  );

  content = content.replaceAll(
    'final String appLabel;\n  GetAppConfigForStudentAppRules.fromJson(dynamic json):',
    'final String appLabel;\n  final bool isPaused;\n  GetAppConfigForStudentAppRules.fromJson(dynamic json):'
  );
  content = content.replaceAll(
    'appLabel = nativeFromJson<String>(json[\'appLabel\']);',
    'appLabel = nativeFromJson<String>(json[\'appLabel\']),\n  isPaused = json[\'isPaused\'] == null ? false : nativeFromJson<bool>(json[\'isPaused\']);'
  );
  content = content.replaceAll(
    'required this.appLabel,\n  });',
    'required this.appLabel,\n    required this.isPaused,\n  });'
  );
  await file.writeAsString(content);

  // upsert_student_config.dart
  file = File('lib/dataconnect_generated/upsert_student_config.dart');
  content = await file.readAsString();
  content = content.replaceAll(
    'required int cooldownMinutes',
    'required int cooldownMinutes,\n    required String quizCount'
  );
  content = content.replaceAll(
    'cooldownMinutes: cooldownMinutes',
    'cooldownMinutes: cooldownMinutes,\n    quizCount: quizCount'
  );
  content = content.replaceAll(
    'final int cooldownMinutes;\n  @Deprecated',
    'final int cooldownMinutes;\n  final String quizCount;\n  @Deprecated'
  );
  content = content.replaceAll(
    'cooldownMinutes = nativeFromJson<int>(json[\'cooldownMinutes\']);',
    'cooldownMinutes = nativeFromJson<int>(json[\'cooldownMinutes\']),\n  quizCount = json[\'quizCount\']?.toString() ?? \'auto\';'
  );
  content = content.replaceAll(
    'required this.cooldownMinutes,\n  });',
    'required this.cooldownMinutes,\n    required this.quizCount,\n  });'
  );
  await file.writeAsString(content);

  // insert_app_rule.dart
  file = File('lib/dataconnect_generated/insert_app_rule.dart');
  content = await file.readAsString();
  content = content.replaceAll(
    'required String appLabel',
    'required String appLabel,\n    bool? isPaused'
  );
  content = content.replaceAll(
    'appLabel: appLabel',
    'appLabel: appLabel,\n    isPaused: isPaused'
  );
  content = content.replaceAll(
    'final String appLabel;\n  @Deprecated',
    'final String appLabel;\n  final bool? isPaused;\n  @Deprecated'
  );
  content = content.replaceAll(
    'appLabel = nativeFromJson<String>(json[\'appLabel\']);',
    'appLabel = nativeFromJson<String>(json[\'appLabel\']),\n  isPaused = json[\'isPaused\'] == null ? null : nativeFromJson<bool>(json[\'isPaused\']);'
  );
  content = content.replaceAll(
    'required this.appLabel,\n  });',
    'required this.appLabel,\n    this.isPaused,\n  });'
  );
  await file.writeAsString(content);
}
