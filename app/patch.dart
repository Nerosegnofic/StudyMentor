import 'dart:io';

void main() async {
  // get_app_config_for_student.dart
  var path = "lib/dataconnect_generated/get_app_config_for_student.dart";
  var file = File(path);
  var content = await file.readAsString();
  
  content = content.replaceFirstMapped(
      RegExp(r"(final int cooldownMinutes;\n\s+GetAppConfigForStudentStudentConfig\.fromJson\(dynamic json\):\n\s+usageHours = nativeFromJson<int>\(json\['usageHours'\]\),\n\s+usageMinutes = nativeFromJson<int>\(json\['usageMinutes'\]\),\n\s+cooldownHours = nativeFromJson<int>\(json\['cooldownHours'\]\),\n\s+cooldownMinutes = nativeFromJson<int>\(json\['cooldownMinutes'\]\));"),
      (match) => "${match.group(1)},\n  quizCount = json['quizCount']?.toString() ?? 'auto';"
  );
  content = content.replaceFirst("final int cooldownMinutes;", "final int cooldownMinutes;\n  final String quizCount;");
  content = content.replaceFirst(
      "cooldownMinutes == otherTyped.cooldownMinutes;",
      "cooldownMinutes == otherTyped.cooldownMinutes && \n    quizCount == otherTyped.quizCount;"
  );
  content = content.replaceFirst(
      "Object.hashAll([usageHours.hashCode, usageMinutes.hashCode, cooldownHours.hashCode, cooldownMinutes.hashCode]);",
      "Object.hashAll([usageHours.hashCode, usageMinutes.hashCode, cooldownHours.hashCode, cooldownMinutes.hashCode, quizCount.hashCode]);"
  );
  content = content.replaceFirst(
      "json['cooldownMinutes'] = nativeToJson<int>(cooldownMinutes);\n    return json;",
      "json['cooldownMinutes'] = nativeToJson<int>(cooldownMinutes);\n    json['quizCount'] = nativeToJson<String>(quizCount);\n    return json;"
  );
  content = content.replaceFirst(
      "required this.cooldownMinutes,\n  });",
      "required this.cooldownMinutes,\n    required this.quizCount,\n  });"
  );

  content = content.replaceFirstMapped(
      RegExp(r"(final String appLabel;\n\s+GetAppConfigForStudentAppRules\.fromJson\(dynamic json\):\n\s+id = nativeFromJson<String>\(json\['id'\]\),\n\s+packageName = nativeFromJson<String>\(json\['packageName'\]\),\n\s+appLabel = nativeFromJson<String>\(json\['appLabel'\]\));"),
      (match) => "${match.group(1)},\n  isPaused = json['isPaused'] == null ? false : nativeFromJson<bool>(json['isPaused']);"
  );
  content = content.replaceFirst("final String appLabel;", "final String appLabel;\n  final bool isPaused;");
  content = content.replaceFirst(
      "appLabel == otherTyped.appLabel;",
      "appLabel == otherTyped.appLabel && \n    isPaused == otherTyped.isPaused;"
  );
  content = content.replaceFirst(
      "Object.hashAll([id.hashCode, packageName.hashCode, appLabel.hashCode]);",
      "Object.hashAll([id.hashCode, packageName.hashCode, appLabel.hashCode, isPaused.hashCode]);"
  );
  content = content.replaceFirst(
      "json['appLabel'] = nativeToJson<String>(appLabel);\n    return json;",
      "json['appLabel'] = nativeToJson<String>(appLabel);\n    json['isPaused'] = nativeToJson<bool>(isPaused);\n    return json;"
  );
  content = content.replaceFirst(
      "required this.appLabel,\n  });",
      "required this.appLabel,\n    required this.isPaused,\n  });"
  );
  await file.writeAsString(content);

  // insert_app_rule.dart
  path = "lib/dataconnect_generated/insert_app_rule.dart";
  file = File(path);
  content = await file.readAsString();

  content = content.replaceFirstMapped(
      RegExp(r"(final String appLabel;\n\s+@Deprecated\('fromJson is deprecated for Variable classes as they are no longer required for deserialization\.'\)\n\s+InsertAppRuleVariables\.fromJson\(Map<String, dynamic> json\):\n\s+studentUid = nativeFromJson<String>\(json\['studentUid'\]\),\n\s+packageName = nativeFromJson<String>\(json\['packageName'\]\),\n\s+appLabel = nativeFromJson<String>\(json\['appLabel'\]\));"),
      (match) => "${match.group(1)},\n  isPaused = json['isPaused'] == null ? null : nativeFromJson<bool>(json['isPaused']);"
  );
  content = content.replaceFirst("final String appLabel;\n  @Deprecated", "final String appLabel;\n  final bool? isPaused;\n  @Deprecated");
  content = content.replaceFirst(
      "appLabel == otherTyped.appLabel;",
      "appLabel == otherTyped.appLabel && \n    isPaused == otherTyped.isPaused;"
  );
  content = content.replaceFirst(
      "Object.hashAll([studentUid.hashCode, packageName.hashCode, appLabel.hashCode]);",
      "Object.hashAll([studentUid.hashCode, packageName.hashCode, appLabel.hashCode, isPaused.hashCode]);"
  );
  content = content.replaceFirst(
      "json['appLabel'] = nativeToJson<String>(appLabel);\n    return json;",
      "json['appLabel'] = nativeToJson<String>(appLabel);\n    if (isPaused != null) json['isPaused'] = nativeToJson<bool>(isPaused!);\n    return json;"
  );
  content = content.replaceFirst(
      "required this.appLabel,\n  });",
      "required this.appLabel,\n    this.isPaused,\n  });"
  );
  await file.writeAsString(content);

  // upsert_student_config.dart
  path = "lib/dataconnect_generated/upsert_student_config.dart";
  file = File(path);
  content = await file.readAsString();

  content = content.replaceFirstMapped(
      RegExp(r"(final int cooldownMinutes;\n\s+@Deprecated\('fromJson is deprecated for Variable classes as they are no longer required for deserialization\.'\)\n\s+UpsertStudentConfigVariables\.fromJson\(Map<String, dynamic> json\):\n\s+studentUid = nativeFromJson<String>\(json\['studentUid'\]\),\n\s+usageHours = nativeFromJson<int>\(json\['usageHours'\]\),\n\s+usageMinutes = nativeFromJson<int>\(json\['usageMinutes'\]\),\n\s+cooldownHours = nativeFromJson<int>\(json\['cooldownHours'\]\),\n\s+cooldownMinutes = nativeFromJson<int>\(json\['cooldownMinutes'\]\));"),
      (match) => "${match.group(1)},\n  quizCount = json['quizCount']?.toString() ?? 'auto';"
  );
  content = content.replaceFirst("final int cooldownMinutes;\n  @Deprecated", "final int cooldownMinutes;\n  final String quizCount;\n  @Deprecated");
  content = content.replaceFirst(
      "cooldownMinutes == otherTyped.cooldownMinutes;",
      "cooldownMinutes == otherTyped.cooldownMinutes && \n    quizCount == otherTyped.quizCount;"
  );
  content = content.replaceFirst(
      "Object.hashAll([studentUid.hashCode, usageHours.hashCode, usageMinutes.hashCode, cooldownHours.hashCode, cooldownMinutes.hashCode]);",
      "Object.hashAll([studentUid.hashCode, usageHours.hashCode, usageMinutes.hashCode, cooldownHours.hashCode, cooldownMinutes.hashCode, quizCount.hashCode]);"
  );
  content = content.replaceFirst(
      "json['cooldownMinutes'] = nativeToJson<int>(cooldownMinutes);\n    return json;",
      "json['cooldownMinutes'] = nativeToJson<int>(cooldownMinutes);\n    json['quizCount'] = nativeToJson<String>(quizCount);\n    return json;"
  );
  content = content.replaceFirst(
      "required this.cooldownMinutes,\n  });",
      "required this.cooldownMinutes,\n    required this.quizCount,\n  });"
  );
  await file.writeAsString(content);

  // Fix nativeFromJson<String> across all generated files
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
