import re
import os

def patch_get_app_config():
    path = "lib/dataconnect_generated/get_app_config_for_student.dart"
    with open(path, "r") as f:
        content = f.read()
    
    # Add quizCount to GetAppConfigForStudentStudentConfig
    content = re.sub(
        r"(final int cooldownMinutes;\n\s+GetAppConfigForStudentStudentConfig\.fromJson\(dynamic json\):\n\s+usageHours = nativeFromJson<int>\(json\['usageHours'\]\),\n\s+usageMinutes = nativeFromJson<int>\(json\['usageMinutes'\]\),\n\s+cooldownHours = nativeFromJson<int>\(json\['cooldownHours'\]\),\n\s+cooldownMinutes = nativeFromJson<int>\(json\['cooldownMinutes'\]\));",
        r"\1,\n  quizCount = json['quizCount']?.toString() ?? 'auto';",
        content
    )
    content = content.replace("final int cooldownMinutes;", "final int cooldownMinutes;\n  final String quizCount;")
    content = content.replace(
        "cooldownMinutes == otherTyped.cooldownMinutes;\n",
        "cooldownMinutes == otherTyped.cooldownMinutes && \n    quizCount == otherTyped.quizCount;\n"
    )
    content = content.replace(
        "Object.hashAll([usageHours.hashCode, usageMinutes.hashCode, cooldownHours.hashCode, cooldownMinutes.hashCode]);",
        "Object.hashAll([usageHours.hashCode, usageMinutes.hashCode, cooldownHours.hashCode, cooldownMinutes.hashCode, quizCount.hashCode]);"
    )
    content = content.replace(
        "json['cooldownMinutes'] = nativeToJson<int>(cooldownMinutes);\n    return json;",
        "json['cooldownMinutes'] = nativeToJson<int>(cooldownMinutes);\n    json['quizCount'] = nativeToJson<String>(quizCount);\n    return json;"
    )
    content = content.replace(
        "required this.cooldownMinutes,\n  });",
        "required this.cooldownMinutes,\n    required this.quizCount,\n  });"
    )

    # Add isPaused to GetAppConfigForStudentAppRules
    content = re.sub(
        r"(final String appLabel;\n\s+GetAppConfigForStudentAppRules\.fromJson\(dynamic json\):\n\s+id = nativeFromJson<String>\(json\['id'\]\),\n\s+packageName = nativeFromJson<String>\(json\['packageName'\]\),\n\s+appLabel = nativeFromJson<String>\(json\['appLabel'\]\));",
        r"\1,\n  isPaused = json['isPaused'] == null ? false : nativeFromJson<bool>(json['isPaused']);",
        content
    )
    content = content.replace("final String appLabel;", "final String appLabel;\n  final bool isPaused;")
    content = content.replace(
        "appLabel == otherTyped.appLabel;\n",
        "appLabel == otherTyped.appLabel && \n    isPaused == otherTyped.isPaused;\n"
    )
    content = content.replace(
        "Object.hashAll([id.hashCode, packageName.hashCode, appLabel.hashCode]);",
        "Object.hashAll([id.hashCode, packageName.hashCode, appLabel.hashCode, isPaused.hashCode]);"
    )
    content = content.replace(
        "json['appLabel'] = nativeToJson<String>(appLabel);\n    return json;",
        "json['appLabel'] = nativeToJson<String>(appLabel);\n    json['isPaused'] = nativeToJson<bool>(isPaused);\n    return json;"
    )
    content = content.replace(
        "required this.appLabel,\n  });",
        "required this.appLabel,\n    required this.isPaused,\n  });"
    )
    
    with open(path, "w") as f:
        f.write(content)

