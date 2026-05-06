part of 'generated.dart';

class GetStudentByFriendCodeVariablesBuilder {
  String friendCode;

  final FirebaseDataConnect _dataConnect;
  GetStudentByFriendCodeVariablesBuilder(this._dataConnect, {required  this.friendCode,});
  Deserializer<GetStudentByFriendCodeData> dataDeserializer = (dynamic json)  => GetStudentByFriendCodeData.fromJson(jsonDecode(json));
  Serializer<GetStudentByFriendCodeVariables> varsSerializer = (GetStudentByFriendCodeVariables vars) => jsonEncode(vars.toJson());
  Future<QueryResult<GetStudentByFriendCodeData, GetStudentByFriendCodeVariables>> execute() {
    return ref().execute();
  }

  QueryRef<GetStudentByFriendCodeData, GetStudentByFriendCodeVariables> ref() {
    GetStudentByFriendCodeVariables vars= GetStudentByFriendCodeVariables(friendCode: friendCode,);
    return _dataConnect.query("GetStudentByFriendCode", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class GetStudentByFriendCodeStudents {
  final String uid;
  final String username;
  final String? friendCode;
  final GetStudentByFriendCodeStudentsUser user;
  GetStudentByFriendCodeStudents.fromJson(dynamic json):
  
  uid = nativeFromJson<String>(json['uid']),
  username = nativeFromJson<String>(json['username']),
  friendCode = json['friendCode'] == null ? null : nativeFromJson<String>(json['friendCode']),
  user = GetStudentByFriendCodeStudentsUser.fromJson(json['user']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final GetStudentByFriendCodeStudents otherTyped = other as GetStudentByFriendCodeStudents;
    return uid == otherTyped.uid && 
    username == otherTyped.username && 
    friendCode == otherTyped.friendCode && 
    user == otherTyped.user;
    
  }
  @override
  int get hashCode => Object.hashAll([uid.hashCode, username.hashCode, friendCode.hashCode, user.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['uid'] = nativeToJson<String>(uid);
    json['username'] = nativeToJson<String>(username);
    if (friendCode != null) {
      json['friendCode'] = nativeToJson<String?>(friendCode);
    }
    json['user'] = user.toJson();
    return json;
  }

  GetStudentByFriendCodeStudents({
    required this.uid,
    required this.username,
    this.friendCode,
    required this.user,
  });
}

@immutable
class GetStudentByFriendCodeStudentsUser {
  final String fullName;
  GetStudentByFriendCodeStudentsUser.fromJson(dynamic json):
  
  fullName = nativeFromJson<String>(json['fullName']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final GetStudentByFriendCodeStudentsUser otherTyped = other as GetStudentByFriendCodeStudentsUser;
    return fullName == otherTyped.fullName;
    
  }
  @override
  int get hashCode => fullName.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['fullName'] = nativeToJson<String>(fullName);
    return json;
  }

  GetStudentByFriendCodeStudentsUser({
    required this.fullName,
  });
}

@immutable
class GetStudentByFriendCodeData {
  final List<GetStudentByFriendCodeStudents> students;
  GetStudentByFriendCodeData.fromJson(dynamic json):
  
  students = (json['students'] as List<dynamic>)
        .map((e) => GetStudentByFriendCodeStudents.fromJson(e))
        .toList();
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final GetStudentByFriendCodeData otherTyped = other as GetStudentByFriendCodeData;
    return students == otherTyped.students;
    
  }
  @override
  int get hashCode => students.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['students'] = students.map((e) => e.toJson()).toList();
    return json;
  }

  GetStudentByFriendCodeData({
    required this.students,
  });
}

@immutable
class GetStudentByFriendCodeVariables {
  final String friendCode;
  @Deprecated('fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  GetStudentByFriendCodeVariables.fromJson(Map<String, dynamic> json):
  
  friendCode = nativeFromJson<String>(json['friendCode']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final GetStudentByFriendCodeVariables otherTyped = other as GetStudentByFriendCodeVariables;
    return friendCode == otherTyped.friendCode;
    
  }
  @override
  int get hashCode => friendCode.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['friendCode'] = nativeToJson<String>(friendCode);
    return json;
  }

  GetStudentByFriendCodeVariables({
    required this.friendCode,
  });
}

