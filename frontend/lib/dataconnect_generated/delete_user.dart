part of 'generated.dart';

class DeleteUserVariablesBuilder {
  
  final FirebaseDataConnect _dataConnect;
  DeleteUserVariablesBuilder(this._dataConnect, );
  Deserializer<DeleteUserData> dataDeserializer = (dynamic json)  => DeleteUserData.fromJson(jsonDecode(json));
  
  Future<OperationResult<DeleteUserData, void>> execute() {
    return ref().execute();
  }

  MutationRef<DeleteUserData, void> ref() {
    
    return _dataConnect.mutation("DeleteUser", dataDeserializer, emptySerializer, null);
  }
}

@immutable
class DeleteUserUserDelete {
  final String uid;
  DeleteUserUserDelete.fromJson(dynamic json):
  
  uid = nativeFromJson<String>(json['uid']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final DeleteUserUserDelete otherTyped = other as DeleteUserUserDelete;
    return uid == otherTyped.uid;
    
  }
  @override
  int get hashCode => uid.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['uid'] = nativeToJson<String>(uid);
    return json;
  }

  DeleteUserUserDelete({
    required this.uid,
  });
}

@immutable
class DeleteUserData {
  final DeleteUserUserDelete? user_delete;
  DeleteUserData.fromJson(dynamic json):
  
  user_delete = json['user_delete'] == null ? null : DeleteUserUserDelete.fromJson(json['user_delete']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final DeleteUserData otherTyped = other as DeleteUserData;
    return user_delete == otherTyped.user_delete;
    
  }
  @override
  int get hashCode => user_delete.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    if (user_delete != null) {
      json['user_delete'] = user_delete!.toJson();
    }
    return json;
  }

  DeleteUserData({
    this.user_delete,
  });
}

