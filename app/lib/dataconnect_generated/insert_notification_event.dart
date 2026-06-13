part of 'generated.dart';

class InsertNotificationEventVariablesBuilder {
  String fromStudentUid;
  String toParentUid;
  String eventType;
  String payload;

  final FirebaseDataConnect _dataConnect;
  InsertNotificationEventVariablesBuilder(this._dataConnect, {required  this.fromStudentUid,required  this.toParentUid,required  this.eventType,required  this.payload,});
  Deserializer<InsertNotificationEventData> dataDeserializer = (dynamic json)  => InsertNotificationEventData.fromJson(jsonDecode(json));
  Serializer<InsertNotificationEventVariables> varsSerializer = (InsertNotificationEventVariables vars) => jsonEncode(vars.toJson());
  Future<OperationResult<InsertNotificationEventData, InsertNotificationEventVariables>> execute() {
    return ref().execute();
  }

  MutationRef<InsertNotificationEventData, InsertNotificationEventVariables> ref() {
    InsertNotificationEventVariables vars= InsertNotificationEventVariables(fromStudentUid: fromStudentUid,toParentUid: toParentUid,eventType: eventType,payload: payload,);
    return _dataConnect.mutation("InsertNotificationEvent", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class InsertNotificationEventNotificationEventInsert {
  final String id;
  InsertNotificationEventNotificationEventInsert.fromJson(dynamic json):
  
  id = nativeFromJson<String>(json['id']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final InsertNotificationEventNotificationEventInsert otherTyped = other as InsertNotificationEventNotificationEventInsert;
    return id == otherTyped.id;
    
  }
  @override
  int get hashCode => id.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    return json;
  }

  InsertNotificationEventNotificationEventInsert({
    required this.id,
  });
}

@immutable
class InsertNotificationEventData {
  final InsertNotificationEventNotificationEventInsert notificationEvent_insert;
  InsertNotificationEventData.fromJson(dynamic json):
  
  notificationEvent_insert = InsertNotificationEventNotificationEventInsert.fromJson(json['notificationEvent_insert']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final InsertNotificationEventData otherTyped = other as InsertNotificationEventData;
    return notificationEvent_insert == otherTyped.notificationEvent_insert;
    
  }
  @override
  int get hashCode => notificationEvent_insert.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['notificationEvent_insert'] = notificationEvent_insert.toJson();
    return json;
  }

  InsertNotificationEventData({
    required this.notificationEvent_insert,
  });
}

@immutable
class InsertNotificationEventVariables {
  final String fromStudentUid;
  final String toParentUid;
  final String eventType;
  final String payload;
  @Deprecated('fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  InsertNotificationEventVariables.fromJson(Map<String, dynamic> json):
  
  fromStudentUid = nativeFromJson<String>(json['fromStudentUid']),
  toParentUid = nativeFromJson<String>(json['toParentUid']),
  eventType = nativeFromJson<String>(json['eventType']),
  payload = nativeFromJson<String>(json['payload']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final InsertNotificationEventVariables otherTyped = other as InsertNotificationEventVariables;
    return fromStudentUid == otherTyped.fromStudentUid && 
    toParentUid == otherTyped.toParentUid && 
    eventType == otherTyped.eventType && 
    payload == otherTyped.payload;
    
  }
  @override
  int get hashCode => Object.hashAll([fromStudentUid.hashCode, toParentUid.hashCode, eventType.hashCode, payload.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['fromStudentUid'] = nativeToJson<String>(fromStudentUid);
    json['toParentUid'] = nativeToJson<String>(toParentUid);
    json['eventType'] = nativeToJson<String>(eventType);
    json['payload'] = nativeToJson<String>(payload);
    return json;
  }

  InsertNotificationEventVariables({
    required this.fromStudentUid,
    required this.toParentUid,
    required this.eventType,
    required this.payload,
  });
}

