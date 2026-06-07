part of 'generated.dart';

class GetAllSubjectProgressVariablesBuilder {
  String studentUid;

  final FirebaseDataConnect _dataConnect;
  GetAllSubjectProgressVariablesBuilder(this._dataConnect, {required  this.studentUid,});
  Deserializer<GetAllSubjectProgressData> dataDeserializer = (dynamic json)  => GetAllSubjectProgressData.fromJson(jsonDecode(json));
  Serializer<GetAllSubjectProgressVariables> varsSerializer = (GetAllSubjectProgressVariables vars) => jsonEncode(vars.toJson());
  Future<QueryResult<GetAllSubjectProgressData, GetAllSubjectProgressVariables>> execute({QueryFetchPolicy fetchPolicy = QueryFetchPolicy.preferCache}) {
    return ref().execute(fetchPolicy: fetchPolicy);
  }

  QueryRef<GetAllSubjectProgressData, GetAllSubjectProgressVariables> ref() {
    GetAllSubjectProgressVariables vars= GetAllSubjectProgressVariables(studentUid: studentUid,);
    return _dataConnect.query("GetAllSubjectProgress", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class GetAllSubjectProgressSubjectProgresses {
  final String studentUid;
  final String subjectKey;
  final int totalXp;
  final int level;
  final Timestamp updatedAt;
  GetAllSubjectProgressSubjectProgresses.fromJson(dynamic json):
  
  studentUid = nativeFromJson<String>(json['studentUid']),
  subjectKey = nativeFromJson<String>(json['subjectKey']),
  totalXp = nativeFromJson<int>(json['totalXp']),
  level = nativeFromJson<int>(json['level']),
  updatedAt = Timestamp.fromJson(json['updatedAt']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final GetAllSubjectProgressSubjectProgresses otherTyped = other as GetAllSubjectProgressSubjectProgresses;
    return studentUid == otherTyped.studentUid && 
    subjectKey == otherTyped.subjectKey && 
    totalXp == otherTyped.totalXp && 
    level == otherTyped.level && 
    updatedAt == otherTyped.updatedAt;
    
  }
  @override
  int get hashCode => Object.hashAll([studentUid.hashCode, subjectKey.hashCode, totalXp.hashCode, level.hashCode, updatedAt.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['studentUid'] = nativeToJson<String>(studentUid);
    json['subjectKey'] = nativeToJson<String>(subjectKey);
    json['totalXp'] = nativeToJson<int>(totalXp);
    json['level'] = nativeToJson<int>(level);
    json['updatedAt'] = updatedAt.toJson();
    return json;
  }

  GetAllSubjectProgressSubjectProgresses({
    required this.studentUid,
    required this.subjectKey,
    required this.totalXp,
    required this.level,
    required this.updatedAt,
  });
}

@immutable
class GetAllSubjectProgressData {
  final List<GetAllSubjectProgressSubjectProgresses> subjectProgresses;
  GetAllSubjectProgressData.fromJson(dynamic json):
  
  subjectProgresses = (json['subjectProgresses'] as List<dynamic>)
        .map((e) => GetAllSubjectProgressSubjectProgresses.fromJson(e))
        .toList();
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final GetAllSubjectProgressData otherTyped = other as GetAllSubjectProgressData;
    return subjectProgresses == otherTyped.subjectProgresses;
    
  }
  @override
  int get hashCode => subjectProgresses.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['subjectProgresses'] = subjectProgresses.map((e) => e.toJson()).toList();
    return json;
  }

  GetAllSubjectProgressData({
    required this.subjectProgresses,
  });
}

@immutable
class GetAllSubjectProgressVariables {
  final String studentUid;
  @Deprecated('fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  GetAllSubjectProgressVariables.fromJson(Map<String, dynamic> json):
  
  studentUid = nativeFromJson<String>(json['studentUid']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final GetAllSubjectProgressVariables otherTyped = other as GetAllSubjectProgressVariables;
    return studentUid == otherTyped.studentUid;
    
  }
  @override
  int get hashCode => studentUid.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['studentUid'] = nativeToJson<String>(studentUid);
    return json;
  }

  GetAllSubjectProgressVariables({
    required this.studentUid,
  });
}

