part of 'generated.dart';

class MarkNotificationEventsReadVariablesBuilder {
  String toParentUid;

  final FirebaseDataConnect _dataConnect;
  MarkNotificationEventsReadVariablesBuilder(this._dataConnect, {required  this.toParentUid,});
  Deserializer<MarkNotificationEventsReadData> dataDeserializer = (dynamic json)  => MarkNotificationEventsReadData.fromJson(jsonDecode(json));
  Serializer<MarkNotificationEventsReadVariables> varsSerializer = (MarkNotificationEventsReadVariables vars) => jsonEncode(vars.toJson());
  Future<OperationResult<MarkNotificationEventsReadData, MarkNotificationEventsReadVariables>> execute() {
    return ref().execute();
  }

  MutationRef<MarkNotificationEventsReadData, MarkNotificationEventsReadVariables> ref() {
    MarkNotificationEventsReadVariables vars= MarkNotificationEventsReadVariables(toParentUid: toParentUid,);
    return _dataConnect.mutation("MarkNotificationEventsRead", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class MarkNotificationEventsReadData {
  final int notificationEvent_updateMany;
  MarkNotificationEventsReadData.fromJson(dynamic json):
  
  notificationEvent_updateMany = nativeFromJson<int>(json['notificationEvent_updateMany']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final MarkNotificationEventsReadData otherTyped = other as MarkNotificationEventsReadData;
    return notificationEvent_updateMany == otherTyped.notificationEvent_updateMany;
    
  }
  @override
  int get hashCode => notificationEvent_updateMany.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['notificationEvent_updateMany'] = nativeToJson<int>(notificationEvent_updateMany);
    return json;
  }

  MarkNotificationEventsReadData({
    required this.notificationEvent_updateMany,
  });
}

@immutable
class MarkNotificationEventsReadVariables {
  final String toParentUid;
  @Deprecated('fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  MarkNotificationEventsReadVariables.fromJson(Map<String, dynamic> json):
  
  toParentUid = nativeFromJson<String>(json['toParentUid']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final MarkNotificationEventsReadVariables otherTyped = other as MarkNotificationEventsReadVariables;
    return toParentUid == otherTyped.toParentUid;
    
  }
  @override
  int get hashCode => toParentUid.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['toParentUid'] = nativeToJson<String>(toParentUid);
    return json;
  }

  MarkNotificationEventsReadVariables({
    required this.toParentUid,
  });
}

