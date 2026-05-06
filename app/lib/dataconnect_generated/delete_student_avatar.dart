part of 'generated.dart';

class DeleteStudentAvatarVariablesBuilder {
  String studentUid;

  final FirebaseDataConnect _dataConnect;
  DeleteStudentAvatarVariablesBuilder(this._dataConnect, {required  this.studentUid,});
  Deserializer<DeleteStudentAvatarData> dataDeserializer = (dynamic json)  => DeleteStudentAvatarData.fromJson(jsonDecode(json));
  Serializer<DeleteStudentAvatarVariables> varsSerializer = (DeleteStudentAvatarVariables vars) => jsonEncode(vars.toJson());
  Future<OperationResult<DeleteStudentAvatarData, DeleteStudentAvatarVariables>> execute() {
    return ref().execute();
  }

  MutationRef<DeleteStudentAvatarData, DeleteStudentAvatarVariables> ref() {
    DeleteStudentAvatarVariables vars= DeleteStudentAvatarVariables(studentUid: studentUid,);
    return _dataConnect.mutation("DeleteStudentAvatar", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class DeleteStudentAvatarStudentAvatarDelete {
  final String studentUid;
  DeleteStudentAvatarStudentAvatarDelete.fromJson(dynamic json):
  
  studentUid = nativeFromJson<String>(json['studentUid']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final DeleteStudentAvatarStudentAvatarDelete otherTyped = other as DeleteStudentAvatarStudentAvatarDelete;
    return studentUid == otherTyped.studentUid;
    
  }
  @override
  int get hashCode => studentUid.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['studentUid'] = nativeToJson<String>(studentUid);
    return json;
  }

  DeleteStudentAvatarStudentAvatarDelete({
    required this.studentUid,
  });
}

@immutable
class DeleteStudentAvatarData {
  final DeleteStudentAvatarStudentAvatarDelete? studentAvatar_delete;
  DeleteStudentAvatarData.fromJson(dynamic json):
  
  studentAvatar_delete = json['studentAvatar_delete'] == null ? null : DeleteStudentAvatarStudentAvatarDelete.fromJson(json['studentAvatar_delete']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final DeleteStudentAvatarData otherTyped = other as DeleteStudentAvatarData;
    return studentAvatar_delete == otherTyped.studentAvatar_delete;
    
  }
  @override
  int get hashCode => studentAvatar_delete.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    if (studentAvatar_delete != null) {
      json['studentAvatar_delete'] = studentAvatar_delete!.toJson();
    }
    return json;
  }

  DeleteStudentAvatarData({
    this.studentAvatar_delete,
  });
}

@immutable
class DeleteStudentAvatarVariables {
  final String studentUid;
  @Deprecated('fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  DeleteStudentAvatarVariables.fromJson(Map<String, dynamic> json):
  
  studentUid = nativeFromJson<String>(json['studentUid']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final DeleteStudentAvatarVariables otherTyped = other as DeleteStudentAvatarVariables;
    return studentUid == otherTyped.studentUid;
    
  }
  @override
  int get hashCode => studentUid.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['studentUid'] = nativeToJson<String>(studentUid);
    return json;
  }

  DeleteStudentAvatarVariables({
    required this.studentUid,
  });
}

