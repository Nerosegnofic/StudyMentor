part of 'generated.dart';

class GetUnreadLocalNotificationEventsVariablesBuilder {
  String toParentUid;

  final FirebaseDataConnect _dataConnect;
  GetUnreadLocalNotificationEventsVariablesBuilder(this._dataConnect, {required  this.toParentUid,});
  Deserializer<GetUnreadLocalNotificationEventsData> dataDeserializer = (dynamic json)  => GetUnreadLocalNotificationEventsData.fromJson(jsonDecode(json));
  Serializer<GetUnreadLocalNotificationEventsVariables> varsSerializer = (GetUnreadLocalNotificationEventsVariables vars) => jsonEncode(vars.toJson());
  Future<QueryResult<GetUnreadLocalNotificationEventsData, GetUnreadLocalNotificationEventsVariables>> execute({QueryFetchPolicy fetchPolicy = QueryFetchPolicy.preferCache}) {
    return ref().execute(fetchPolicy: fetchPolicy);
  }

  QueryRef<GetUnreadLocalNotificationEventsData, GetUnreadLocalNotificationEventsVariables> ref() {
    GetUnreadLocalNotificationEventsVariables vars= GetUnreadLocalNotificationEventsVariables(toParentUid: toParentUid,);
    return _dataConnect.query("GetUnreadLocalNotificationEvents", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class GetUnreadLocalNotificationEventsLocalNotificationEvents {
  final String id;
  final String fromStudentUid;
  final String eventType;
  final String payload;
  final Timestamp createdAt;
  GetUnreadLocalNotificationEventsLocalNotificationEvents.fromJson(dynamic json):
  
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

    final GetUnreadLocalNotificationEventsLocalNotificationEvents otherTyped = other as GetUnreadLocalNotificationEventsLocalNotificationEvents;
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

  GetUnreadLocalNotificationEventsLocalNotificationEvents({
    required this.id,
    required this.fromStudentUid,
    required this.eventType,
    required this.payload,
    required this.createdAt,
  });
}

@immutable
class GetUnreadLocalNotificationEventsData {
  final List<GetUnreadLocalNotificationEventsLocalNotificationEvents> localNotificationEvents;
  GetUnreadLocalNotificationEventsData.fromJson(dynamic json):
  
  localNotificationEvents = (json['localNotificationEvents'] as List<dynamic>)
        .map((e) => GetUnreadLocalNotificationEventsLocalNotificationEvents.fromJson(e))
        .toList();
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final GetUnreadLocalNotificationEventsData otherTyped = other as GetUnreadLocalNotificationEventsData;
    return localNotificationEvents == otherTyped.localNotificationEvents;
    
  }
  @override
  int get hashCode => localNotificationEvents.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['localNotificationEvents'] = localNotificationEvents.map((e) => e.toJson()).toList();
    return json;
  }

  GetUnreadLocalNotificationEventsData({
    required this.localNotificationEvents,
  });
}

@immutable
class GetUnreadLocalNotificationEventsVariables {
  final String toParentUid;
  @Deprecated('fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  GetUnreadLocalNotificationEventsVariables.fromJson(Map<String, dynamic> json):
  
  toParentUid = nativeFromJson<String>(json['toParentUid']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final GetUnreadLocalNotificationEventsVariables otherTyped = other as GetUnreadLocalNotificationEventsVariables;
    return toParentUid == otherTyped.toParentUid;
    
  }
  @override
  int get hashCode => toParentUid.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['toParentUid'] = nativeToJson<String>(toParentUid);
    return json;
  }

  GetUnreadLocalNotificationEventsVariables({
    required this.toParentUid,
  });
}

