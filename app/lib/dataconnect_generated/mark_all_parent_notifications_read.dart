part of 'generated.dart';

class MarkAllParentNotificationsReadVariablesBuilder {
  String toParentUid;

  final FirebaseDataConnect _dataConnect;
  MarkAllParentNotificationsReadVariablesBuilder(this._dataConnect, {required  this.toParentUid,});
  Deserializer<MarkAllParentNotificationsReadData> dataDeserializer = (dynamic json)  => MarkAllParentNotificationsReadData.fromJson(jsonDecode(json));
  Serializer<MarkAllParentNotificationsReadVariables> varsSerializer = (MarkAllParentNotificationsReadVariables vars) => jsonEncode(vars.toJson());
  Future<OperationResult<MarkAllParentNotificationsReadData, MarkAllParentNotificationsReadVariables>> execute() {
    return ref().execute();
  }

  MutationRef<MarkAllParentNotificationsReadData, MarkAllParentNotificationsReadVariables> ref() {
    MarkAllParentNotificationsReadVariables vars= MarkAllParentNotificationsReadVariables(toParentUid: toParentUid,);
    return _dataConnect.mutation("MarkAllParentNotificationsRead", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class MarkAllParentNotificationsReadData {
  final int localNotificationEvent_updateMany;
  MarkAllParentNotificationsReadData.fromJson(dynamic json):
  
  localNotificationEvent_updateMany = nativeFromJson<int>(json['localNotificationEvent_updateMany']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final MarkAllParentNotificationsReadData otherTyped = other as MarkAllParentNotificationsReadData;
    return localNotificationEvent_updateMany == otherTyped.localNotificationEvent_updateMany;
    
  }
  @override
  int get hashCode => localNotificationEvent_updateMany.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['localNotificationEvent_updateMany'] = nativeToJson<int>(localNotificationEvent_updateMany);
    return json;
  }

  MarkAllParentNotificationsReadData({
    required this.localNotificationEvent_updateMany,
  });
}

@immutable
class MarkAllParentNotificationsReadVariables {
  final String toParentUid;
  @Deprecated('fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  MarkAllParentNotificationsReadVariables.fromJson(Map<String, dynamic> json):
  
  toParentUid = nativeFromJson<String>(json['toParentUid']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final MarkAllParentNotificationsReadVariables otherTyped = other as MarkAllParentNotificationsReadVariables;
    return toParentUid == otherTyped.toParentUid;
    
  }
  @override
  int get hashCode => toParentUid.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['toParentUid'] = nativeToJson<String>(toParentUid);
    return json;
  }

  MarkAllParentNotificationsReadVariables({
    required this.toParentUid,
  });
}

