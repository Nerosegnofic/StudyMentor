part of 'generated.dart';

class MarkAllStudentNotificationsReadVariablesBuilder {
  String studentUid;

  final FirebaseDataConnect _dataConnect;
  MarkAllStudentNotificationsReadVariablesBuilder(this._dataConnect, {required  this.studentUid,});
  Deserializer<MarkAllStudentNotificationsReadData> dataDeserializer = (dynamic json)  => MarkAllStudentNotificationsReadData.fromJson(jsonDecode(json));
  Serializer<MarkAllStudentNotificationsReadVariables> varsSerializer = (MarkAllStudentNotificationsReadVariables vars) => jsonEncode(vars.toJson());
  Future<OperationResult<MarkAllStudentNotificationsReadData, MarkAllStudentNotificationsReadVariables>> execute() {
    return ref().execute();
  }

  MutationRef<MarkAllStudentNotificationsReadData, MarkAllStudentNotificationsReadVariables> ref() {
    MarkAllStudentNotificationsReadVariables vars= MarkAllStudentNotificationsReadVariables(studentUid: studentUid,);
    return _dataConnect.mutation("MarkAllStudentNotificationsRead", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class MarkAllStudentNotificationsReadData {
  final int studentNotificationEvent_updateMany;
  MarkAllStudentNotificationsReadData.fromJson(dynamic json):
  
  studentNotificationEvent_updateMany = nativeFromJson<int>(json['studentNotificationEvent_updateMany']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final MarkAllStudentNotificationsReadData otherTyped = other as MarkAllStudentNotificationsReadData;
    return studentNotificationEvent_updateMany == otherTyped.studentNotificationEvent_updateMany;
    
  }
  @override
  int get hashCode => studentNotificationEvent_updateMany.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['studentNotificationEvent_updateMany'] = nativeToJson<int>(studentNotificationEvent_updateMany);
    return json;
  }

  MarkAllStudentNotificationsReadData({
    required this.studentNotificationEvent_updateMany,
  });
}

@immutable
class MarkAllStudentNotificationsReadVariables {
  final String studentUid;
  @Deprecated('fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  MarkAllStudentNotificationsReadVariables.fromJson(Map<String, dynamic> json):
  
  studentUid = nativeFromJson<String>(json['studentUid']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final MarkAllStudentNotificationsReadVariables otherTyped = other as MarkAllStudentNotificationsReadVariables;
    return studentUid == otherTyped.studentUid;
    
  }
  @override
  int get hashCode => studentUid.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['studentUid'] = nativeToJson<String>(studentUid);
    return json;
  }

  MarkAllStudentNotificationsReadVariables({
    required this.studentUid,
  });
}

