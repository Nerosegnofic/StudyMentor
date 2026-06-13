part of 'generated.dart';

class GetNotificationPreferencesVariablesBuilder {
  String userUid;

  final FirebaseDataConnect _dataConnect;
  GetNotificationPreferencesVariablesBuilder(this._dataConnect, {required  this.userUid,});
  Deserializer<GetNotificationPreferencesData> dataDeserializer = (dynamic json)  => GetNotificationPreferencesData.fromJson(jsonDecode(json));
  Serializer<GetNotificationPreferencesVariables> varsSerializer = (GetNotificationPreferencesVariables vars) => jsonEncode(vars.toJson());
  Future<QueryResult<GetNotificationPreferencesData, GetNotificationPreferencesVariables>> execute({QueryFetchPolicy fetchPolicy = QueryFetchPolicy.preferCache}) {
    return ref().execute(fetchPolicy: fetchPolicy);
  }

  QueryRef<GetNotificationPreferencesData, GetNotificationPreferencesVariables> ref() {
    GetNotificationPreferencesVariables vars= GetNotificationPreferencesVariables(userUid: userUid,);
    return _dataConnect.query("GetNotificationPreferences", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class GetNotificationPreferencesNotificationPreferences {
  final String category;
  final bool enabled;
  final String? reminderTime;
  GetNotificationPreferencesNotificationPreferences.fromJson(dynamic json):
  
  category = nativeFromJson<String>(json['category']),
  enabled = nativeFromJson<bool>(json['enabled']),
  reminderTime = json['reminderTime'] == null ? null : nativeFromJson<String>(json['reminderTime']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final GetNotificationPreferencesNotificationPreferences otherTyped = other as GetNotificationPreferencesNotificationPreferences;
    return category == otherTyped.category && 
    enabled == otherTyped.enabled && 
    reminderTime == otherTyped.reminderTime;
    
  }
  @override
  int get hashCode => Object.hashAll([category.hashCode, enabled.hashCode, reminderTime.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['category'] = nativeToJson<String>(category);
    json['enabled'] = nativeToJson<bool>(enabled);
    if (reminderTime != null) {
      json['reminderTime'] = nativeToJson<String?>(reminderTime);
    }
    return json;
  }

  GetNotificationPreferencesNotificationPreferences({
    required this.category,
    required this.enabled,
    this.reminderTime,
  });
}

@immutable
class GetNotificationPreferencesData {
  final List<GetNotificationPreferencesNotificationPreferences> notificationPreferences;
  GetNotificationPreferencesData.fromJson(dynamic json):
  
  notificationPreferences = (json['notificationPreferences'] as List<dynamic>)
        .map((e) => GetNotificationPreferencesNotificationPreferences.fromJson(e))
        .toList();
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final GetNotificationPreferencesData otherTyped = other as GetNotificationPreferencesData;
    return notificationPreferences == otherTyped.notificationPreferences;
    
  }
  @override
  int get hashCode => notificationPreferences.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['notificationPreferences'] = notificationPreferences.map((e) => e.toJson()).toList();
    return json;
  }

  GetNotificationPreferencesData({
    required this.notificationPreferences,
  });
}

@immutable
class GetNotificationPreferencesVariables {
  final String userUid;
  @Deprecated('fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  GetNotificationPreferencesVariables.fromJson(Map<String, dynamic> json):
  
  userUid = nativeFromJson<String>(json['userUid']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final GetNotificationPreferencesVariables otherTyped = other as GetNotificationPreferencesVariables;
    return userUid == otherTyped.userUid;
    
  }
  @override
  int get hashCode => userUid.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['userUid'] = nativeToJson<String>(userUid);
    return json;
  }

  GetNotificationPreferencesVariables({
    required this.userUid,
  });
}

