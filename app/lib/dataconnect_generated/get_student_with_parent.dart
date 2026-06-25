part of 'generated.dart';

class GetStudentWithParentVariablesBuilder {
  String uid;

  final FirebaseDataConnect _dataConnect;
  GetStudentWithParentVariablesBuilder(this._dataConnect, {required  this.uid,});
  Deserializer<GetStudentWithParentData> dataDeserializer = (dynamic json)  => GetStudentWithParentData.fromJson(jsonDecode(json));
  Serializer<GetStudentWithParentVariables> varsSerializer = (GetStudentWithParentVariables vars) => jsonEncode(vars.toJson());
  Future<QueryResult<GetStudentWithParentData, GetStudentWithParentVariables>> execute({QueryFetchPolicy fetchPolicy = QueryFetchPolicy.preferCache}) {
    return ref().execute(fetchPolicy: fetchPolicy);
  }

  QueryRef<GetStudentWithParentData, GetStudentWithParentVariables> ref() {
    GetStudentWithParentVariables vars= GetStudentWithParentVariables(uid: uid,);
    return _dataConnect.query("GetStudentWithParent", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class GetStudentWithParentStudent {
  final GetStudentWithParentStudentParent parent;
  GetStudentWithParentStudent.fromJson(dynamic json):
  
  parent = GetStudentWithParentStudentParent.fromJson(json['parent']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final GetStudentWithParentStudent otherTyped = other as GetStudentWithParentStudent;
    return parent == otherTyped.parent;
    
  }
  @override
  int get hashCode => parent.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['parent'] = parent.toJson();
    return json;
  }

  GetStudentWithParentStudent({
    required this.parent,
  });
}

@immutable
class GetStudentWithParentStudentParent {
  final String uid;
  GetStudentWithParentStudentParent.fromJson(dynamic json):
  
  uid = nativeFromJson<String>(json['uid']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final GetStudentWithParentStudentParent otherTyped = other as GetStudentWithParentStudentParent;
    return uid == otherTyped.uid;
    
  }
  @override
  int get hashCode => uid.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['uid'] = nativeToJson<String>(uid);
    return json;
  }

  GetStudentWithParentStudentParent({
    required this.uid,
  });
}

@immutable
class GetStudentWithParentData {
  final GetStudentWithParentStudent? student;
  GetStudentWithParentData.fromJson(dynamic json):
  
  student = json['student'] == null ? null : GetStudentWithParentStudent.fromJson(json['student']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final GetStudentWithParentData otherTyped = other as GetStudentWithParentData;
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

  GetStudentWithParentData({
    this.student,
  });
}

@immutable
class GetStudentWithParentVariables {
  final String uid;
  @Deprecated('fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  GetStudentWithParentVariables.fromJson(Map<String, dynamic> json):
  
  uid = nativeFromJson<String>(json['uid']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final GetStudentWithParentVariables otherTyped = other as GetStudentWithParentVariables;
    return uid == otherTyped.uid;
    
  }
  @override
  int get hashCode => uid.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['uid'] = nativeToJson<String>(uid);
    return json;
  }

  GetStudentWithParentVariables({
    required this.uid,
  });
}

