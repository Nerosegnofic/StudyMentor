part of 'generated.dart';

class DeleteNotificationPreferencesForUserVariablesBuilder {
  String userUid;

  final FirebaseDataConnect _dataConnect;
  DeleteNotificationPreferencesForUserVariablesBuilder(this._dataConnect, {required  this.userUid,});
  Deserializer<DeleteNotificationPreferencesForUserData> dataDeserializer = (dynamic json)  => DeleteNotificationPreferencesForUserData.fromJson(jsonDecode(json));
  Serializer<DeleteNotificationPreferencesForUserVariables> varsSerializer = (DeleteNotificationPreferencesForUserVariables vars) => jsonEncode(vars.toJson());
  Future<OperationResult<DeleteNotificationPreferencesForUserData, DeleteNotificationPreferencesForUserVariables>> execute() {
    return ref().execute();
  }

  MutationRef<DeleteNotificationPreferencesForUserData, DeleteNotificationPreferencesForUserVariables> ref() {
    DeleteNotificationPreferencesForUserVariables vars= DeleteNotificationPreferencesForUserVariables(userUid: userUid,);
    return _dataConnect.mutation("DeleteNotificationPreferencesForUser", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class DeleteNotificationPreferencesForUserData {
  final int notificationPreference_deleteMany;
  DeleteNotificationPreferencesForUserData.fromJson(dynamic json):
  
  notificationPreference_deleteMany = nativeFromJson<int>(json['notificationPreference_deleteMany']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final DeleteNotificationPreferencesForUserData otherTyped = other as DeleteNotificationPreferencesForUserData;
    return notificationPreference_deleteMany == otherTyped.notificationPreference_deleteMany;
    
  }
  @override
  int get hashCode => notificationPreference_deleteMany.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['notificationPreference_deleteMany'] = nativeToJson<int>(notificationPreference_deleteMany);
    return json;
  }

  DeleteNotificationPreferencesForUserData({
    required this.notificationPreference_deleteMany,
  });
}

@immutable
class DeleteNotificationPreferencesForUserVariables {
  final String userUid;
  @Deprecated('fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  DeleteNotificationPreferencesForUserVariables.fromJson(Map<String, dynamic> json):
  
  userUid = nativeFromJson<String>(json['userUid']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final DeleteNotificationPreferencesForUserVariables otherTyped = other as DeleteNotificationPreferencesForUserVariables;
    return userUid == otherTyped.userUid;
    
  }
  @override
  int get hashCode => userUid.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['userUid'] = nativeToJson<String>(userUid);
    return json;
  }

  DeleteNotificationPreferencesForUserVariables({
    required this.userUid,
  });
}

