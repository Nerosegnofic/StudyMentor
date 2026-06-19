part of 'generated.dart';

class GetAllLocalNotificationEventsForParentVariablesBuilder {
  String toParentUid;

  final FirebaseDataConnect _dataConnect;
  GetAllLocalNotificationEventsForParentVariablesBuilder(this._dataConnect, {required  this.toParentUid,});
  Deserializer<GetAllLocalNotificationEventsForParentData> dataDeserializer = (dynamic json)  => GetAllLocalNotificationEventsForParentData.fromJson(jsonDecode(json));
  Serializer<GetAllLocalNotificationEventsForParentVariables> varsSerializer = (GetAllLocalNotificationEventsForParentVariables vars) => jsonEncode(vars.toJson());
  Future<QueryResult<GetAllLocalNotificationEventsForParentData, GetAllLocalNotificationEventsForParentVariables>> execute({QueryFetchPolicy fetchPolicy = QueryFetchPolicy.preferCache}) {
    return ref().execute(fetchPolicy: fetchPolicy);
  }

  QueryRef<GetAllLocalNotificationEventsForParentData, GetAllLocalNotificationEventsForParentVariables> ref() {
    GetAllLocalNotificationEventsForParentVariables vars= GetAllLocalNotificationEventsForParentVariables(toParentUid: toParentUid,);
    return _dataConnect.query("GetAllLocalNotificationEventsForParent", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class GetAllLocalNotificationEventsForParentLocalNotificationEvents {
  final String id;
  final String fromStudentUid;
  final String eventType;
  final String payload;
  final Timestamp createdAt;
  final bool isRead;
  GetAllLocalNotificationEventsForParentLocalNotificationEvents.fromJson(dynamic json):
  
  id = nativeFromJson<String>(json['id']),
  fromStudentUid = nativeFromJson<String>(json['fromStudentUid']),
  eventType = nativeFromJson<String>(json['eventType']),
  payload = nativeFromJson<String>(json['payload']),
  createdAt = Timestamp.fromJson(json['createdAt']),
  isRead = nativeFromJson<bool>(json['isRead']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final GetAllLocalNotificationEventsForParentLocalNotificationEvents otherTyped = other as GetAllLocalNotificationEventsForParentLocalNotificationEvents;
    return id == otherTyped.id && 
    fromStudentUid == otherTyped.fromStudentUid && 
    eventType == otherTyped.eventType && 
    payload == otherTyped.payload && 
    createdAt == otherTyped.createdAt && 
    isRead == otherTyped.isRead;
    
  }
  @override
  int get hashCode => Object.hashAll([id.hashCode, fromStudentUid.hashCode, eventType.hashCode, payload.hashCode, createdAt.hashCode, isRead.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    json['fromStudentUid'] = nativeToJson<String>(fromStudentUid);
    json['eventType'] = nativeToJson<String>(eventType);
    json['payload'] = nativeToJson<String>(payload);
    json['createdAt'] = createdAt.toJson();
    json['isRead'] = nativeToJson<bool>(isRead);
    return json;
  }

  GetAllLocalNotificationEventsForParentLocalNotificationEvents({
    required this.id,
    required this.fromStudentUid,
    required this.eventType,
    required this.payload,
    required this.createdAt,
    required this.isRead,
  });
}

@immutable
class GetAllLocalNotificationEventsForParentData {
  final List<GetAllLocalNotificationEventsForParentLocalNotificationEvents> localNotificationEvents;
  GetAllLocalNotificationEventsForParentData.fromJson(dynamic json):
  
  localNotificationEvents = (json['localNotificationEvents'] as List<dynamic>)
        .map((e) => GetAllLocalNotificationEventsForParentLocalNotificationEvents.fromJson(e))
        .toList();
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final GetAllLocalNotificationEventsForParentData otherTyped = other as GetAllLocalNotificationEventsForParentData;
    return localNotificationEvents == otherTyped.localNotificationEvents;
    
  }
  @override
  int get hashCode => localNotificationEvents.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['localNotificationEvents'] = localNotificationEvents.map((e) => e.toJson()).toList();
    return json;
  }

  GetAllLocalNotificationEventsForParentData({
    required this.localNotificationEvents,
  });
}

@immutable
class GetAllLocalNotificationEventsForParentVariables {
  final String toParentUid;
  @Deprecated('fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  GetAllLocalNotificationEventsForParentVariables.fromJson(Map<String, dynamic> json):
  
  toParentUid = nativeFromJson<String>(json['toParentUid']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final GetAllLocalNotificationEventsForParentVariables otherTyped = other as GetAllLocalNotificationEventsForParentVariables;
    return toParentUid == otherTyped.toParentUid;
    
  }
  @override
  int get hashCode => toParentUid.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['toParentUid'] = nativeToJson<String>(toParentUid);
    return json;
  }

  GetAllLocalNotificationEventsForParentVariables({
    required this.toParentUid,
  });
}

