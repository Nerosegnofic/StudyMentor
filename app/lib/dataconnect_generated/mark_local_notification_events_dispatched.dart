part of 'generated.dart';

class MarkLocalNotificationEventsDispatchedVariablesBuilder {
  List<String> eventIds;

  final FirebaseDataConnect _dataConnect;
  MarkLocalNotificationEventsDispatchedVariablesBuilder(this._dataConnect, {required  this.eventIds,});
  Deserializer<MarkLocalNotificationEventsDispatchedData> dataDeserializer = (dynamic json)  => MarkLocalNotificationEventsDispatchedData.fromJson(jsonDecode(json));
  Serializer<MarkLocalNotificationEventsDispatchedVariables> varsSerializer = (MarkLocalNotificationEventsDispatchedVariables vars) => jsonEncode(vars.toJson());
  Future<OperationResult<MarkLocalNotificationEventsDispatchedData, MarkLocalNotificationEventsDispatchedVariables>> execute() {
    return ref().execute();
  }

  MutationRef<MarkLocalNotificationEventsDispatchedData, MarkLocalNotificationEventsDispatchedVariables> ref() {
    MarkLocalNotificationEventsDispatchedVariables vars= MarkLocalNotificationEventsDispatchedVariables(eventIds: eventIds,);
    return _dataConnect.mutation("MarkLocalNotificationEventsDispatched", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class MarkLocalNotificationEventsDispatchedData {
  final int localNotificationEvent_updateMany;
  MarkLocalNotificationEventsDispatchedData.fromJson(dynamic json):
  
  localNotificationEvent_updateMany = nativeFromJson<int>(json['localNotificationEvent_updateMany']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final MarkLocalNotificationEventsDispatchedData otherTyped = other as MarkLocalNotificationEventsDispatchedData;
    return localNotificationEvent_updateMany == otherTyped.localNotificationEvent_updateMany;
    
  }
  @override
  int get hashCode => localNotificationEvent_updateMany.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['localNotificationEvent_updateMany'] = nativeToJson<int>(localNotificationEvent_updateMany);
    return json;
  }

  MarkLocalNotificationEventsDispatchedData({
    required this.localNotificationEvent_updateMany,
  });
}

@immutable
class MarkLocalNotificationEventsDispatchedVariables {
  final List<String> eventIds;
  @Deprecated('fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  MarkLocalNotificationEventsDispatchedVariables.fromJson(Map<String, dynamic> json):
  
  eventIds = (json['eventIds'] as List<dynamic>)
        .map((e) => nativeFromJson<String>(e))
        .toList();
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final MarkLocalNotificationEventsDispatchedVariables otherTyped = other as MarkLocalNotificationEventsDispatchedVariables;
    return eventIds == otherTyped.eventIds;
    
  }
  @override
  int get hashCode => eventIds.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['eventIds'] = eventIds.map((e) => nativeToJson<String>(e)).toList();
    return json;
  }

  MarkLocalNotificationEventsDispatchedVariables({
    required this.eventIds,
  });
}