def patch_insert_app_rule():
    path = "lib/dataconnect_generated/insert_app_rule.dart"
    with open(path, "r") as f:
        content = f.read()

    # Add isPaused to InsertAppRuleVariables
    content = re.sub(
        r"(final String appLabel;\n\s+@Deprecated\('fromJson is deprecated for Variable classes as they are no longer required for deserialization\.'\)\n\s+InsertAppRuleVariables\.fromJson\(Map<String, dynamic> json\):\n\s+studentUid = nativeFromJson<String>\(json\['studentUid'\]\),\n\s+packageName = nativeFromJson<String>\(json\['packageName'\]\),\n\s+appLabel = nativeFromJson<String>\(json\['appLabel'\]\));",
        r"\1,\n  isPaused = json['isPaused'] == null ? null : nativeFromJson<bool>(json['isPaused']);",
        content
    )
    content = content.replace("final String appLabel;\n  @Deprecated", "final String appLabel;\n  final bool? isPaused;\n  @Deprecated")
    content = content.replace(
        "appLabel == otherTyped.appLabel;\n",
        "appLabel == otherTyped.appLabel && \n    isPaused == otherTyped.isPaused;\n"
    )
    content = content.replace(
        "Object.hashAll([studentUid.hashCode, packageName.hashCode, appLabel.hashCode]);",
        "Object.hashAll([studentUid.hashCode, packageName.hashCode, appLabel.hashCode, isPaused.hashCode]);"
    )
    content = content.replace(
        "json['appLabel'] = nativeToJson<String>(appLabel);\n    return json;",
        "json['appLabel'] = nativeToJson<String>(appLabel);\n    if (isPaused != null) json['isPaused'] = nativeToJson<bool>(isPaused);\n    return json;"
    )
    content = content.replace(
        "required this.appLabel,\n  });",
        "required this.appLabel,\n    this.isPaused,\n  });"
    )

    with open(path, "w") as f:
        f.write(content)

def patch_upsert_student_config():
    path = "lib/dataconnect_generated/upsert_student_config.dart"
    with open(path, "r") as f:
        content = f.read()

    # Add quizCount to UpsertStudentConfigVariables
    content = re.sub(
        r"(final int cooldownMinutes;\n\s+@Deprecated\('fromJson is deprecated for Variable classes as they are no longer required for deserialization\.'\)\n\s+UpsertStudentConfigVariables\.fromJson\(Map<String, dynamic> json\):\n\s+studentUid = nativeFromJson<String>\(json\['studentUid'\]\),\n\s+usageHours = nativeFromJson<int>\(json\['usageHours'\]\),\n\s+usageMinutes = nativeFromJson<int>\(json\['usageMinutes'\]\),\n\s+cooldownHours = nativeFromJson<int>\(json\['cooldownHours'\]\),\n\s+cooldownMinutes = nativeFromJson<int>\(json\['cooldownMinutes'\]\));",
        r"\1,\n  quizCount = json['quizCount']?.toString() ?? 'auto';",
        content
    )
    content = content.replace("final int cooldownMinutes;\n  @Deprecated", "final int cooldownMinutes;\n  final String quizCount;\n  @Deprecated")
    content = content.replace(
        "cooldownMinutes == otherTyped.cooldownMinutes;\n",
        "cooldownMinutes == otherTyped.cooldownMinutes && \n    quizCount == otherTyped.quizCount;\n"
    )
    content = content.replace(
        "Object.hashAll([studentUid.hashCode, usageHours.hashCode, usageMinutes.hashCode, cooldownHours.hashCode, cooldownMinutes.hashCode]);",
        "Object.hashAll([studentUid.hashCode, usageHours.hashCode, usageMinutes.hashCode, cooldownHours.hashCode, cooldownMinutes.hashCode, quizCount.hashCode]);"
    )
    content = content.replace(
        "json['cooldownMinutes'] = nativeToJson<int>(cooldownMinutes);\n    return json;",
        "json['cooldownMinutes'] = nativeToJson<int>(cooldownMinutes);\n    json['quizCount'] = nativeToJson<String>(quizCount);\n    return json;"
    )
    content = content.replace(
        "required this.cooldownMinutes,\n  });",
        "required this.cooldownMinutes,\n    required this.quizCount,\n  });"
    )

    with open(path, "w") as f:
        f.write(content)

def fix_native_from_json_string():
    # Fix all nativeFromJson<String> globally
    for root, dirs, files in os.walk("lib/dataconnect_generated"):
        for file in files:
            if file.endswith(".dart"):
                path = os.path.join(root, file)
                with open(path, "r") as f:
                    content = f.read()
                if "nativeFromJson<String>" in content:
                    content = re.sub(r"nativeFromJson<String>\(json\['([^']+)'\]\)", r"json['\1']?.toString() ?? ''", content)
                    with open(path, "w") as f:
                        f.write(content)

if __name__ == "__main__":
    patch_get_app_config()
    patch_insert_app_rule()
    patch_upsert_student_config()
    fix_native_from_json_string()

