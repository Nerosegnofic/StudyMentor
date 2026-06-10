part of 'generated.dart';

class DeleteSubjectProgressVariablesBuilder {
  String studentUid;
  String subjectKey;

  final FirebaseDataConnect _dataConnect;
  DeleteSubjectProgressVariablesBuilder(this._dataConnect, {required  this.studentUid,required  this.subjectKey,});
  Deserializer<DeleteSubjectProgressData> dataDeserializer = (dynamic json)  => DeleteSubjectProgressData.fromJson(jsonDecode(json));
  Serializer<DeleteSubjectProgressVariables> varsSerializer = (DeleteSubjectProgressVariables vars) => jsonEncode(vars.toJson());
  Future<OperationResult<DeleteSubjectProgressData, DeleteSubjectProgressVariables>> execute() {
    return ref().execute();
  }

  MutationRef<DeleteSubjectProgressData, DeleteSubjectProgressVariables> ref() {
    DeleteSubjectProgressVariables vars= DeleteSubjectProgressVariables(studentUid: studentUid,subjectKey: subjectKey,);
    return _dataConnect.mutation("DeleteSubjectProgress", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class DeleteSubjectProgressSubjectProgressDelete {
  final String studentUid;
  final String subjectKey;
  DeleteSubjectProgressSubjectProgressDelete.fromJson(dynamic json):
  
  studentUid = nativeFromJson<String>(json['studentUid']),
  subjectKey = nativeFromJson<String>(json['subjectKey']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final DeleteSubjectProgressSubjectProgressDelete otherTyped = other as DeleteSubjectProgressSubjectProgressDelete;
    return studentUid == otherTyped.studentUid && 
    subjectKey == otherTyped.subjectKey;
    
  }
  @override
  int get hashCode => Object.hashAll([studentUid.hashCode, subjectKey.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['studentUid'] = nativeToJson<String>(studentUid);
    json['subjectKey'] = nativeToJson<String>(subjectKey);
    return json;
  }

  DeleteSubjectProgressSubjectProgressDelete({
    required this.studentUid,
    required this.subjectKey,
  });
}

@immutable
class DeleteSubjectProgressData {
  final DeleteSubjectProgressSubjectProgressDelete? subjectProgress_delete;
  DeleteSubjectProgressData.fromJson(dynamic json):
  
  subjectProgress_delete = json['subjectProgress_delete'] == null ? null : DeleteSubjectProgressSubjectProgressDelete.fromJson(json['subjectProgress_delete']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final DeleteSubjectProgressData otherTyped = other as DeleteSubjectProgressData;
    return subjectProgress_delete == otherTyped.subjectProgress_delete;
    
  }
  @override
  int get hashCode => subjectProgress_delete.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    if (subjectProgress_delete != null) {
      json['subjectProgress_delete'] = subjectProgress_delete!.toJson();
    }
    return json;
  }

  DeleteSubjectProgressData({
    this.subjectProgress_delete,
  });
}

@immutable
class DeleteSubjectProgressVariables {
  final String studentUid;
  final String subjectKey;
  @Deprecated('fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  DeleteSubjectProgressVariables.fromJson(Map<String, dynamic> json):
  
  studentUid = nativeFromJson<String>(json['studentUid']),
  subjectKey = nativeFromJson<String>(json['subjectKey']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final DeleteSubjectProgressVariables otherTyped = other as DeleteSubjectProgressVariables;
    return studentUid == otherTyped.studentUid && 
    subjectKey == otherTyped.subjectKey;
    
  }
  @override
  int get hashCode => Object.hashAll([studentUid.hashCode, subjectKey.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['studentUid'] = nativeToJson<String>(studentUid);
    json['subjectKey'] = nativeToJson<String>(subjectKey);
    return json;
  }

  DeleteSubjectProgressVariables({
    required this.studentUid,
    required this.subjectKey,
  });
}

