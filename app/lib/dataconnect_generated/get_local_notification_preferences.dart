part of 'generated.dart';

class GetLocalNotificationPreferencesVariablesBuilder {
  String userUid;

  final FirebaseDataConnect _dataConnect;
  GetLocalNotificationPreferencesVariablesBuilder(this._dataConnect, {required  this.userUid,});
  Deserializer<GetLocalNotificationPreferencesData> dataDeserializer = (dynamic json)  => GetLocalNotificationPreferencesData.fromJson(jsonDecode(json));
  Serializer<GetLocalNotificationPreferencesVariables> varsSerializer = (GetLocalNotificationPreferencesVariables vars) => jsonEncode(vars.toJson());
  Future<QueryResult<GetLocalNotificationPreferencesData, GetLocalNotificationPreferencesVariables>> execute({QueryFetchPolicy fetchPolicy = QueryFetchPolicy.preferCache}) {
    return ref().execute(fetchPolicy: fetchPolicy);
  }

  QueryRef<GetLocalNotificationPreferencesData, GetLocalNotificationPreferencesVariables> ref() {
    GetLocalNotificationPreferencesVariables vars= GetLocalNotificationPreferencesVariables(userUid: userUid,);
    return _dataConnect.query("GetLocalNotificationPreferences", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class GetLocalNotificationPreferencesLocalNotificationPreferences {
  final String category;
  final bool enabled;
  final String? reminderTime;
  GetLocalNotificationPreferencesLocalNotificationPreferences.fromJson(dynamic json):
  
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

    final GetLocalNotificationPreferencesLocalNotificationPreferences otherTyped = other as GetLocalNotificationPreferencesLocalNotificationPreferences;
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

  GetLocalNotificationPreferencesLocalNotificationPreferences({
    required this.category,
    required this.enabled,
    this.reminderTime,
  });
}

@immutable
class GetLocalNotificationPreferencesData {
  final List<GetLocalNotificationPreferencesLocalNotificationPreferences> localNotificationPreferences;
  GetLocalNotificationPreferencesData.fromJson(dynamic json):
  
  localNotificationPreferences = (json['localNotificationPreferences'] as List<dynamic>)
        .map((e) => GetLocalNotificationPreferencesLocalNotificationPreferences.fromJson(e))
        .toList();
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final GetLocalNotificationPreferencesData otherTyped = other as GetLocalNotificationPreferencesData;
    return localNotificationPreferences == otherTyped.localNotificationPreferences;
    
  }
  @override
  int get hashCode => localNotificationPreferences.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['localNotificationPreferences'] = localNotificationPreferences.map((e) => e.toJson()).toList();
    return json;
  }

  GetLocalNotificationPreferencesData({
    required this.localNotificationPreferences,
  });
}

@immutable
class GetLocalNotificationPreferencesVariables {
  final String userUid;
  @Deprecated('fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  GetLocalNotificationPreferencesVariables.fromJson(Map<String, dynamic> json):
  
  userUid = nativeFromJson<String>(json['userUid']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final GetLocalNotificationPreferencesVariables otherTyped = other as GetLocalNotificationPreferencesVariables;
    return userUid == otherTyped.userUid;
    
  }
  @override
  int get hashCode => userUid.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['userUid'] = nativeToJson<String>(userUid);
    return json;
  }

  GetLocalNotificationPreferencesVariables({
    required this.userUid,
  });
}

