part of 'generated.dart';

class DeleteStudentSettingsVariablesBuilder {
  String studentUid;

  final FirebaseDataConnect _dataConnect;
  DeleteStudentSettingsVariablesBuilder(this._dataConnect, {required  this.studentUid,});
  Deserializer<DeleteStudentSettingsData> dataDeserializer = (dynamic json)  => DeleteStudentSettingsData.fromJson(jsonDecode(json));
  Serializer<DeleteStudentSettingsVariables> varsSerializer = (DeleteStudentSettingsVariables vars) => jsonEncode(vars.toJson());
  Future<OperationResult<DeleteStudentSettingsData, DeleteStudentSettingsVariables>> execute() {
    return ref().execute();
  }

  MutationRef<DeleteStudentSettingsData, DeleteStudentSettingsVariables> ref() {
    DeleteStudentSettingsVariables vars= DeleteStudentSettingsVariables(studentUid: studentUid,);
    return _dataConnect.mutation("DeleteStudentSettings", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class DeleteStudentSettingsStudentSettingsDelete {
  final String studentUid;
  DeleteStudentSettingsStudentSettingsDelete.fromJson(dynamic json):
  
  studentUid = nativeFromJson<String>(json['studentUid']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final DeleteStudentSettingsStudentSettingsDelete otherTyped = other as DeleteStudentSettingsStudentSettingsDelete;
    return studentUid == otherTyped.studentUid;
    
  }
  @override
  int get hashCode => studentUid.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['studentUid'] = nativeToJson<String>(studentUid);
    return json;
  }

  DeleteStudentSettingsStudentSettingsDelete({
    required this.studentUid,
  });
}

@immutable
class DeleteStudentSettingsData {
  final DeleteStudentSettingsStudentSettingsDelete? studentSettings_delete;
  DeleteStudentSettingsData.fromJson(dynamic json):
  
  studentSettings_delete = json['studentSettings_delete'] == null ? null : DeleteStudentSettingsStudentSettingsDelete.fromJson(json['studentSettings_delete']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final DeleteStudentSettingsData otherTyped = other as DeleteStudentSettingsData;
    return studentSettings_delete == otherTyped.studentSettings_delete;
    
  }
  @override
  int get hashCode => studentSettings_delete.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    if (studentSettings_delete != null) {
      json['studentSettings_delete'] = studentSettings_delete!.toJson();
    }
    return json;
  }

  DeleteStudentSettingsData({
    this.studentSettings_delete,
  });
}

@immutable
class DeleteStudentSettingsVariables {
  final String studentUid;
  @Deprecated('fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  DeleteStudentSettingsVariables.fromJson(Map<String, dynamic> json):
  
  studentUid = nativeFromJson<String>(json['studentUid']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final DeleteStudentSettingsVariables otherTyped = other as DeleteStudentSettingsVariables;
    return studentUid == otherTyped.studentUid;
    
  }
  @override
  int get hashCode => studentUid.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['studentUid'] = nativeToJson<String>(studentUid);
    return json;
  }

  DeleteStudentSettingsVariables({
    required this.studentUid,
  });
}

