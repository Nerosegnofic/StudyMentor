part of 'generated.dart';

class GetUndispatchedLocalNotificationEventsVariablesBuilder {
  String toParentUid;

  final FirebaseDataConnect _dataConnect;
  GetUndispatchedLocalNotificationEventsVariablesBuilder(this._dataConnect, {required  this.toParentUid,});
  Deserializer<GetUndispatchedLocalNotificationEventsData> dataDeserializer = (dynamic json)  => GetUndispatchedLocalNotificationEventsData.fromJson(jsonDecode(json));
  Serializer<GetUndispatchedLocalNotificationEventsVariables> varsSerializer = (GetUndispatchedLocalNotificationEventsVariables vars) => jsonEncode(vars.toJson());
  Future<QueryResult<GetUndispatchedLocalNotificationEventsData, GetUndispatchedLocalNotificationEventsVariables>> execute({QueryFetchPolicy fetchPolicy = QueryFetchPolicy.preferCache}) {
    return ref().execute(fetchPolicy: fetchPolicy);
  }

  QueryRef<GetUndispatchedLocalNotificationEventsData, GetUndispatchedLocalNotificationEventsVariables> ref() {
    GetUndispatchedLocalNotificationEventsVariables vars= GetUndispatchedLocalNotificationEventsVariables(toParentUid: toParentUid,);
    return _dataConnect.query("GetUndispatchedLocalNotificationEvents", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class GetUndispatchedLocalNotificationEventsLocalNotificationEvents {
  final String id;
  final String fromStudentUid;
  final String eventType;
  final String payload;
  final Timestamp createdAt;
  GetUndispatchedLocalNotificationEventsLocalNotificationEvents.fromJson(dynamic json):
  
  id = nativeFromJson<String>(json['id']),
  fromStudentUid = nativeFromJson<String>(json['fromStudentUid']),
  eventType = nativeFromJson<String>(json['eventType']),
  payload = nativeFromJson<String>(json['payload']),
  createdAt = Timestamp.fromJson(json['createdAt']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final GetUndispatchedLocalNotificationEventsLocalNotificationEvents otherTyped = other as GetUndispatchedLocalNotificationEventsLocalNotificationEvents;
    return id == otherTyped.id && 
    fromStudentUid == otherTyped.fromStudentUid && 
    eventType == otherTyped.eventType && 
    payload == otherTyped.payload && 
    createdAt == otherTyped.createdAt;
    
  }
  @override
  int get hashCode => Object.hashAll([id.hashCode, fromStudentUid.hashCode, eventType.hashCode, payload.hashCode, createdAt.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    json['fromStudentUid'] = nativeToJson<String>(fromStudentUid);
    json['eventType'] = nativeToJson<String>(eventType);
    json['payload'] = nativeToJson<String>(payload);
    json['createdAt'] = createdAt.toJson();
    return json;
  }

  GetUndispatchedLocalNotificationEventsLocalNotificationEvents({
    required this.id,
    required this.fromStudentUid,
    required this.eventType,
    required this.payload,
    required this.createdAt,
  });
}

@immutable
class GetUndispatchedLocalNotificationEventsData {
  final List<GetUndispatchedLocalNotificationEventsLocalNotificationEvents> localNotificationEvents;
  GetUndispatchedLocalNotificationEventsData.fromJson(dynamic json):
  
  localNotificationEvents = (json['localNotificationEvents'] as List<dynamic>)
        .map((e) => GetUndispatchedLocalNotificationEventsLocalNotificationEvents.fromJson(e))
        .toList();
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final GetUndispatchedLocalNotificationEventsData otherTyped = other as GetUndispatchedLocalNotificationEventsData;
    return localNotificationEvents == otherTyped.localNotificationEvents;
    
  }
  @override
  int get hashCode => localNotificationEvents.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['localNotificationEvents'] = localNotificationEvents.map((e) => e.toJson()).toList();
    return json;
  }

  GetUndispatchedLocalNotificationEventsData({
    required this.localNotificationEvents,
  });
}

@immutable
class GetUndispatchedLocalNotificationEventsVariables {
  final String toParentUid;
  @Deprecated('fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  GetUndispatchedLocalNotificationEventsVariables.fromJson(Map<String, dynamic> json):
  
  toParentUid = nativeFromJson<String>(json['toParentUid']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final GetUndispatchedLocalNotificationEventsVariables otherTyped = other as GetUndispatchedLocalNotificationEventsVariables;
    return toParentUid == otherTyped.toParentUid;
    
  }
  @override
  int get hashCode => toParentUid.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['toParentUid'] = nativeToJson<String>(toParentUid);
    return json;
  }

  GetUndispatchedLocalNotificationEventsVariables({
    required this.toParentUid,
  });
}

