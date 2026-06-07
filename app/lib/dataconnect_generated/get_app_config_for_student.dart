part of 'generated.dart';

class GetAppConfigForStudentVariablesBuilder {
  String studentUid;

  final FirebaseDataConnect _dataConnect;
  GetAppConfigForStudentVariablesBuilder(this._dataConnect, {required  this.studentUid,});
  Deserializer<GetAppConfigForStudentData> dataDeserializer = (dynamic json)  => GetAppConfigForStudentData.fromJson(jsonDecode(json));
  Serializer<GetAppConfigForStudentVariables> varsSerializer = (GetAppConfigForStudentVariables vars) => jsonEncode(vars.toJson());
  Future<QueryResult<GetAppConfigForStudentData, GetAppConfigForStudentVariables>> execute({QueryFetchPolicy fetchPolicy = QueryFetchPolicy.preferCache}) {
    return ref().execute(fetchPolicy: fetchPolicy);
  }

  QueryRef<GetAppConfigForStudentData, GetAppConfigForStudentVariables> ref() {
    GetAppConfigForStudentVariables vars= GetAppConfigForStudentVariables(studentUid: studentUid,);
    return _dataConnect.query("GetAppConfigForStudent", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class GetAppConfigForStudentStudentConfig {
  final int usageHours;
  final int usageMinutes;
  final int cooldownHours;
  final int cooldownMinutes;
  final String quizCount;
  GetAppConfigForStudentStudentConfig.fromJson(dynamic json):
  
  usageHours = nativeFromJson<int>(json['usageHours']),
  usageMinutes = nativeFromJson<int>(json['usageMinutes']),
  cooldownHours = nativeFromJson<int>(json['cooldownHours']),
  cooldownMinutes = nativeFromJson<int>(json['cooldownMinutes']),
  quizCount = nativeFromJson<String>(json['quizCount'] ?? 'auto');
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final GetAppConfigForStudentStudentConfig otherTyped = other as GetAppConfigForStudentStudentConfig;
    return usageHours == otherTyped.usageHours && 
    usageMinutes == otherTyped.usageMinutes && 
    cooldownHours == otherTyped.cooldownHours && 
    cooldownMinutes == otherTyped.cooldownMinutes &&
    quizCount == otherTyped.quizCount;
    
  }
  @override
  int get hashCode => Object.hashAll([usageHours.hashCode, usageMinutes.hashCode, cooldownHours.hashCode, cooldownMinutes.hashCode, quizCount.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['usageHours'] = nativeToJson<int>(usageHours);
    json['usageMinutes'] = nativeToJson<int>(usageMinutes);
    json['cooldownHours'] = nativeToJson<int>(cooldownHours);
    json['cooldownMinutes'] = nativeToJson<int>(cooldownMinutes);
    json['quizCount'] = nativeToJson<String>(quizCount);
    return json;
  }

  GetAppConfigForStudentStudentConfig({
    required this.usageHours,
    required this.usageMinutes,
    required this.cooldownHours,
    required this.cooldownMinutes,
    required this.quizCount,
  });
}

@immutable
class GetAppConfigForStudentAppRules {
  final String id;
  final String packageName;
  final String appLabel;
  final bool isPaused;
  GetAppConfigForStudentAppRules.fromJson(dynamic json):
  
  id = nativeFromJson<String>(json['id']),
  packageName = nativeFromJson<String>(json['packageName']),
  appLabel = nativeFromJson<String>(json['appLabel']),
  isPaused = nativeFromJson<bool>(json['isPaused'] ?? false);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final GetAppConfigForStudentAppRules otherTyped = other as GetAppConfigForStudentAppRules;
    return id == otherTyped.id && 
    packageName == otherTyped.packageName && 
    appLabel == otherTyped.appLabel &&
    isPaused == otherTyped.isPaused;
    
  }
  @override
  int get hashCode => Object.hashAll([id.hashCode, packageName.hashCode, appLabel.hashCode, isPaused.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    json['packageName'] = nativeToJson<String>(packageName);
    json['appLabel'] = nativeToJson<String>(appLabel);
    json['isPaused'] = nativeToJson<bool>(isPaused);
    return json;
  }

  GetAppConfigForStudentAppRules({
    required this.id,
    required this.packageName,
    required this.appLabel,
    required this.isPaused,
  });
}

@immutable
class GetAppConfigForStudentData {
  final GetAppConfigForStudentStudentConfig? studentConfig;
  final List<GetAppConfigForStudentAppRules> appRules;
  GetAppConfigForStudentData.fromJson(dynamic json):
  
  studentConfig = json['studentConfig'] == null ? null : GetAppConfigForStudentStudentConfig.fromJson(json['studentConfig']),
  appRules = (json['appRules'] as List<dynamic>)
        .map((e) => GetAppConfigForStudentAppRules.fromJson(e))
        .toList();
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final GetAppConfigForStudentData otherTyped = other as GetAppConfigForStudentData;
    return studentConfig == otherTyped.studentConfig && 
    appRules == otherTyped.appRules;
    
  }
  @override
  int get hashCode => Object.hashAll([studentConfig.hashCode, appRules.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    if (studentConfig != null) {
      json['studentConfig'] = studentConfig!.toJson();
    }
    json['appRules'] = appRules.map((e) => e.toJson()).toList();
    return json;
  }

  GetAppConfigForStudentData({
    this.studentConfig,
    required this.appRules,
  });
}

@immutable
class GetAppConfigForStudentVariables {
  final String studentUid;
  @Deprecated('fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  GetAppConfigForStudentVariables.fromJson(Map<String, dynamic> json):
  
  studentUid = nativeFromJson<String>(json['studentUid']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final GetAppConfigForStudentVariables otherTyped = other as GetAppConfigForStudentVariables;
    return studentUid == otherTyped.studentUid;
    
  }
  @override
  int get hashCode => studentUid.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['studentUid'] = nativeToJson<String>(studentUid);
    return json;
  }

  GetAppConfigForStudentVariables({
    required this.studentUid,
  });
}

