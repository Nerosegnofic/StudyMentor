part of 'generated.dart';

class InsertStudentVariablesBuilder {
  String parentUid;
  String username;
  Optional<int> _gradeLevel = Optional.optional(nativeFromJson, nativeToJson);

  final FirebaseDataConnect _dataConnect;  InsertStudentVariablesBuilder gradeLevel(int? t) {
   _gradeLevel.value = t;
   return this;
  }

  InsertStudentVariablesBuilder(this._dataConnect, {required  this.parentUid,required  this.username,});
  Deserializer<InsertStudentData> dataDeserializer = (dynamic json)  => InsertStudentData.fromJson(jsonDecode(json));
  Serializer<InsertStudentVariables> varsSerializer = (InsertStudentVariables vars) => jsonEncode(vars.toJson());
  Future<OperationResult<InsertStudentData, InsertStudentVariables>> execute() {
    return ref().execute();
  }

  MutationRef<InsertStudentData, InsertStudentVariables> ref() {
    InsertStudentVariables vars= InsertStudentVariables(parentUid: parentUid,username: username,gradeLevel: _gradeLevel,);
    return _dataConnect.mutation("InsertStudent", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class InsertStudentStudentInsert {
  final String uid;
  InsertStudentStudentInsert.fromJson(dynamic json):
  
  uid = nativeFromJson<String>(json['uid']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final InsertStudentStudentInsert otherTyped = other as InsertStudentStudentInsert;
    return uid == otherTyped.uid;
    
  }
  @override
  int get hashCode => uid.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['uid'] = nativeToJson<String>(uid);
    return json;
  }

  InsertStudentStudentInsert({
    required this.uid,
  });
}

@immutable
class InsertStudentData {
  final InsertStudentStudentInsert student_insert;
  InsertStudentData.fromJson(dynamic json):
  
  student_insert = InsertStudentStudentInsert.fromJson(json['student_insert']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final InsertStudentData otherTyped = other as InsertStudentData;
    return student_insert == otherTyped.student_insert;
    
  }
  @override
  int get hashCode => student_insert.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['student_insert'] = student_insert.toJson();
    return json;
  }

  InsertStudentData({
    required this.student_insert,
  });
}

@immutable
class InsertStudentVariables {
  final String parentUid;
  final String username;
  late final Optional<int>gradeLevel;
  @Deprecated('fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  InsertStudentVariables.fromJson(Map<String, dynamic> json):
  
  parentUid = nativeFromJson<String>(json['parentUid']),
  username = nativeFromJson<String>(json['username']) {
  
  
  
  
    gradeLevel = Optional.optional(nativeFromJson, nativeToJson);
    gradeLevel.value = json['gradeLevel'] == null ? null : nativeFromJson<int>(json['gradeLevel']);
  
  }
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final InsertStudentVariables otherTyped = other as InsertStudentVariables;
    return parentUid == otherTyped.parentUid && 
    username == otherTyped.username && 
    gradeLevel == otherTyped.gradeLevel;
    
  }
  @override
  int get hashCode => Object.hashAll([parentUid.hashCode, username.hashCode, gradeLevel.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['parentUid'] = nativeToJson<String>(parentUid);
    json['username'] = nativeToJson<String>(username);
    if(gradeLevel.state == OptionalState.set) {
      json['gradeLevel'] = gradeLevel.toJson();
    }
    return json;
  }

  InsertStudentVariables({
    required this.parentUid,
    required this.username,
    required this.gradeLevel,
  });
}

