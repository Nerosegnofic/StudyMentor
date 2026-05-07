part of 'generated.dart';

class DeleteStudentConfigVariablesBuilder {
  String studentUid;

  final FirebaseDataConnect _dataConnect;
  DeleteStudentConfigVariablesBuilder(this._dataConnect, {required  this.studentUid,});
  Deserializer<DeleteStudentConfigData> dataDeserializer = (dynamic json)  => DeleteStudentConfigData.fromJson(jsonDecode(json));
  Serializer<DeleteStudentConfigVariables> varsSerializer = (DeleteStudentConfigVariables vars) => jsonEncode(vars.toJson());
  Future<OperationResult<DeleteStudentConfigData, DeleteStudentConfigVariables>> execute() {
    return ref().execute();
  }

  MutationRef<DeleteStudentConfigData, DeleteStudentConfigVariables> ref() {
    DeleteStudentConfigVariables vars= DeleteStudentConfigVariables(studentUid: studentUid,);
    return _dataConnect.mutation("DeleteStudentConfig", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class DeleteStudentConfigStudentConfigDelete {
  final String studentUid;
  DeleteStudentConfigStudentConfigDelete.fromJson(dynamic json):
  
  studentUid = nativeFromJson<String>(json['studentUid']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final DeleteStudentConfigStudentConfigDelete otherTyped = other as DeleteStudentConfigStudentConfigDelete;
    return studentUid == otherTyped.studentUid;
    
  }
  @override
  int get hashCode => studentUid.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['studentUid'] = nativeToJson<String>(studentUid);
    return json;
  }

  DeleteStudentConfigStudentConfigDelete({
    required this.studentUid,
  });
}

@immutable
class DeleteStudentConfigData {
  final DeleteStudentConfigStudentConfigDelete? studentConfig_delete;
  DeleteStudentConfigData.fromJson(dynamic json):
  
  studentConfig_delete = json['studentConfig_delete'] == null ? null : DeleteStudentConfigStudentConfigDelete.fromJson(json['studentConfig_delete']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final DeleteStudentConfigData otherTyped = other as DeleteStudentConfigData;
    return studentConfig_delete == otherTyped.studentConfig_delete;
    
  }
  @override
  int get hashCode => studentConfig_delete.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    if (studentConfig_delete != null) {
      json['studentConfig_delete'] = studentConfig_delete!.toJson();
    }
    return json;
  }

  DeleteStudentConfigData({
    this.studentConfig_delete,
  });
}

@immutable
class DeleteStudentConfigVariables {
  final String studentUid;
  @Deprecated('fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  DeleteStudentConfigVariables.fromJson(Map<String, dynamic> json):
  
  studentUid = nativeFromJson<String>(json['studentUid']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final DeleteStudentConfigVariables otherTyped = other as DeleteStudentConfigVariables;
    return studentUid == otherTyped.studentUid;
    
  }
  @override
  int get hashCode => studentUid.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['studentUid'] = nativeToJson<String>(studentUid);
    return json;
  }

  DeleteStudentConfigVariables({
    required this.studentUid,
  });
}

