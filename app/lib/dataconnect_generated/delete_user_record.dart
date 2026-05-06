part of 'generated.dart';

class DeleteUserRecordVariablesBuilder {
  String uid;

  final FirebaseDataConnect _dataConnect;
  DeleteUserRecordVariablesBuilder(this._dataConnect, {required  this.uid,});
  Deserializer<DeleteUserRecordData> dataDeserializer = (dynamic json)  => DeleteUserRecordData.fromJson(jsonDecode(json));
  Serializer<DeleteUserRecordVariables> varsSerializer = (DeleteUserRecordVariables vars) => jsonEncode(vars.toJson());
  Future<OperationResult<DeleteUserRecordData, DeleteUserRecordVariables>> execute() {
    return ref().execute();
  }

  MutationRef<DeleteUserRecordData, DeleteUserRecordVariables> ref() {
    DeleteUserRecordVariables vars= DeleteUserRecordVariables(uid: uid,);
    return _dataConnect.mutation("DeleteUserRecord", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class DeleteUserRecordUserDelete {
  final String uid;
  DeleteUserRecordUserDelete.fromJson(dynamic json):
  
  uid = nativeFromJson<String>(json['uid']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final DeleteUserRecordUserDelete otherTyped = other as DeleteUserRecordUserDelete;
    return uid == otherTyped.uid;
    
  }
  @override
  int get hashCode => uid.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['uid'] = nativeToJson<String>(uid);
    return json;
  }

  DeleteUserRecordUserDelete({
    required this.uid,
  });
}

@immutable
class DeleteUserRecordData {
  final DeleteUserRecordUserDelete? user_delete;
  DeleteUserRecordData.fromJson(dynamic json):
  
  user_delete = json['user_delete'] == null ? null : DeleteUserRecordUserDelete.fromJson(json['user_delete']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final DeleteUserRecordData otherTyped = other as DeleteUserRecordData;
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

  DeleteUserRecordData({
    this.user_delete,
  });
}

@immutable
class DeleteUserRecordVariables {
  final String uid;
  @Deprecated('fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  DeleteUserRecordVariables.fromJson(Map<String, dynamic> json):
  
  uid = nativeFromJson<String>(json['uid']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final DeleteUserRecordVariables otherTyped = other as DeleteUserRecordVariables;
    return uid == otherTyped.uid;
    
  }
  @override
  int get hashCode => uid.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['uid'] = nativeToJson<String>(uid);
    return json;
  }

  DeleteUserRecordVariables({
    required this.uid,
  });
}

