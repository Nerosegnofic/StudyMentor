part of 'generated.dart';

class MarkEmailVerifiedVariablesBuilder {
  
  final FirebaseDataConnect _dataConnect;
  MarkEmailVerifiedVariablesBuilder(this._dataConnect, );
  Deserializer<MarkEmailVerifiedData> dataDeserializer = (dynamic json)  => MarkEmailVerifiedData.fromJson(jsonDecode(json));
  
  Future<OperationResult<MarkEmailVerifiedData, void>> execute() {
    return ref().execute();
  }

  MutationRef<MarkEmailVerifiedData, void> ref() {
    
    return _dataConnect.mutation("MarkEmailVerified", dataDeserializer, emptySerializer, null);
  }
}

@immutable
class MarkEmailVerifiedUserUpdate {
  final String uid;
  MarkEmailVerifiedUserUpdate.fromJson(dynamic json):
  
  uid = nativeFromJson<String>(json['uid']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final MarkEmailVerifiedUserUpdate otherTyped = other as MarkEmailVerifiedUserUpdate;
    return uid == otherTyped.uid;
    
  }
  @override
  int get hashCode => uid.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['uid'] = nativeToJson<String>(uid);
    return json;
  }

  MarkEmailVerifiedUserUpdate({
    required this.uid,
  });
}

@immutable
class MarkEmailVerifiedData {
  final MarkEmailVerifiedUserUpdate? user_update;
  MarkEmailVerifiedData.fromJson(dynamic json):
  
  user_update = json['user_update'] == null ? null : MarkEmailVerifiedUserUpdate.fromJson(json['user_update']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final MarkEmailVerifiedData otherTyped = other as MarkEmailVerifiedData;
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

  MarkEmailVerifiedData({
    this.user_update,
  });
}

