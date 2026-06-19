part of 'generated.dart';

class DeleteLocalNotificationEventVariablesBuilder {
  String id;

  final FirebaseDataConnect _dataConnect;
  DeleteLocalNotificationEventVariablesBuilder(this._dataConnect, {required  this.id,});
  Deserializer<DeleteLocalNotificationEventData> dataDeserializer = (dynamic json)  => DeleteLocalNotificationEventData.fromJson(jsonDecode(json));
  Serializer<DeleteLocalNotificationEventVariables> varsSerializer = (DeleteLocalNotificationEventVariables vars) => jsonEncode(vars.toJson());
  Future<OperationResult<DeleteLocalNotificationEventData, DeleteLocalNotificationEventVariables>> execute() {
    return ref().execute();
  }

  MutationRef<DeleteLocalNotificationEventData, DeleteLocalNotificationEventVariables> ref() {
    DeleteLocalNotificationEventVariables vars= DeleteLocalNotificationEventVariables(id: id,);
    return _dataConnect.mutation("DeleteLocalNotificationEvent", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class DeleteLocalNotificationEventLocalNotificationEventDelete {
  final String id;
  DeleteLocalNotificationEventLocalNotificationEventDelete.fromJson(dynamic json):
  
  id = nativeFromJson<String>(json['id']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final DeleteLocalNotificationEventLocalNotificationEventDelete otherTyped = other as DeleteLocalNotificationEventLocalNotificationEventDelete;
    return id == otherTyped.id;
    
  }
  @override
  int get hashCode => id.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    return json;
  }

  DeleteLocalNotificationEventLocalNotificationEventDelete({
    required this.id,
  });
}

@immutable
class DeleteLocalNotificationEventData {
  final DeleteLocalNotificationEventLocalNotificationEventDelete? localNotificationEvent_delete;
  DeleteLocalNotificationEventData.fromJson(dynamic json):
  
  localNotificationEvent_delete = json['localNotificationEvent_delete'] == null ? null : DeleteLocalNotificationEventLocalNotificationEventDelete.fromJson(json['localNotificationEvent_delete']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final DeleteLocalNotificationEventData otherTyped = other as DeleteLocalNotificationEventData;
    return localNotificationEvent_delete == otherTyped.localNotificationEvent_delete;
    
  }
  @override
  int get hashCode => localNotificationEvent_delete.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    if (localNotificationEvent_delete != null) {
      json['localNotificationEvent_delete'] = localNotificationEvent_delete!.toJson();
    }
    return json;
  }

  DeleteLocalNotificationEventData({
    this.localNotificationEvent_delete,
  });
}

@immutable
class DeleteLocalNotificationEventVariables {
  final String id;
  @Deprecated('fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  DeleteLocalNotificationEventVariables.fromJson(Map<String, dynamic> json):
  
  id = nativeFromJson<String>(json['id']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final DeleteLocalNotificationEventVariables otherTyped = other as DeleteLocalNotificationEventVariables;
    return id == otherTyped.id;
    
  }
  @override
  int get hashCode => id.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    return json;
  }

  DeleteLocalNotificationEventVariables({
    required this.id,
  });
}

