part of 'generated.dart';

class GetUnreadNotificationEventsVariablesBuilder {
  String toParentUid;

  final FirebaseDataConnect _dataConnect;
  GetUnreadNotificationEventsVariablesBuilder(this._dataConnect, {required  this.toParentUid,});
  Deserializer<GetUnreadNotificationEventsData> dataDeserializer = (dynamic json)  => GetUnreadNotificationEventsData.fromJson(jsonDecode(json));
  Serializer<GetUnreadNotificationEventsVariables> varsSerializer = (GetUnreadNotificationEventsVariables vars) => jsonEncode(vars.toJson());
  Future<QueryResult<GetUnreadNotificationEventsData, GetUnreadNotificationEventsVariables>> execute({QueryFetchPolicy fetchPolicy = QueryFetchPolicy.preferCache}) {
    return ref().execute(fetchPolicy: fetchPolicy);
  }

  QueryRef<GetUnreadNotificationEventsData, GetUnreadNotificationEventsVariables> ref() {
    GetUnreadNotificationEventsVariables vars= GetUnreadNotificationEventsVariables(toParentUid: toParentUid,);
    return _dataConnect.query("GetUnreadNotificationEvents", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class GetUnreadNotificationEventsNotificationEvents {
  final String id;
  final String fromStudentUid;
  final String eventType;
  final String payload;
  final Timestamp createdAt;
  GetUnreadNotificationEventsNotificationEvents.fromJson(dynamic json):
  
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

    final GetUnreadNotificationEventsNotificationEvents otherTyped = other as GetUnreadNotificationEventsNotificationEvents;
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

  GetUnreadNotificationEventsNotificationEvents({
    required this.id,
    required this.fromStudentUid,
    required this.eventType,
    required this.payload,
    required this.createdAt,
  });
}

@immutable
class GetUnreadNotificationEventsData {
  final List<GetUnreadNotificationEventsNotificationEvents> notificationEvents;
  GetUnreadNotificationEventsData.fromJson(dynamic json):
  
  notificationEvents = (json['notificationEvents'] as List<dynamic>)
        .map((e) => GetUnreadNotificationEventsNotificationEvents.fromJson(e))
        .toList();
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final GetUnreadNotificationEventsData otherTyped = other as GetUnreadNotificationEventsData;
    return notificationEvents == otherTyped.notificationEvents;
    
  }
  @override
  int get hashCode => notificationEvents.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['notificationEvents'] = notificationEvents.map((e) => e.toJson()).toList();
    return json;
  }

  GetUnreadNotificationEventsData({
    required this.notificationEvents,
  });
}

@immutable
class GetUnreadNotificationEventsVariables {
  final String toParentUid;
  @Deprecated('fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  GetUnreadNotificationEventsVariables.fromJson(Map<String, dynamic> json):
  
  toParentUid = nativeFromJson<String>(json['toParentUid']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final GetUnreadNotificationEventsVariables otherTyped = other as GetUnreadNotificationEventsVariables;
    return toParentUid == otherTyped.toParentUid;
    
  }
  @override
  int get hashCode => toParentUid.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['toParentUid'] = nativeToJson<String>(toParentUid);
    return json;
  }

  GetUnreadNotificationEventsVariables({
    required this.toParentUid,
  });
}

