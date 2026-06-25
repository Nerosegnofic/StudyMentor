part of 'generated.dart';

class GetStudentsByParentVariablesBuilder {
  String parentUid;

  final FirebaseDataConnect _dataConnect;
  GetStudentsByParentVariablesBuilder(this._dataConnect, {required  this.parentUid,});
  Deserializer<GetStudentsByParentData> dataDeserializer = (dynamic json)  => GetStudentsByParentData.fromJson(jsonDecode(json));
  Serializer<GetStudentsByParentVariables> varsSerializer = (GetStudentsByParentVariables vars) => jsonEncode(vars.toJson());
  Future<QueryResult<GetStudentsByParentData, GetStudentsByParentVariables>> execute({QueryFetchPolicy fetchPolicy = QueryFetchPolicy.preferCache}) {
    return ref().execute(fetchPolicy: fetchPolicy);
  }

  QueryRef<GetStudentsByParentData, GetStudentsByParentVariables> ref() {
    GetStudentsByParentVariables vars= GetStudentsByParentVariables(parentUid: parentUid,);
    return _dataConnect.query("GetStudentsByParent", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class GetStudentsByParentStudents {
  final String uid;
  final GetStudentsByParentStudentsUser user;
  final int? gradeLevel;
  final Timestamp? lastActiveAt;
  GetStudentsByParentStudents.fromJson(dynamic json):
  
  uid = nativeFromJson<String>(json['uid']),
  user = GetStudentsByParentStudentsUser.fromJson(json['user']),
  gradeLevel = json['gradeLevel'] == null ? null : nativeFromJson<int>(json['gradeLevel']),
  lastActiveAt = json['lastActiveAt'] == null ? null : Timestamp.fromJson(json['lastActiveAt']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final GetStudentsByParentStudents otherTyped = other as GetStudentsByParentStudents;
    return uid == otherTyped.uid && 
    user == otherTyped.user && 
    gradeLevel == otherTyped.gradeLevel && 
    lastActiveAt == otherTyped.lastActiveAt;
    
  }
  @override
  int get hashCode => Object.hashAll([uid.hashCode, user.hashCode, gradeLevel.hashCode, lastActiveAt.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['uid'] = nativeToJson<String>(uid);
    json['user'] = user.toJson();
    if (gradeLevel != null) {
      json['gradeLevel'] = nativeToJson<int?>(gradeLevel);
    }
    if (lastActiveAt != null) {
      json['lastActiveAt'] = lastActiveAt!.toJson();
    }
    return json;
  }

  GetStudentsByParentStudents({
    required this.uid,
    required this.user,
    this.gradeLevel,
    this.lastActiveAt,
  });
}

@immutable
class GetStudentsByParentStudentsUser {
  final String fullName;
  final String email;
  final bool isEmailVerified;
  final Timestamp createdAt;
  GetStudentsByParentStudentsUser.fromJson(dynamic json):
  
  fullName = nativeFromJson<String>(json['fullName']),
  email = nativeFromJson<String>(json['email']),
  isEmailVerified = nativeFromJson<bool>(json['isEmailVerified']),
  createdAt = Timestamp.fromJson(json['createdAt']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final GetStudentsByParentStudentsUser otherTyped = other as GetStudentsByParentStudentsUser;
    return fullName == otherTyped.fullName && 
    email == otherTyped.email && 
    isEmailVerified == otherTyped.isEmailVerified && 
    createdAt == otherTyped.createdAt;
    
  }
  @override
  int get hashCode => Object.hashAll([fullName.hashCode, email.hashCode, isEmailVerified.hashCode, createdAt.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['fullName'] = nativeToJson<String>(fullName);
    json['email'] = nativeToJson<String>(email);
    json['isEmailVerified'] = nativeToJson<bool>(isEmailVerified);
    json['createdAt'] = createdAt.toJson();
    return json;
  }

  GetStudentsByParentStudentsUser({
    required this.fullName,
    required this.email,
    required this.isEmailVerified,
    required this.createdAt,
  });
}

@immutable
class GetStudentsByParentData {
  final List<GetStudentsByParentStudents> students;
  GetStudentsByParentData.fromJson(dynamic json):
  
  students = (json['students'] as List<dynamic>)
        .map((e) => GetStudentsByParentStudents.fromJson(e))
        .toList();
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final GetStudentsByParentData otherTyped = other as GetStudentsByParentData;
    return students == otherTyped.students;
    
  }
  @override
  int get hashCode => students.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['students'] = students.map((e) => e.toJson()).toList();
    return json;
  }

  GetStudentsByParentData({
    required this.students,
  });
}

@immutable
class GetStudentsByParentVariables {
  final String parentUid;
  @Deprecated('fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  GetStudentsByParentVariables.fromJson(Map<String, dynamic> json):
  
  parentUid = nativeFromJson<String>(json['parentUid']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final GetStudentsByParentVariables otherTyped = other as GetStudentsByParentVariables;
    return parentUid == otherTyped.parentUid;
    
  }
  @override
  int get hashCode => parentUid.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['parentUid'] = nativeToJson<String>(parentUid);
    return json;
  }

  GetStudentsByParentVariables({
    required this.parentUid,
  });
}

