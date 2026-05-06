part of 'generated.dart';

class DeleteStudentRecordVariablesBuilder {
  String uid;

  final FirebaseDataConnect _dataConnect;
  DeleteStudentRecordVariablesBuilder(this._dataConnect, {required  this.uid,});
  Deserializer<DeleteStudentRecordData> dataDeserializer = (dynamic json)  => DeleteStudentRecordData.fromJson(jsonDecode(json));
  Serializer<DeleteStudentRecordVariables> varsSerializer = (DeleteStudentRecordVariables vars) => jsonEncode(vars.toJson());
  Future<OperationResult<DeleteStudentRecordData, DeleteStudentRecordVariables>> execute() {
    return ref().execute();
  }

  MutationRef<DeleteStudentRecordData, DeleteStudentRecordVariables> ref() {
    DeleteStudentRecordVariables vars= DeleteStudentRecordVariables(uid: uid,);
    return _dataConnect.mutation("DeleteStudentRecord", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class DeleteStudentRecordStudentDelete {
  final String uid;
  DeleteStudentRecordStudentDelete.fromJson(dynamic json):
  
  uid = nativeFromJson<String>(json['uid']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final DeleteStudentRecordStudentDelete otherTyped = other as DeleteStudentRecordStudentDelete;
    return uid == otherTyped.uid;
    
  }
  @override
  int get hashCode => uid.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['uid'] = nativeToJson<String>(uid);
    return json;
  }

  DeleteStudentRecordStudentDelete({
    required this.uid,
  });
}

@immutable
class DeleteStudentRecordData {
  final DeleteStudentRecordStudentDelete? student_delete;
  DeleteStudentRecordData.fromJson(dynamic json):
  
  student_delete = json['student_delete'] == null ? null : DeleteStudentRecordStudentDelete.fromJson(json['student_delete']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final DeleteStudentRecordData otherTyped = other as DeleteStudentRecordData;
    return student_delete == otherTyped.student_delete;
    
  }
  @override
  int get hashCode => student_delete.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    if (student_delete != null) {
      json['student_delete'] = student_delete!.toJson();
    }
    return json;
  }

  DeleteStudentRecordData({
    this.student_delete,
  });
}

@immutable
class DeleteStudentRecordVariables {
  final String uid;
  @Deprecated('fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  DeleteStudentRecordVariables.fromJson(Map<String, dynamic> json):
  
  uid = nativeFromJson<String>(json['uid']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final DeleteStudentRecordVariables otherTyped = other as DeleteStudentRecordVariables;
    return uid == otherTyped.uid;
    
  }
  @override
  int get hashCode => uid.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['uid'] = nativeToJson<String>(uid);
    return json;
  }

  DeleteStudentRecordVariables({
    required this.uid,
  });
}

