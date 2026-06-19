part of 'generated.dart';

class DeleteStudentNotificationEventVariablesBuilder {
  String id;

  final FirebaseDataConnect _dataConnect;
  DeleteStudentNotificationEventVariablesBuilder(this._dataConnect, {required  this.id,});
  Deserializer<DeleteStudentNotificationEventData> dataDeserializer = (dynamic json)  => DeleteStudentNotificationEventData.fromJson(jsonDecode(json));
  Serializer<DeleteStudentNotificationEventVariables> varsSerializer = (DeleteStudentNotificationEventVariables vars) => jsonEncode(vars.toJson());
  Future<OperationResult<DeleteStudentNotificationEventData, DeleteStudentNotificationEventVariables>> execute() {
    return ref().execute();
  }

  MutationRef<DeleteStudentNotificationEventData, DeleteStudentNotificationEventVariables> ref() {
    DeleteStudentNotificationEventVariables vars= DeleteStudentNotificationEventVariables(id: id,);
    return _dataConnect.mutation("DeleteStudentNotificationEvent", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class DeleteStudentNotificationEventStudentNotificationEventDelete {
  final String id;
  DeleteStudentNotificationEventStudentNotificationEventDelete.fromJson(dynamic json):
  
  id = nativeFromJson<String>(json['id']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final DeleteStudentNotificationEventStudentNotificationEventDelete otherTyped = other as DeleteStudentNotificationEventStudentNotificationEventDelete;
    return id == otherTyped.id;
    
  }
  @override
  int get hashCode => id.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    return json;
  }

  DeleteStudentNotificationEventStudentNotificationEventDelete({
    required this.id,
  });
}

@immutable
class DeleteStudentNotificationEventData {
  final DeleteStudentNotificationEventStudentNotificationEventDelete? studentNotificationEvent_delete;
  DeleteStudentNotificationEventData.fromJson(dynamic json):
  
  studentNotificationEvent_delete = json['studentNotificationEvent_delete'] == null ? null : DeleteStudentNotificationEventStudentNotificationEventDelete.fromJson(json['studentNotificationEvent_delete']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final DeleteStudentNotificationEventData otherTyped = other as DeleteStudentNotificationEventData;
    return studentNotificationEvent_delete == otherTyped.studentNotificationEvent_delete;
    
  }
  @override
  int get hashCode => studentNotificationEvent_delete.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    if (studentNotificationEvent_delete != null) {
      json['studentNotificationEvent_delete'] = studentNotificationEvent_delete!.toJson();
    }
    return json;
  }

  DeleteStudentNotificationEventData({
    this.studentNotificationEvent_delete,
  });
}

@immutable
class DeleteStudentNotificationEventVariables {
  final String id;
  @Deprecated('fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  DeleteStudentNotificationEventVariables.fromJson(Map<String, dynamic> json):
  
  id = nativeFromJson<String>(json['id']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final DeleteStudentNotificationEventVariables otherTyped = other as DeleteStudentNotificationEventVariables;
    return id == otherTyped.id;
    
  }
  @override
  int get hashCode => id.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    return json;
  }

  DeleteStudentNotificationEventVariables({
    required this.id,
  });
}

