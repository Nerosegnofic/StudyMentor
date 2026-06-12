part of 'generated.dart';

class GetStudentProfileVariablesBuilder {
  String uid;

  final FirebaseDataConnect _dataConnect;
  GetStudentProfileVariablesBuilder(this._dataConnect, {required  this.uid,});
  Deserializer<GetStudentProfileData> dataDeserializer = (dynamic json)  => GetStudentProfileData.fromJson(jsonDecode(json));
  Serializer<GetStudentProfileVariables> varsSerializer = (GetStudentProfileVariables vars) => jsonEncode(vars.toJson());
  Future<QueryResult<GetStudentProfileData, GetStudentProfileVariables>> execute({QueryFetchPolicy fetchPolicy = QueryFetchPolicy.preferCache}) {
    return ref().execute(fetchPolicy: fetchPolicy);
  }

  QueryRef<GetStudentProfileData, GetStudentProfileVariables> ref() {
    GetStudentProfileVariables vars= GetStudentProfileVariables(uid: uid,);
    return _dataConnect.query("GetStudentProfile", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class GetStudentProfileStudent {
  final String uid;
  final String username;
  final int? gradeLevel;
  GetStudentProfileStudent.fromJson(dynamic json):
  
  uid = nativeFromJson<String>(json['uid']),
  username = nativeFromJson<String>(json['username']),
  gradeLevel = json['gradeLevel'] == null ? null : nativeFromJson<int>(json['gradeLevel']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final GetStudentProfileStudent otherTyped = other as GetStudentProfileStudent;
    return uid == otherTyped.uid && 
    username == otherTyped.username && 
    gradeLevel == otherTyped.gradeLevel;
    
  }
  @override
  int get hashCode => Object.hashAll([uid.hashCode, username.hashCode, gradeLevel.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['uid'] = nativeToJson<String>(uid);
    json['username'] = nativeToJson<String>(username);
    if (gradeLevel != null) {
      json['gradeLevel'] = nativeToJson<int?>(gradeLevel);
    }
    return json;
  }

  GetStudentProfileStudent({
    required this.uid,
    required this.username,
    this.gradeLevel,
  });
}

@immutable
class GetStudentProfileData {
  final GetStudentProfileStudent? student;
  GetStudentProfileData.fromJson(dynamic json):
  
  student = json['student'] == null ? null : GetStudentProfileStudent.fromJson(json['student']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final GetStudentProfileData otherTyped = other as GetStudentProfileData;
    return student == otherTyped.student;
    
  }
  @override
  int get hashCode => student.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    if (student != null) {
      json['student'] = student!.toJson();
    }
    return json;
  }

  GetStudentProfileData({
    this.student,
  });
}

@immutable
class GetStudentProfileVariables {
  final String uid;
  @Deprecated('fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  GetStudentProfileVariables.fromJson(Map<String, dynamic> json):
  
  uid = nativeFromJson<String>(json['uid']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final GetStudentProfileVariables otherTyped = other as GetStudentProfileVariables;
    return uid == otherTyped.uid;
    
  }
  @override
  int get hashCode => uid.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['uid'] = nativeToJson<String>(uid);
    return json;
  }

  GetStudentProfileVariables({
    required this.uid,
  });
}

