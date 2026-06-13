part of 'generated.dart';

class UpsertLocalNotificationPreferenceVariablesBuilder {
  String userUid;
  String category;
  bool enabled;
  Optional<String> _reminderTime = Optional.optional(nativeFromJson, nativeToJson);

  final FirebaseDataConnect _dataConnect;  UpsertLocalNotificationPreferenceVariablesBuilder reminderTime(String? t) {
   _reminderTime.value = t;
   return this;
  }

  UpsertLocalNotificationPreferenceVariablesBuilder(this._dataConnect, {required  this.userUid,required  this.category,required  this.enabled,});
  Deserializer<UpsertLocalNotificationPreferenceData> dataDeserializer = (dynamic json)  => UpsertLocalNotificationPreferenceData.fromJson(jsonDecode(json));
  Serializer<UpsertLocalNotificationPreferenceVariables> varsSerializer = (UpsertLocalNotificationPreferenceVariables vars) => jsonEncode(vars.toJson());
  Future<OperationResult<UpsertLocalNotificationPreferenceData, UpsertLocalNotificationPreferenceVariables>> execute() {
    return ref().execute();
  }

  MutationRef<UpsertLocalNotificationPreferenceData, UpsertLocalNotificationPreferenceVariables> ref() {
    UpsertLocalNotificationPreferenceVariables vars= UpsertLocalNotificationPreferenceVariables(userUid: userUid,category: category,enabled: enabled,reminderTime: _reminderTime,);
    return _dataConnect.mutation("UpsertLocalNotificationPreference", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class UpsertLocalNotificationPreferenceLocalNotificationPreferenceUpsert {
  final String userUid;
  final String category;
  UpsertLocalNotificationPreferenceLocalNotificationPreferenceUpsert.fromJson(dynamic json):
  
  userUid = nativeFromJson<String>(json['userUid']),
  category = nativeFromJson<String>(json['category']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final UpsertLocalNotificationPreferenceLocalNotificationPreferenceUpsert otherTyped = other as UpsertLocalNotificationPreferenceLocalNotificationPreferenceUpsert;
    return userUid == otherTyped.userUid && 
    category == otherTyped.category;
    
  }
  @override
  int get hashCode => Object.hashAll([userUid.hashCode, category.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['userUid'] = nativeToJson<String>(userUid);
    json['category'] = nativeToJson<String>(category);
    return json;
  }

  UpsertLocalNotificationPreferenceLocalNotificationPreferenceUpsert({
    required this.userUid,
    required this.category,
  });
}

@immutable
class UpsertLocalNotificationPreferenceData {
  final UpsertLocalNotificationPreferenceLocalNotificationPreferenceUpsert localNotificationPreference_upsert;
  UpsertLocalNotificationPreferenceData.fromJson(dynamic json):
  
  localNotificationPreference_upsert = UpsertLocalNotificationPreferenceLocalNotificationPreferenceUpsert.fromJson(json['localNotificationPreference_upsert']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final UpsertLocalNotificationPreferenceData otherTyped = other as UpsertLocalNotificationPreferenceData;
    return localNotificationPreference_upsert == otherTyped.localNotificationPreference_upsert;
    
  }
  @override
  int get hashCode => localNotificationPreference_upsert.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['localNotificationPreference_upsert'] = localNotificationPreference_upsert.toJson();
    return json;
  }

  UpsertLocalNotificationPreferenceData({
    required this.localNotificationPreference_upsert,
  });
}

@immutable
class UpsertLocalNotificationPreferenceVariables {
  final String userUid;
  final String category;
  final bool enabled;
  late final Optional<String>reminderTime;
  @Deprecated('fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  UpsertLocalNotificationPreferenceVariables.fromJson(Map<String, dynamic> json):
  
  userUid = nativeFromJson<String>(json['userUid']),
  category = nativeFromJson<String>(json['category']),
  enabled = nativeFromJson<bool>(json['enabled']) {
  
  
  
  
  
    reminderTime = Optional.optional(nativeFromJson, nativeToJson);
    reminderTime.value = json['reminderTime'] == null ? null : nativeFromJson<String>(json['reminderTime']);
  
  }
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final UpsertLocalNotificationPreferenceVariables otherTyped = other as UpsertLocalNotificationPreferenceVariables;
    return userUid == otherTyped.userUid && 
    category == otherTyped.category && 
    enabled == otherTyped.enabled && 
    reminderTime == otherTyped.reminderTime;
    
  }
  @override
  int get hashCode => Object.hashAll([userUid.hashCode, category.hashCode, enabled.hashCode, reminderTime.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['userUid'] = nativeToJson<String>(userUid);
    json['category'] = nativeToJson<String>(category);
    json['enabled'] = nativeToJson<bool>(enabled);
    if(reminderTime.state == OptionalState.set) {
      json['reminderTime'] = reminderTime.toJson();
    }
    return json;
  }

  UpsertLocalNotificationPreferenceVariables({
    required this.userUid,
    required this.category,
    required this.enabled,
    required this.reminderTime,
  });
}

