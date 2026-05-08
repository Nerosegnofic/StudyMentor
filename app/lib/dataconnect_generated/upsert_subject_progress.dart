part of 'generated.dart';

class UpsertSubjectProgressVariablesBuilder {
  String studentUid;
  String subjectKey;
  int totalXp;
  int level;

  final FirebaseDataConnect _dataConnect;
  UpsertSubjectProgressVariablesBuilder(this._dataConnect, {required  this.studentUid,required  this.subjectKey,required  this.totalXp,required  this.level,});
  Deserializer<UpsertSubjectProgressData> dataDeserializer = (dynamic json)  => UpsertSubjectProgressData.fromJson(jsonDecode(json));
  Serializer<UpsertSubjectProgressVariables> varsSerializer = (UpsertSubjectProgressVariables vars) => jsonEncode(vars.toJson());
  Future<OperationResult<UpsertSubjectProgressData, UpsertSubjectProgressVariables>> execute() {
    return ref().execute();
  }

  MutationRef<UpsertSubjectProgressData, UpsertSubjectProgressVariables> ref() {
    UpsertSubjectProgressVariables vars= UpsertSubjectProgressVariables(studentUid: studentUid,subjectKey: subjectKey,totalXp: totalXp,level: level,);
    return _dataConnect.mutation("UpsertSubjectProgress", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class UpsertSubjectProgressSubjectProgressUpsert {
  final String studentUid;
  final String subjectKey;
  UpsertSubjectProgressSubjectProgressUpsert.fromJson(dynamic json):
  
  studentUid = nativeFromJson<String>(json['studentUid']),
  subjectKey = nativeFromJson<String>(json['subjectKey']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final UpsertSubjectProgressSubjectProgressUpsert otherTyped = other as UpsertSubjectProgressSubjectProgressUpsert;
    return studentUid == otherTyped.studentUid && 
    subjectKey == otherTyped.subjectKey;
    
  }
  @override
  int get hashCode => Object.hashAll([studentUid.hashCode, subjectKey.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['studentUid'] = nativeToJson<String>(studentUid);
    json['subjectKey'] = nativeToJson<String>(subjectKey);
    return json;
  }

  UpsertSubjectProgressSubjectProgressUpsert({
    required this.studentUid,
    required this.subjectKey,
  });
}

@immutable
class UpsertSubjectProgressData {
  final UpsertSubjectProgressSubjectProgressUpsert subjectProgress_upsert;
  UpsertSubjectProgressData.fromJson(dynamic json):
  
  subjectProgress_upsert = UpsertSubjectProgressSubjectProgressUpsert.fromJson(json['subjectProgress_upsert']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final UpsertSubjectProgressData otherTyped = other as UpsertSubjectProgressData;
    return subjectProgress_upsert == otherTyped.subjectProgress_upsert;
    
  }
  @override
  int get hashCode => subjectProgress_upsert.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['subjectProgress_upsert'] = subjectProgress_upsert.toJson();
    return json;
  }

  UpsertSubjectProgressData({
    required this.subjectProgress_upsert,
  });
}

@immutable
class UpsertSubjectProgressVariables {
  final String studentUid;
  final String subjectKey;
  final int totalXp;
  final int level;
  @Deprecated('fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  UpsertSubjectProgressVariables.fromJson(Map<String, dynamic> json):
  
  studentUid = nativeFromJson<String>(json['studentUid']),
  subjectKey = nativeFromJson<String>(json['subjectKey']),
  totalXp = nativeFromJson<int>(json['totalXp']),
  level = nativeFromJson<int>(json['level']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final UpsertSubjectProgressVariables otherTyped = other as UpsertSubjectProgressVariables;
    return studentUid == otherTyped.studentUid && 
    subjectKey == otherTyped.subjectKey && 
    totalXp == otherTyped.totalXp && 
    level == otherTyped.level;
    
  }
  @override
  int get hashCode => Object.hashAll([studentUid.hashCode, subjectKey.hashCode, totalXp.hashCode, level.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['studentUid'] = nativeToJson<String>(studentUid);
    json['subjectKey'] = nativeToJson<String>(subjectKey);
    json['totalXp'] = nativeToJson<int>(totalXp);
    json['level'] = nativeToJson<int>(level);
    return json;
  }

  UpsertSubjectProgressVariables({
    required this.studentUid,
    required this.subjectKey,
    required this.totalXp,
    required this.level,
  });
}

