part of 'generated.dart';

class GetStudentsByParentVariablesBuilder {
  String parentUid;

  final FirebaseDataConnect _dataConnect;
  GetStudentsByParentVariablesBuilder(this._dataConnect, {required  this.parentUid,});
  Deserializer<GetStudentsByParentData> dataDeserializer = (dynamic json)  => GetStudentsByParentData.fromJson(jsonDecode(json));
  Serializer<GetStudentsByParentVariables> varsSerializer = (GetStudentsByParentVariables vars) => jsonEncode(vars.toJson());
  Future<QueryResult<GetStudentsByParentData, GetStudentsByParentVariables>> execute() {
    return ref().execute();
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
  final int? totalXp;
  final int? totalCoins;
  GetStudentsByParentStudents.fromJson(dynamic json):
  
  uid = nativeFromJson<String>(json['uid']),
  user = GetStudentsByParentStudentsUser.fromJson(json['user']),
  gradeLevel = json['gradeLevel'] == null ? null : nativeFromJson<int>(json['gradeLevel']),
  totalXp = json['totalXp'] == null ? null : nativeFromJson<int>(json['totalXp']),
  totalCoins = json['totalCoins'] == null ? null : nativeFromJson<int>(json['totalCoins']);
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
    totalXp == otherTyped.totalXp && 
    totalCoins == otherTyped.totalCoins;
    
  }
  @override
  int get hashCode => Object.hashAll([uid.hashCode, user.hashCode, gradeLevel.hashCode, totalXp.hashCode, totalCoins.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['uid'] = nativeToJson<String>(uid);
    json['user'] = user.toJson();
    if (gradeLevel != null) {
      json['gradeLevel'] = nativeToJson<int?>(gradeLevel);
    }
    if (totalXp != null) {
      json['totalXp'] = nativeToJson<int?>(totalXp);
    }
    if (totalCoins != null) {
      json['totalCoins'] = nativeToJson<int?>(totalCoins);
    }
    return json;
  }

  GetStudentsByParentStudents({
    required this.uid,
    required this.user,
    this.gradeLevel,
    this.totalXp,
    this.totalCoins,
  });
}

@immutable
class GetStudentsByParentStudentsUser {
  final String fullName;
  final String email;
  final bool isActive;
  final bool isEmailVerified;
  GetStudentsByParentStudentsUser.fromJson(dynamic json):
  
  fullName = nativeFromJson<String>(json['fullName']),
  email = nativeFromJson<String>(json['email']),
  isActive = nativeFromJson<bool>(json['isActive']),
  isEmailVerified = nativeFromJson<bool>(json['isEmailVerified']);
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
    isActive == otherTyped.isActive && 
    isEmailVerified == otherTyped.isEmailVerified;
    
  }
  @override
  int get hashCode => Object.hashAll([fullName.hashCode, email.hashCode, isActive.hashCode, isEmailVerified.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['fullName'] = nativeToJson<String>(fullName);
    json['email'] = nativeToJson<String>(email);
    json['isActive'] = nativeToJson<bool>(isActive);
    json['isEmailVerified'] = nativeToJson<bool>(isEmailVerified);
    return json;
  }

  GetStudentsByParentStudentsUser({
    required this.fullName,
    required this.email,
    required this.isActive,
    required this.isEmailVerified,
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

