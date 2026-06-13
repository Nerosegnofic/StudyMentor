part of 'generated.dart';

class DeleteLocalNotificationPreferencesForUserVariablesBuilder {
  String userUid;

  final FirebaseDataConnect _dataConnect;
  DeleteLocalNotificationPreferencesForUserVariablesBuilder(this._dataConnect, {required  this.userUid,});
  Deserializer<DeleteLocalNotificationPreferencesForUserData> dataDeserializer = (dynamic json)  => DeleteLocalNotificationPreferencesForUserData.fromJson(jsonDecode(json));
  Serializer<DeleteLocalNotificationPreferencesForUserVariables> varsSerializer = (DeleteLocalNotificationPreferencesForUserVariables vars) => jsonEncode(vars.toJson());
  Future<OperationResult<DeleteLocalNotificationPreferencesForUserData, DeleteLocalNotificationPreferencesForUserVariables>> execute() {
    return ref().execute();
  }

  MutationRef<DeleteLocalNotificationPreferencesForUserData, DeleteLocalNotificationPreferencesForUserVariables> ref() {
    DeleteLocalNotificationPreferencesForUserVariables vars= DeleteLocalNotificationPreferencesForUserVariables(userUid: userUid,);
    return _dataConnect.mutation("DeleteLocalNotificationPreferencesForUser", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class DeleteLocalNotificationPreferencesForUserData {
  final int localNotificationPreference_deleteMany;
  DeleteLocalNotificationPreferencesForUserData.fromJson(dynamic json):
  
  localNotificationPreference_deleteMany = nativeFromJson<int>(json['localNotificationPreference_deleteMany']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final DeleteLocalNotificationPreferencesForUserData otherTyped = other as DeleteLocalNotificationPreferencesForUserData;
    return localNotificationPreference_deleteMany == otherTyped.localNotificationPreference_deleteMany;
    
  }
  @override
  int get hashCode => localNotificationPreference_deleteMany.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['localNotificationPreference_deleteMany'] = nativeToJson<int>(localNotificationPreference_deleteMany);
    return json;
  }

  DeleteLocalNotificationPreferencesForUserData({
    required this.localNotificationPreference_deleteMany,
  });
}

@immutable
class DeleteLocalNotificationPreferencesForUserVariables {
  final String userUid;
  @Deprecated('fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  DeleteLocalNotificationPreferencesForUserVariables.fromJson(Map<String, dynamic> json):
  
  userUid = nativeFromJson<String>(json['userUid']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final DeleteLocalNotificationPreferencesForUserVariables otherTyped = other as DeleteLocalNotificationPreferencesForUserVariables;
    return userUid == otherTyped.userUid;
    
  }
  @override
  int get hashCode => userUid.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['userUid'] = nativeToJson<String>(userUid);
    return json;
  }

  DeleteLocalNotificationPreferencesForUserVariables({
    required this.userUid,
  });
}

