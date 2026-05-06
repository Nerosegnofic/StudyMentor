part of 'generated.dart';

class RemoveFriendVariablesBuilder {
  String id;

  final FirebaseDataConnect _dataConnect;
  RemoveFriendVariablesBuilder(this._dataConnect, {required  this.id,});
  Deserializer<RemoveFriendData> dataDeserializer = (dynamic json)  => RemoveFriendData.fromJson(jsonDecode(json));
  Serializer<RemoveFriendVariables> varsSerializer = (RemoveFriendVariables vars) => jsonEncode(vars.toJson());
  Future<OperationResult<RemoveFriendData, RemoveFriendVariables>> execute() {
    return ref().execute();
  }

  MutationRef<RemoveFriendData, RemoveFriendVariables> ref() {
    RemoveFriendVariables vars= RemoveFriendVariables(id: id,);
    return _dataConnect.mutation("RemoveFriend", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class RemoveFriendFriendshipDelete {
  final String id;
  RemoveFriendFriendshipDelete.fromJson(dynamic json):
  
  id = nativeFromJson<String>(json['id']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final RemoveFriendFriendshipDelete otherTyped = other as RemoveFriendFriendshipDelete;
    return id == otherTyped.id;
    
  }
  @override
  int get hashCode => id.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    return json;
  }

  RemoveFriendFriendshipDelete({
    required this.id,
  });
}

@immutable
class RemoveFriendData {
  final RemoveFriendFriendshipDelete? friendship_delete;
  RemoveFriendData.fromJson(dynamic json):
  
  friendship_delete = json['friendship_delete'] == null ? null : RemoveFriendFriendshipDelete.fromJson(json['friendship_delete']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final RemoveFriendData otherTyped = other as RemoveFriendData;
    return friendship_delete == otherTyped.friendship_delete;
    
  }
  @override
  int get hashCode => friendship_delete.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    if (friendship_delete != null) {
      json['friendship_delete'] = friendship_delete!.toJson();
    }
    return json;
  }

  RemoveFriendData({
    this.friendship_delete,
  });
}

@immutable
class RemoveFriendVariables {
  final String id;
  @Deprecated('fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  RemoveFriendVariables.fromJson(Map<String, dynamic> json):
  
  id = nativeFromJson<String>(json['id']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final RemoveFriendVariables otherTyped = other as RemoveFriendVariables;
    return id == otherTyped.id;
    
  }
  @override
  int get hashCode => id.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    return json;
  }

  RemoveFriendVariables({
    required this.id,
  });
}

