part of 'generated.dart';

class UpdateFriendRequestStatusVariablesBuilder {
  String id;
  String status;

  final FirebaseDataConnect _dataConnect;
  UpdateFriendRequestStatusVariablesBuilder(this._dataConnect, {required  this.id,required  this.status,});
  Deserializer<UpdateFriendRequestStatusData> dataDeserializer = (dynamic json)  => UpdateFriendRequestStatusData.fromJson(jsonDecode(json));
  Serializer<UpdateFriendRequestStatusVariables> varsSerializer = (UpdateFriendRequestStatusVariables vars) => jsonEncode(vars.toJson());
  Future<OperationResult<UpdateFriendRequestStatusData, UpdateFriendRequestStatusVariables>> execute() {
    return ref().execute();
  }

  MutationRef<UpdateFriendRequestStatusData, UpdateFriendRequestStatusVariables> ref() {
    UpdateFriendRequestStatusVariables vars= UpdateFriendRequestStatusVariables(id: id,status: status,);
    return _dataConnect.mutation("UpdateFriendRequestStatus", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class UpdateFriendRequestStatusFriendRequestUpdate {
  final String id;
  UpdateFriendRequestStatusFriendRequestUpdate.fromJson(dynamic json):
  
  id = nativeFromJson<String>(json['id']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final UpdateFriendRequestStatusFriendRequestUpdate otherTyped = other as UpdateFriendRequestStatusFriendRequestUpdate;
    return id == otherTyped.id;
    
  }
  @override
  int get hashCode => id.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    return json;
  }

  UpdateFriendRequestStatusFriendRequestUpdate({
    required this.id,
  });
}

@immutable
class UpdateFriendRequestStatusData {
  final UpdateFriendRequestStatusFriendRequestUpdate? friendRequest_update;
  UpdateFriendRequestStatusData.fromJson(dynamic json):
  
  friendRequest_update = json['friendRequest_update'] == null ? null : UpdateFriendRequestStatusFriendRequestUpdate.fromJson(json['friendRequest_update']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final UpdateFriendRequestStatusData otherTyped = other as UpdateFriendRequestStatusData;
    return friendRequest_update == otherTyped.friendRequest_update;
    
  }
  @override
  int get hashCode => friendRequest_update.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    if (friendRequest_update != null) {
      json['friendRequest_update'] = friendRequest_update!.toJson();
    }
    return json;
  }

  UpdateFriendRequestStatusData({
    this.friendRequest_update,
  });
}

@immutable
class UpdateFriendRequestStatusVariables {
  final String id;
  final String status;
  @Deprecated('fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  UpdateFriendRequestStatusVariables.fromJson(Map<String, dynamic> json):
  
  id = nativeFromJson<String>(json['id']),
  status = nativeFromJson<String>(json['status']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final UpdateFriendRequestStatusVariables otherTyped = other as UpdateFriendRequestStatusVariables;
    return id == otherTyped.id && 
    status == otherTyped.status;
    
  }
  @override
  int get hashCode => Object.hashAll([id.hashCode, status.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    json['status'] = nativeToJson<String>(status);
    return json;
  }

  UpdateFriendRequestStatusVariables({
    required this.id,
    required this.status,
  });
}

