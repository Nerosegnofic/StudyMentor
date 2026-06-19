part of 'generated.dart';

class ToggleStudentNotificationEventReadVariablesBuilder {
  String id;
  bool isRead;

  final FirebaseDataConnect _dataConnect;
  ToggleStudentNotificationEventReadVariablesBuilder(this._dataConnect, {required  this.id,required  this.isRead,});
  Deserializer<ToggleStudentNotificationEventReadData> dataDeserializer = (dynamic json)  => ToggleStudentNotificationEventReadData.fromJson(jsonDecode(json));
  Serializer<ToggleStudentNotificationEventReadVariables> varsSerializer = (ToggleStudentNotificationEventReadVariables vars) => jsonEncode(vars.toJson());
  Future<OperationResult<ToggleStudentNotificationEventReadData, ToggleStudentNotificationEventReadVariables>> execute() {
    return ref().execute();
  }

  MutationRef<ToggleStudentNotificationEventReadData, ToggleStudentNotificationEventReadVariables> ref() {
    ToggleStudentNotificationEventReadVariables vars= ToggleStudentNotificationEventReadVariables(id: id,isRead: isRead,);
    return _dataConnect.mutation("ToggleStudentNotificationEventRead", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class ToggleStudentNotificationEventReadStudentNotificationEventUpdate {
  final String id;
  ToggleStudentNotificationEventReadStudentNotificationEventUpdate.fromJson(dynamic json):
  
  id = nativeFromJson<String>(json['id']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final ToggleStudentNotificationEventReadStudentNotificationEventUpdate otherTyped = other as ToggleStudentNotificationEventReadStudentNotificationEventUpdate;
    return id == otherTyped.id;
    
  }
  @override
  int get hashCode => id.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    return json;
  }

  ToggleStudentNotificationEventReadStudentNotificationEventUpdate({
    required this.id,
  });
}

@immutable
class ToggleStudentNotificationEventReadData {
  final ToggleStudentNotificationEventReadStudentNotificationEventUpdate? studentNotificationEvent_update;
  ToggleStudentNotificationEventReadData.fromJson(dynamic json):
  
  studentNotificationEvent_update = json['studentNotificationEvent_update'] == null ? null : ToggleStudentNotificationEventReadStudentNotificationEventUpdate.fromJson(json['studentNotificationEvent_update']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final ToggleStudentNotificationEventReadData otherTyped = other as ToggleStudentNotificationEventReadData;
    return studentNotificationEvent_update == otherTyped.studentNotificationEvent_update;
    
  }
  @override
  int get hashCode => studentNotificationEvent_update.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    if (studentNotificationEvent_update != null) {
      json['studentNotificationEvent_update'] = studentNotificationEvent_update!.toJson();
    }
    return json;
  }

  ToggleStudentNotificationEventReadData({
    this.studentNotificationEvent_update,
  });
}

@immutable
class ToggleStudentNotificationEventReadVariables {
  final String id;
  final bool isRead;
  @Deprecated('fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  ToggleStudentNotificationEventReadVariables.fromJson(Map<String, dynamic> json):
  
  id = nativeFromJson<String>(json['id']),
  isRead = nativeFromJson<bool>(json['isRead']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final ToggleStudentNotificationEventReadVariables otherTyped = other as ToggleStudentNotificationEventReadVariables;
    return id == otherTyped.id && 
    isRead == otherTyped.isRead;
    
  }
  @override
  int get hashCode => Object.hashAll([id.hashCode, isRead.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    json['isRead'] = nativeToJson<bool>(isRead);
    return json;
  }

  ToggleStudentNotificationEventReadVariables({
    required this.id,
    required this.isRead,
  });
}

