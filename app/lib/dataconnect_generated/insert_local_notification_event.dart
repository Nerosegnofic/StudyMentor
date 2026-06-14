part of 'generated.dart';

class InsertLocalNotificationEventVariablesBuilder {
  String fromStudentUid;
  String toParentUid;
  String eventType;
  String payload;

  final FirebaseDataConnect _dataConnect;
  InsertLocalNotificationEventVariablesBuilder(this._dataConnect, {required  this.fromStudentUid,required  this.toParentUid,required  this.eventType,required  this.payload,});
  Deserializer<InsertLocalNotificationEventData> dataDeserializer = (dynamic json)  => InsertLocalNotificationEventData.fromJson(jsonDecode(json));
  Serializer<InsertLocalNotificationEventVariables> varsSerializer = (InsertLocalNotificationEventVariables vars) => jsonEncode(vars.toJson());
  Future<OperationResult<InsertLocalNotificationEventData, InsertLocalNotificationEventVariables>> execute() {
    return ref().execute();
  }

  MutationRef<InsertLocalNotificationEventData, InsertLocalNotificationEventVariables> ref() {
    InsertLocalNotificationEventVariables vars= InsertLocalNotificationEventVariables(fromStudentUid: fromStudentUid,toParentUid: toParentUid,eventType: eventType,payload: payload,);
    return _dataConnect.mutation("InsertLocalNotificationEvent", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class InsertLocalNotificationEventLocalNotificationEventInsert {
  final String id;
  InsertLocalNotificationEventLocalNotificationEventInsert.fromJson(dynamic json):
  
  id = nativeFromJson<String>(json['id']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final InsertLocalNotificationEventLocalNotificationEventInsert otherTyped = other as InsertLocalNotificationEventLocalNotificationEventInsert;
    return id == otherTyped.id;
    
  }
  @override
  int get hashCode => id.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    return json;
  }

  InsertLocalNotificationEventLocalNotificationEventInsert({
    required this.id,
  });
}

@immutable
class InsertLocalNotificationEventData {
  final InsertLocalNotificationEventLocalNotificationEventInsert localNotificationEvent_insert;
  InsertLocalNotificationEventData.fromJson(dynamic json):
  
  localNotificationEvent_insert = InsertLocalNotificationEventLocalNotificationEventInsert.fromJson(json['localNotificationEvent_insert']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final InsertLocalNotificationEventData otherTyped = other as InsertLocalNotificationEventData;
    return localNotificationEvent_insert == otherTyped.localNotificationEvent_insert;
    
  }
  @override
  int get hashCode => localNotificationEvent_insert.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['localNotificationEvent_insert'] = localNotificationEvent_insert.toJson();
    return json;
  }

  InsertLocalNotificationEventData({
    required this.localNotificationEvent_insert,
  });
}

@immutable
class InsertLocalNotificationEventVariables {
  final String fromStudentUid;
  final String toParentUid;
  final String eventType;
  final String payload;
  @Deprecated('fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  InsertLocalNotificationEventVariables.fromJson(Map<String, dynamic> json):
  
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

    final InsertLocalNotificationEventVariables otherTyped = other as InsertLocalNotificationEventVariables;
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

  InsertLocalNotificationEventVariables({
    required this.fromStudentUid,
    required this.toParentUid,
    required this.eventType,
    required this.payload,
  });
}

