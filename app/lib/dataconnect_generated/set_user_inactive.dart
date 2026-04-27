part of 'generated.dart';

class SetUserInactiveVariablesBuilder {
  
  final FirebaseDataConnect _dataConnect;
  SetUserInactiveVariablesBuilder(this._dataConnect, );
  Deserializer<SetUserInactiveData> dataDeserializer = (dynamic json)  => SetUserInactiveData.fromJson(jsonDecode(json));
  
  Future<OperationResult<SetUserInactiveData, void>> execute() {
    return ref().execute();
  }

  MutationRef<SetUserInactiveData, void> ref() {
    
    return _dataConnect.mutation("SetUserInactive", dataDeserializer, emptySerializer, null);
  }
}

@immutable
class SetUserInactiveUserUpdate {
  final String uid;
  SetUserInactiveUserUpdate.fromJson(dynamic json):
  
  uid = nativeFromJson<String>(json['uid']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final SetUserInactiveUserUpdate otherTyped = other as SetUserInactiveUserUpdate;
    return uid == otherTyped.uid;
    
  }
  @override
  int get hashCode => uid.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['uid'] = nativeToJson<String>(uid);
    return json;
  }

  SetUserInactiveUserUpdate({
    required this.uid,
  });
}

@immutable
class SetUserInactiveData {
  final SetUserInactiveUserUpdate? user_update;
  SetUserInactiveData.fromJson(dynamic json):
  
  user_update = json['user_update'] == null ? null : SetUserInactiveUserUpdate.fromJson(json['user_update']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final SetUserInactiveData otherTyped = other as SetUserInactiveData;
    return user_update == otherTyped.user_update;
    
  }
  @override
  int get hashCode => user_update.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    if (user_update != null) {
      json['user_update'] = user_update!.toJson();
    }
    return json;
  }

  SetUserInactiveData({
    this.user_update,
  });
}

