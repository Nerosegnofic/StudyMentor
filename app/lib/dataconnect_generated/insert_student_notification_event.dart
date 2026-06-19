part of 'generated.dart';

class InsertStudentNotificationEventVariablesBuilder {
  String studentUid;
  String eventType;
  String title;
  String body;

  final FirebaseDataConnect _dataConnect;
  InsertStudentNotificationEventVariablesBuilder(this._dataConnect, {required  this.studentUid,required  this.eventType,required  this.title,required  this.body,});
  Deserializer<InsertStudentNotificationEventData> dataDeserializer = (dynamic json)  => InsertStudentNotificationEventData.fromJson(jsonDecode(json));
  Serializer<InsertStudentNotificationEventVariables> varsSerializer = (InsertStudentNotificationEventVariables vars) => jsonEncode(vars.toJson());
  Future<OperationResult<InsertStudentNotificationEventData, InsertStudentNotificationEventVariables>> execute() {
    return ref().execute();
  }

  MutationRef<InsertStudentNotificationEventData, InsertStudentNotificationEventVariables> ref() {
    InsertStudentNotificationEventVariables vars= InsertStudentNotificationEventVariables(studentUid: studentUid,eventType: eventType,title: title,body: body,);
    return _dataConnect.mutation("InsertStudentNotificationEvent", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class InsertStudentNotificationEventStudentNotificationEventInsert {
  final String id;
  InsertStudentNotificationEventStudentNotificationEventInsert.fromJson(dynamic json):
  
  id = nativeFromJson<String>(json['id']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final InsertStudentNotificationEventStudentNotificationEventInsert otherTyped = other as InsertStudentNotificationEventStudentNotificationEventInsert;
    return id == otherTyped.id;
    
  }
  @override
  int get hashCode => id.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    return json;
  }

  InsertStudentNotificationEventStudentNotificationEventInsert({
    required this.id,
  });
}

@immutable
class InsertStudentNotificationEventData {
  final InsertStudentNotificationEventStudentNotificationEventInsert studentNotificationEvent_insert;
  InsertStudentNotificationEventData.fromJson(dynamic json):
  
  studentNotificationEvent_insert = InsertStudentNotificationEventStudentNotificationEventInsert.fromJson(json['studentNotificationEvent_insert']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final InsertStudentNotificationEventData otherTyped = other as InsertStudentNotificationEventData;
    return studentNotificationEvent_insert == otherTyped.studentNotificationEvent_insert;
    
  }
  @override
  int get hashCode => studentNotificationEvent_insert.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['studentNotificationEvent_insert'] = studentNotificationEvent_insert.toJson();
    return json;
  }

  InsertStudentNotificationEventData({
    required this.studentNotificationEvent_insert,
  });
}

@immutable
class InsertStudentNotificationEventVariables {
  final String studentUid;
  final String eventType;
  final String title;
  final String body;
  @Deprecated('fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  InsertStudentNotificationEventVariables.fromJson(Map<String, dynamic> json):
  
  studentUid = nativeFromJson<String>(json['studentUid']),
  eventType = nativeFromJson<String>(json['eventType']),
  title = nativeFromJson<String>(json['title']),
  body = nativeFromJson<String>(json['body']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final InsertStudentNotificationEventVariables otherTyped = other as InsertStudentNotificationEventVariables;
    return studentUid == otherTyped.studentUid && 
    eventType == otherTyped.eventType && 
    title == otherTyped.title && 
    body == otherTyped.body;
    
  }
  @override
  int get hashCode => Object.hashAll([studentUid.hashCode, eventType.hashCode, title.hashCode, body.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['studentUid'] = nativeToJson<String>(studentUid);
    json['eventType'] = nativeToJson<String>(eventType);
    json['title'] = nativeToJson<String>(title);
    json['body'] = nativeToJson<String>(body);
    return json;
  }

  InsertStudentNotificationEventVariables({
    required this.studentUid,
    required this.eventType,
    required this.title,
    required this.body,
  });
}

