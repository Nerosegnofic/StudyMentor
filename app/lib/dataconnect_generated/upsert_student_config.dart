part of 'generated.dart';

class UpsertStudentConfigVariablesBuilder {
  String studentUid;
  int usageHours;
  int usageMinutes;
  int cooldownHours;
  int cooldownMinutes;

  final FirebaseDataConnect _dataConnect;
  UpsertStudentConfigVariablesBuilder(this._dataConnect, {required  this.studentUid,required  this.usageHours,required  this.usageMinutes,required  this.cooldownHours,required  this.cooldownMinutes,});
  Deserializer<UpsertStudentConfigData> dataDeserializer = (dynamic json)  => UpsertStudentConfigData.fromJson(jsonDecode(json));
  Serializer<UpsertStudentConfigVariables> varsSerializer = (UpsertStudentConfigVariables vars) => jsonEncode(vars.toJson());
  Future<OperationResult<UpsertStudentConfigData, UpsertStudentConfigVariables>> execute() {
    return ref().execute();
  }

  MutationRef<UpsertStudentConfigData, UpsertStudentConfigVariables> ref() {
    UpsertStudentConfigVariables vars= UpsertStudentConfigVariables(studentUid: studentUid,usageHours: usageHours,usageMinutes: usageMinutes,cooldownHours: cooldownHours,cooldownMinutes: cooldownMinutes,);
    return _dataConnect.mutation("UpsertStudentConfig", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class UpsertStudentConfigStudentConfigUpsert {
  final String studentUid;
  UpsertStudentConfigStudentConfigUpsert.fromJson(dynamic json):
  
  studentUid = nativeFromJson<String>(json['studentUid']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final UpsertStudentConfigStudentConfigUpsert otherTyped = other as UpsertStudentConfigStudentConfigUpsert;
    return studentUid == otherTyped.studentUid;
    
  }
  @override
  int get hashCode => studentUid.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['studentUid'] = nativeToJson<String>(studentUid);
    return json;
  }

  UpsertStudentConfigStudentConfigUpsert({
    required this.studentUid,
  });
}

@immutable
class UpsertStudentConfigData {
  final UpsertStudentConfigStudentConfigUpsert studentConfig_upsert;
  UpsertStudentConfigData.fromJson(dynamic json):
  
  studentConfig_upsert = UpsertStudentConfigStudentConfigUpsert.fromJson(json['studentConfig_upsert']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final UpsertStudentConfigData otherTyped = other as UpsertStudentConfigData;
    return studentConfig_upsert == otherTyped.studentConfig_upsert;
    
  }
  @override
  int get hashCode => studentConfig_upsert.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['studentConfig_upsert'] = studentConfig_upsert.toJson();
    return json;
  }

  UpsertStudentConfigData({
    required this.studentConfig_upsert,
  });
}

@immutable
class UpsertStudentConfigVariables {
  final String studentUid;
  final int usageHours;
  final int usageMinutes;
  final int cooldownHours;
  final int cooldownMinutes;
  @Deprecated('fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  UpsertStudentConfigVariables.fromJson(Map<String, dynamic> json):
  
  studentUid = nativeFromJson<String>(json['studentUid']),
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

    final UpsertStudentConfigVariables otherTyped = other as UpsertStudentConfigVariables;
    return studentUid == otherTyped.studentUid && 
    usageHours == otherTyped.usageHours && 
    usageMinutes == otherTyped.usageMinutes && 
    cooldownHours == otherTyped.cooldownHours && 
    cooldownMinutes == otherTyped.cooldownMinutes;
    
  }
  @override
  int get hashCode => Object.hashAll([studentUid.hashCode, usageHours.hashCode, usageMinutes.hashCode, cooldownHours.hashCode, cooldownMinutes.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['studentUid'] = nativeToJson<String>(studentUid);
    json['usageHours'] = nativeToJson<int>(usageHours);
    json['usageMinutes'] = nativeToJson<int>(usageMinutes);
    json['cooldownHours'] = nativeToJson<int>(cooldownHours);
    json['cooldownMinutes'] = nativeToJson<int>(cooldownMinutes);
    return json;
  }

  UpsertStudentConfigVariables({
    required this.studentUid,
    required this.usageHours,
    required this.usageMinutes,
    required this.cooldownHours,
    required this.cooldownMinutes,
  });
}

