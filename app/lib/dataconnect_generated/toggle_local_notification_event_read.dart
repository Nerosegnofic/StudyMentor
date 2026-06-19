part of 'generated.dart';

class ToggleLocalNotificationEventReadVariablesBuilder {
  String id;
  bool isRead;

  final FirebaseDataConnect _dataConnect;
  ToggleLocalNotificationEventReadVariablesBuilder(this._dataConnect, {required  this.id,required  this.isRead,});
  Deserializer<ToggleLocalNotificationEventReadData> dataDeserializer = (dynamic json)  => ToggleLocalNotificationEventReadData.fromJson(jsonDecode(json));
  Serializer<ToggleLocalNotificationEventReadVariables> varsSerializer = (ToggleLocalNotificationEventReadVariables vars) => jsonEncode(vars.toJson());
  Future<OperationResult<ToggleLocalNotificationEventReadData, ToggleLocalNotificationEventReadVariables>> execute() {
    return ref().execute();
  }

  MutationRef<ToggleLocalNotificationEventReadData, ToggleLocalNotificationEventReadVariables> ref() {
    ToggleLocalNotificationEventReadVariables vars= ToggleLocalNotificationEventReadVariables(id: id,isRead: isRead,);
    return _dataConnect.mutation("ToggleLocalNotificationEventRead", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class ToggleLocalNotificationEventReadLocalNotificationEventUpdate {
  final String id;
  ToggleLocalNotificationEventReadLocalNotificationEventUpdate.fromJson(dynamic json):
  
  id = nativeFromJson<String>(json['id']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final ToggleLocalNotificationEventReadLocalNotificationEventUpdate otherTyped = other as ToggleLocalNotificationEventReadLocalNotificationEventUpdate;
    return id == otherTyped.id;
    
  }
  @override
  int get hashCode => id.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    return json;
  }

  ToggleLocalNotificationEventReadLocalNotificationEventUpdate({
    required this.id,
  });
}

@immutable
class ToggleLocalNotificationEventReadData {
  final ToggleLocalNotificationEventReadLocalNotificationEventUpdate? localNotificationEvent_update;
  ToggleLocalNotificationEventReadData.fromJson(dynamic json):
  
  localNotificationEvent_update = json['localNotificationEvent_update'] == null ? null : ToggleLocalNotificationEventReadLocalNotificationEventUpdate.fromJson(json['localNotificationEvent_update']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final ToggleLocalNotificationEventReadData otherTyped = other as ToggleLocalNotificationEventReadData;
    return localNotificationEvent_update == otherTyped.localNotificationEvent_update;
    
  }
  @override
  int get hashCode => localNotificationEvent_update.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    if (localNotificationEvent_update != null) {
      json['localNotificationEvent_update'] = localNotificationEvent_update!.toJson();
    }
    return json;
  }

  ToggleLocalNotificationEventReadData({
    this.localNotificationEvent_update,
  });
}

@immutable
class ToggleLocalNotificationEventReadVariables {
  final String id;
  final bool isRead;
  @Deprecated('fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  ToggleLocalNotificationEventReadVariables.fromJson(Map<String, dynamic> json):
  
  id = nativeFromJson<String>(json['id']),
  isRead = nativeFromJson<bool>(json['isRead']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final ToggleLocalNotificationEventReadVariables otherTyped = other as ToggleLocalNotificationEventReadVariables;
    return id == otherTyped.id && 
    isRead == otherTyped.isRead;
    
  }
  @override
  int get hashCode => Object.hashAll([id.hashCode, isRead.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    json['isRead'] = nativeToJson<bool>(isRead);
    return json;
  }

  ToggleLocalNotificationEventReadVariables({
    required this.id,
    required this.isRead,
  });
}

