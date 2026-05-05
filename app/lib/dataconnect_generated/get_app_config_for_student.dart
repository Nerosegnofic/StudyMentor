part of 'generated.dart';

class GetAppConfigForStudentVariablesBuilder {
  String studentUid;

  final FirebaseDataConnect _dataConnect;
  GetAppConfigForStudentVariablesBuilder(this._dataConnect, {required  this.studentUid,});
  Deserializer<GetAppConfigForStudentData> dataDeserializer = (dynamic json)  => GetAppConfigForStudentData.fromJson(jsonDecode(json));
  Serializer<GetAppConfigForStudentVariables> varsSerializer = (GetAppConfigForStudentVariables vars) => jsonEncode(vars.toJson());
  Future<QueryResult<GetAppConfigForStudentData, GetAppConfigForStudentVariables>> execute() {
    return ref().execute();
  }

  QueryRef<GetAppConfigForStudentData, GetAppConfigForStudentVariables> ref() {
    GetAppConfigForStudentVariables vars= GetAppConfigForStudentVariables(studentUid: studentUid,);
    return _dataConnect.query("GetAppConfigForStudent", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class GetAppConfigForStudentAppRules {
  final String id;
  final String packageName;
  final String appLabel;
  final int? usageHours;
  final int? usageMinutes;
  final int? cooldownHours;
  final int? cooldownMinutes;
  GetAppConfigForStudentAppRules.fromJson(dynamic json):
  
  id = nativeFromJson<String>(json['id']),
  packageName = nativeFromJson<String>(json['packageName']),
  appLabel = nativeFromJson<String>(json['appLabel']),
  usageHours = json['usageHours'] == null ? null : nativeFromJson<int>(json['usageHours']),
  usageMinutes = json['usageMinutes'] == null ? null : nativeFromJson<int>(json['usageMinutes']),
  cooldownHours = json['cooldownHours'] == null ? null : nativeFromJson<int>(json['cooldownHours']),
  cooldownMinutes = json['cooldownMinutes'] == null ? null : nativeFromJson<int>(json['cooldownMinutes']);
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
    usageHours == otherTyped.usageHours && 
    usageMinutes == otherTyped.usageMinutes && 
    cooldownHours == otherTyped.cooldownHours && 
    cooldownMinutes == otherTyped.cooldownMinutes;
    
  }
  @override
  int get hashCode => Object.hashAll([id.hashCode, packageName.hashCode, appLabel.hashCode, usageHours.hashCode, usageMinutes.hashCode, cooldownHours.hashCode, cooldownMinutes.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    json['packageName'] = nativeToJson<String>(packageName);
    json['appLabel'] = nativeToJson<String>(appLabel);
    if (usageHours != null) {
      json['usageHours'] = nativeToJson<int?>(usageHours);
    }
    if (usageMinutes != null) {
      json['usageMinutes'] = nativeToJson<int?>(usageMinutes);
    }
    if (cooldownHours != null) {
      json['cooldownHours'] = nativeToJson<int?>(cooldownHours);
    }
    if (cooldownMinutes != null) {
      json['cooldownMinutes'] = nativeToJson<int?>(cooldownMinutes);
    }
    return json;
  }

  GetAppConfigForStudentAppRules({
    required this.id,
    required this.packageName,
    required this.appLabel,
    this.usageHours,
    this.usageMinutes,
    this.cooldownHours,
    this.cooldownMinutes,
  });
}

@immutable
class GetAppConfigForStudentData {
  final List<GetAppConfigForStudentAppRules> appRules;
  GetAppConfigForStudentData.fromJson(dynamic json):
  
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
    return appRules == otherTyped.appRules;
    
  }
  @override
  int get hashCode => appRules.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['appRules'] = appRules.map((e) => e.toJson()).toList();
    return json;
  }

  GetAppConfigForStudentData({
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

