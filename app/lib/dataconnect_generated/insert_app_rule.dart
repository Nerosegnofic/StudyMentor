part of 'generated.dart';

class InsertAppRuleVariablesBuilder {
  String studentUid;
  String packageName;
  String appLabel;
  int usageHours;
  int usageMinutes;
  int cooldownHours;
  int cooldownMinutes;

  final FirebaseDataConnect _dataConnect;
  InsertAppRuleVariablesBuilder(this._dataConnect, {required  this.studentUid,required  this.packageName,required  this.appLabel,required  this.usageHours,required  this.usageMinutes,required  this.cooldownHours,required  this.cooldownMinutes,});
  Deserializer<InsertAppRuleData> dataDeserializer = (dynamic json)  => InsertAppRuleData.fromJson(jsonDecode(json));
  Serializer<InsertAppRuleVariables> varsSerializer = (InsertAppRuleVariables vars) => jsonEncode(vars.toJson());
  Future<OperationResult<InsertAppRuleData, InsertAppRuleVariables>> execute() {
    return ref().execute();
  }

  MutationRef<InsertAppRuleData, InsertAppRuleVariables> ref() {
    InsertAppRuleVariables vars= InsertAppRuleVariables(studentUid: studentUid,packageName: packageName,appLabel: appLabel,usageHours: usageHours,usageMinutes: usageMinutes,cooldownHours: cooldownHours,cooldownMinutes: cooldownMinutes,);
    return _dataConnect.mutation("InsertAppRule", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class InsertAppRuleAppRuleInsert {
  final String id;
  InsertAppRuleAppRuleInsert.fromJson(dynamic json):
  
  id = nativeFromJson<String>(json['id']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final InsertAppRuleAppRuleInsert otherTyped = other as InsertAppRuleAppRuleInsert;
    return id == otherTyped.id;
    
  }
  @override
  int get hashCode => id.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    return json;
  }

  InsertAppRuleAppRuleInsert({
    required this.id,
  });
}

@immutable
class InsertAppRuleData {
  final InsertAppRuleAppRuleInsert appRule_insert;
  InsertAppRuleData.fromJson(dynamic json):
  
  appRule_insert = InsertAppRuleAppRuleInsert.fromJson(json['appRule_insert']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final InsertAppRuleData otherTyped = other as InsertAppRuleData;
    return appRule_insert == otherTyped.appRule_insert;
    
  }
  @override
  int get hashCode => appRule_insert.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['appRule_insert'] = appRule_insert.toJson();
    return json;
  }

  InsertAppRuleData({
    required this.appRule_insert,
  });
}

@immutable
class InsertAppRuleVariables {
  final String studentUid;
  final String packageName;
  final String appLabel;
  final int usageHours;
  final int usageMinutes;
  final int cooldownHours;
  final int cooldownMinutes;
  @Deprecated('fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  InsertAppRuleVariables.fromJson(Map<String, dynamic> json):
  
  studentUid = nativeFromJson<String>(json['studentUid']),
  packageName = nativeFromJson<String>(json['packageName']),
  appLabel = nativeFromJson<String>(json['appLabel']),
  usageHours = nativeFromJson<int>(json['usageHours']),
  usageMinutes = nativeFromJson<int>(json['usageMinutes']),
  cooldownHours = nativeFromJson<int>(json['cooldownHours']),
  cooldownMinutes = nativeFromJson<int>(json['cooldownMinutes']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final InsertAppRuleVariables otherTyped = other as InsertAppRuleVariables;
    return studentUid == otherTyped.studentUid && 
    packageName == otherTyped.packageName && 
    appLabel == otherTyped.appLabel && 
    usageHours == otherTyped.usageHours && 
    usageMinutes == otherTyped.usageMinutes && 
    cooldownHours == otherTyped.cooldownHours && 
    cooldownMinutes == otherTyped.cooldownMinutes;
    
  }
  @override
  int get hashCode => Object.hashAll([studentUid.hashCode, packageName.hashCode, appLabel.hashCode, usageHours.hashCode, usageMinutes.hashCode, cooldownHours.hashCode, cooldownMinutes.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['studentUid'] = nativeToJson<String>(studentUid);
    json['packageName'] = nativeToJson<String>(packageName);
    json['appLabel'] = nativeToJson<String>(appLabel);
    json['usageHours'] = nativeToJson<int>(usageHours);
    json['usageMinutes'] = nativeToJson<int>(usageMinutes);
    json['cooldownHours'] = nativeToJson<int>(cooldownHours);
    json['cooldownMinutes'] = nativeToJson<int>(cooldownMinutes);
    return json;
  }

  InsertAppRuleVariables({
    required this.studentUid,
    required this.packageName,
    required this.appLabel,
    required this.usageHours,
    required this.usageMinutes,
    required this.cooldownHours,
    required this.cooldownMinutes,
  });
}

