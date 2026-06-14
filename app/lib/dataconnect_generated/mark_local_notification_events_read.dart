part of 'generated.dart';

class MarkLocalNotificationEventsReadVariablesBuilder {
  String toParentUid;

  final FirebaseDataConnect _dataConnect;
  MarkLocalNotificationEventsReadVariablesBuilder(this._dataConnect, {required  this.toParentUid,});
  Deserializer<MarkLocalNotificationEventsReadData> dataDeserializer = (dynamic json)  => MarkLocalNotificationEventsReadData.fromJson(jsonDecode(json));
  Serializer<MarkLocalNotificationEventsReadVariables> varsSerializer = (MarkLocalNotificationEventsReadVariables vars) => jsonEncode(vars.toJson());
  Future<OperationResult<MarkLocalNotificationEventsReadData, MarkLocalNotificationEventsReadVariables>> execute() {
    return ref().execute();
  }

  MutationRef<MarkLocalNotificationEventsReadData, MarkLocalNotificationEventsReadVariables> ref() {
    MarkLocalNotificationEventsReadVariables vars= MarkLocalNotificationEventsReadVariables(toParentUid: toParentUid,);
    return _dataConnect.mutation("MarkLocalNotificationEventsRead", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class MarkLocalNotificationEventsReadData {
  final int localNotificationEvent_updateMany;
  MarkLocalNotificationEventsReadData.fromJson(dynamic json):
  
  localNotificationEvent_updateMany = nativeFromJson<int>(json['localNotificationEvent_updateMany']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final MarkLocalNotificationEventsReadData otherTyped = other as MarkLocalNotificationEventsReadData;
    return localNotificationEvent_updateMany == otherTyped.localNotificationEvent_updateMany;
    
  }
  @override
  int get hashCode => localNotificationEvent_updateMany.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['localNotificationEvent_updateMany'] = nativeToJson<int>(localNotificationEvent_updateMany);
    return json;
  }

  MarkLocalNotificationEventsReadData({
    required this.localNotificationEvent_updateMany,
  });
}

@immutable
class MarkLocalNotificationEventsReadVariables {
  final String toParentUid;
  @Deprecated('fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  MarkLocalNotificationEventsReadVariables.fromJson(Map<String, dynamic> json):
  
  toParentUid = nativeFromJson<String>(json['toParentUid']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final MarkLocalNotificationEventsReadVariables otherTyped = other as MarkLocalNotificationEventsReadVariables;
    return toParentUid == otherTyped.toParentUid;
    
  }
  @override
  int get hashCode => toParentUid.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['toParentUid'] = nativeToJson<String>(toParentUid);
    return json;
  }

  MarkLocalNotificationEventsReadVariables({
    required this.toParentUid,
  });
}

