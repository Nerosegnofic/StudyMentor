part of 'generated.dart';

class GetStudentByUsernameVariablesBuilder {
  String username;

  final FirebaseDataConnect _dataConnect;
  GetStudentByUsernameVariablesBuilder(this._dataConnect, {required  this.username,});
  Deserializer<GetStudentByUsernameData> dataDeserializer = (dynamic json)  => GetStudentByUsernameData.fromJson(jsonDecode(json));
  Serializer<GetStudentByUsernameVariables> varsSerializer = (GetStudentByUsernameVariables vars) => jsonEncode(vars.toJson());
  Future<QueryResult<GetStudentByUsernameData, GetStudentByUsernameVariables>> execute() {
    return ref().execute();
  }

  QueryRef<GetStudentByUsernameData, GetStudentByUsernameVariables> ref() {
    GetStudentByUsernameVariables vars= GetStudentByUsernameVariables(username: username,);
    return _dataConnect.query("GetStudentByUsername", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class GetStudentByUsernameStudents {
  final String uid;
  GetStudentByUsernameStudents.fromJson(dynamic json):
  
  uid = nativeFromJson<String>(json['uid']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final GetStudentByUsernameStudents otherTyped = other as GetStudentByUsernameStudents;
    return uid == otherTyped.uid;
    
  }
  @override
  int get hashCode => uid.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['uid'] = nativeToJson<String>(uid);
    return json;
  }

  GetStudentByUsernameStudents({
    required this.uid,
  });
}

@immutable
class GetStudentByUsernameData {
  final List<GetStudentByUsernameStudents> students;
  GetStudentByUsernameData.fromJson(dynamic json):
  
  students = (json['students'] as List<dynamic>)
        .map((e) => GetStudentByUsernameStudents.fromJson(e))
        .toList();
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final GetStudentByUsernameData otherTyped = other as GetStudentByUsernameData;
    return students == otherTyped.students;
    
  }
  @override
  int get hashCode => students.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['students'] = students.map((e) => e.toJson()).toList();
    return json;
  }

  GetStudentByUsernameData({
    required this.students,
  });
}

@immutable
class GetStudentByUsernameVariables {
  final String username;
  @Deprecated('fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  GetStudentByUsernameVariables.fromJson(Map<String, dynamic> json):
  
  username = nativeFromJson<String>(json['username']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final GetStudentByUsernameVariables otherTyped = other as GetStudentByUsernameVariables;
    return username == otherTyped.username;
    
  }
  @override
  int get hashCode => username.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['username'] = nativeToJson<String>(username);
    return json;
  }

  GetStudentByUsernameVariables({
    required this.username,
  });
}

