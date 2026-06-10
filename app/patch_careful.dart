import 'dart:io';

void main() async {
  // 1. get_app_config_for_student.dart
  var file = File('lib/dataconnect_generated/get_app_config_for_student.dart');
  var content = await file.readAsString();
  
  content = content.replaceFirst(
    'final int cooldownMinutes;\n  GetAppConfigForStudentStudentConfig',
    'final int cooldownMinutes;\n  final String quizCount;\n  GetAppConfigForStudentStudentConfig'
  );
  content = content.replaceFirst(
    'cooldownMinutes = nativeFromJson<int>(json[\'cooldownMinutes\']);',
    'cooldownMinutes = nativeFromJson<int>(json[\'cooldownMinutes\']),\n  quizCount = json[\'quizCount\']?.toString() ?? \'auto\';'
  );
  content = content.replaceFirst(
    'required this.cooldownMinutes,\n  });',
    'required this.cooldownMinutes,\n    required this.quizCount,\n  });'
  );
  content = content.replaceFirst(
    'cooldownMinutes == otherTyped.cooldownMinutes;',
    'cooldownMinutes == otherTyped.cooldownMinutes && \n    quizCount == otherTyped.quizCount;'
  );
  content = content.replaceFirst(
    'Object.hashAll([usageHours.hashCode, usageMinutes.hashCode, cooldownHours.hashCode, cooldownMinutes.hashCode]);',
    'Object.hashAll([usageHours.hashCode, usageMinutes.hashCode, cooldownHours.hashCode, cooldownMinutes.hashCode, quizCount.hashCode]);'
  );
  content = content.replaceFirst(
    'json[\'cooldownMinutes\'] = nativeToJson<int>(cooldownMinutes);\n    return json;',
    'json[\'cooldownMinutes\'] = nativeToJson<int>(cooldownMinutes);\n    json[\'quizCount\'] = nativeToJson<String>(quizCount);\n    return json;'
  );

  content = content.replaceFirst(
    'final String appLabel;\n  GetAppConfigForStudentAppRules',
    'final String appLabel;\n  final bool isPaused;\n  GetAppConfigForStudentAppRules'
  );
  content = content.replaceFirst(
    'appLabel = nativeFromJson<String>(json[\'appLabel\']);',
    'appLabel = nativeFromJson<String>(json[\'appLabel\']),\n  isPaused = json[\'isPaused\'] == null ? false : nativeFromJson<bool>(json[\'isPaused\']);'
  );
  content = content.replaceFirst(
    'required this.appLabel,\n  });',
    'required this.appLabel,\n    required this.isPaused,\n  });'
  );
  content = content.replaceFirst(
    'appLabel == otherTyped.appLabel;',
    'appLabel == otherTyped.appLabel && \n    isPaused == otherTyped.isPaused;'
  );
  content = content.replaceFirst(
    'Object.hashAll([id.hashCode, packageName.hashCode, appLabel.hashCode]);',
    'Object.hashAll([id.hashCode, packageName.hashCode, appLabel.hashCode, isPaused.hashCode]);'
  );
  content = content.replaceFirst(
    'json[\'appLabel\'] = nativeToJson<String>(appLabel);\n    return json;',
    'json[\'appLabel\'] = nativeToJson<String>(appLabel);\n    json[\'isPaused\'] = nativeToJson<bool>(isPaused);\n    return json;'
  );
  
  await file.writeAsString(content);

  // 2. upsert_student_config.dart
  file = File('lib/dataconnect_generated/upsert_student_config.dart');
  content = await file.readAsString();
  
  content = content.replaceFirst(
    'required int cooldownMinutes\n  })',
    'required int cooldownMinutes,\n    required String quizCount\n  })'
  );
  content = content.replaceFirst(
    'cooldownMinutes: cooldownMinutes,\n    );',
    'cooldownMinutes: cooldownMinutes,\n      quizCount: quizCount,\n    );'
  );
  content = content.replaceFirst(
    'final int cooldownMinutes;\n  @Deprecated',
    'final int cooldownMinutes;\n  final String quizCount;\n  @Deprecated'
  );
  content = content.replaceFirst(
    'cooldownMinutes = nativeFromJson<int>(json[\'cooldownMinutes\']);',
    'cooldownMinutes = nativeFromJson<int>(json[\'cooldownMinutes\']),\n  quizCount = json[\'quizCount\']?.toString() ?? \'auto\';'
  );
  content = content.replaceFirst(
    'required this.cooldownMinutes,\n  });',
    'required this.cooldownMinutes,\n    required this.quizCount,\n  });'
  );
  content = content.replaceFirst(
    'cooldownMinutes == otherTyped.cooldownMinutes;',
    'cooldownMinutes == otherTyped.cooldownMinutes && \n    quizCount == otherTyped.quizCount;'
  );
  content = content.replaceFirst(
    'Object.hashAll([studentUid.hashCode, usageHours.hashCode, usageMinutes.hashCode, cooldownHours.hashCode, cooldownMinutes.hashCode]);',
    'Object.hashAll([studentUid.hashCode, usageHours.hashCode, usageMinutes.hashCode, cooldownHours.hashCode, cooldownMinutes.hashCode, quizCount.hashCode]);'
  );
  content = content.replaceFirst(
    'json[\'cooldownMinutes\'] = nativeToJson<int>(cooldownMinutes);\n    return json;',
    'json[\'cooldownMinutes\'] = nativeToJson<int>(cooldownMinutes);\n    json[\'quizCount\'] = nativeToJson<String>(quizCount);\n    return json;'
  );
  await file.writeAsString(content);

  // 3. insert_app_rule.dart
  file = File('lib/dataconnect_generated/insert_app_rule.dart');
  content = await file.readAsString();
  
  content = content.replaceFirst(
    'required String appLabel\n  })',
    'required String appLabel,\n    bool? isPaused\n  })'
  );
  content = content.replaceFirst(
    'appLabel: appLabel,\n    );',
    'appLabel: appLabel,\n      isPaused: isPaused,\n    );'
  );
  content = content.replaceFirst(
    'final String appLabel;\n  @Deprecated',
    'final String appLabel;\n  final bool? isPaused;\n  @Deprecated'
  );
  content = content.replaceFirst(
    'appLabel = nativeFromJson<String>(json[\'appLabel\']);',
    'appLabel = nativeFromJson<String>(json[\'appLabel\']),\n  isPaused = json[\'isPaused\'] == null ? null : nativeFromJson<bool>(json[\'isPaused\']);'
  );
  content = content.replaceFirst(
    'required this.appLabel,\n  });',
    'required this.appLabel,\n    this.isPaused,\n  });'
  );
  content = content.replaceFirst(
    'appLabel == otherTyped.appLabel;',
    'appLabel == otherTyped.appLabel && \n    isPaused == otherTyped.isPaused;'
  );
  content = content.replaceFirst(
    'Object.hashAll([studentUid.hashCode, packageName.hashCode, appLabel.hashCode]);',
    'Object.hashAll([studentUid.hashCode, packageName.hashCode, appLabel.hashCode, isPaused.hashCode]);'
  );
  content = content.replaceFirst(
    'json[\'appLabel\'] = nativeToJson<String>(appLabel);\n    return json;',
    'json[\'appLabel\'] = nativeToJson<String>(appLabel);\n    if (isPaused != null) json[\'isPaused\'] = nativeToJson<bool>(isPaused!);\n    return json;'
  );
  await file.writeAsString(content);

  // Fix nativeFromJson<String> globally
  var dir = Directory('lib/dataconnect_generated');
  await for (var f in dir.list(recursive: true)) {
    if (f is File && f.path.endsWith('.dart')) {
      var c = await f.readAsString();
      if (c.contains('nativeFromJson<String>')) {
        c = c.replaceAllMapped(
            RegExp(r"nativeFromJson<String>\(json\['([^']+)'\]\)"),
            (m) => "json['${m.group(1)}']?.toString() ?? ''"
        );
        await f.writeAsString(c);
      }
    }
  }
}
