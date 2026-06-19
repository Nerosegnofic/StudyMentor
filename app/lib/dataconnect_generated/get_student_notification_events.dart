part of 'generated.dart';

class GetStudentNotificationEventsVariablesBuilder {
  String studentUid;

  final FirebaseDataConnect _dataConnect;
  GetStudentNotificationEventsVariablesBuilder(this._dataConnect, {required  this.studentUid,});
  Deserializer<GetStudentNotificationEventsData> dataDeserializer = (dynamic json)  => GetStudentNotificationEventsData.fromJson(jsonDecode(json));
  Serializer<GetStudentNotificationEventsVariables> varsSerializer = (GetStudentNotificationEventsVariables vars) => jsonEncode(vars.toJson());
  Future<QueryResult<GetStudentNotificationEventsData, GetStudentNotificationEventsVariables>> execute({QueryFetchPolicy fetchPolicy = QueryFetchPolicy.preferCache}) {
    return ref().execute(fetchPolicy: fetchPolicy);
  }

  QueryRef<GetStudentNotificationEventsData, GetStudentNotificationEventsVariables> ref() {
    GetStudentNotificationEventsVariables vars= GetStudentNotificationEventsVariables(studentUid: studentUid,);
    return _dataConnect.query("GetStudentNotificationEvents", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class GetStudentNotificationEventsStudentNotificationEvents {
  final String id;
  final String eventType;
  final String title;
  final String body;
  final Timestamp createdAt;
  final bool isRead;
  GetStudentNotificationEventsStudentNotificationEvents.fromJson(dynamic json):
  
  id = nativeFromJson<String>(json['id']),
  eventType = nativeFromJson<String>(json['eventType']),
  title = nativeFromJson<String>(json['title']),
  body = nativeFromJson<String>(json['body']),
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

    final GetStudentNotificationEventsStudentNotificationEvents otherTyped = other as GetStudentNotificationEventsStudentNotificationEvents;
    return id == otherTyped.id && 
    eventType == otherTyped.eventType && 
    title == otherTyped.title && 
    body == otherTyped.body && 
    createdAt == otherTyped.createdAt && 
    isRead == otherTyped.isRead;
    
  }
  @override
  int get hashCode => Object.hashAll([id.hashCode, eventType.hashCode, title.hashCode, body.hashCode, createdAt.hashCode, isRead.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    json['eventType'] = nativeToJson<String>(eventType);
    json['title'] = nativeToJson<String>(title);
    json['body'] = nativeToJson<String>(body);
    json['createdAt'] = createdAt.toJson();
    json['isRead'] = nativeToJson<bool>(isRead);
    return json;
  }

  GetStudentNotificationEventsStudentNotificationEvents({
    required this.id,
    required this.eventType,
    required this.title,
    required this.body,
    required this.createdAt,
    required this.isRead,
  });
}

@immutable
class GetStudentNotificationEventsData {
  final List<GetStudentNotificationEventsStudentNotificationEvents> studentNotificationEvents;
  GetStudentNotificationEventsData.fromJson(dynamic json):
  
  studentNotificationEvents = (json['studentNotificationEvents'] as List<dynamic>)
        .map((e) => GetStudentNotificationEventsStudentNotificationEvents.fromJson(e))
        .toList();
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final GetStudentNotificationEventsData otherTyped = other as GetStudentNotificationEventsData;
    return studentNotificationEvents == otherTyped.studentNotificationEvents;
    
  }
  @override
  int get hashCode => studentNotificationEvents.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['studentNotificationEvents'] = studentNotificationEvents.map((e) => e.toJson()).toList();
    return json;
  }

  GetStudentNotificationEventsData({
    required this.studentNotificationEvents,
  });
}

@immutable
class GetStudentNotificationEventsVariables {
  final String studentUid;
  @Deprecated('fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  GetStudentNotificationEventsVariables.fromJson(Map<String, dynamic> json):
  
  studentUid = nativeFromJson<String>(json['studentUid']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final GetStudentNotificationEventsVariables otherTyped = other as GetStudentNotificationEventsVariables;
    return studentUid == otherTyped.studentUid;
    
  }
  @override
  int get hashCode => studentUid.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['studentUid'] = nativeToJson<String>(studentUid);
    return json;
  }

  GetStudentNotificationEventsVariables({
    required this.studentUid,
  });
}

