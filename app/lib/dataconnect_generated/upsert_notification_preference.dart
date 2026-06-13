part of 'generated.dart';

class UpsertNotificationPreferenceVariablesBuilder {
  String userUid;
  String category;
  bool enabled;
  Optional<String> _reminderTime = Optional.optional(nativeFromJson, nativeToJson);

  final FirebaseDataConnect _dataConnect;  UpsertNotificationPreferenceVariablesBuilder reminderTime(String? t) {
   _reminderTime.value = t;
   return this;
  }

  UpsertNotificationPreferenceVariablesBuilder(this._dataConnect, {required  this.userUid,required  this.category,required  this.enabled,});
  Deserializer<UpsertNotificationPreferenceData> dataDeserializer = (dynamic json)  => UpsertNotificationPreferenceData.fromJson(jsonDecode(json));
  Serializer<UpsertNotificationPreferenceVariables> varsSerializer = (UpsertNotificationPreferenceVariables vars) => jsonEncode(vars.toJson());
  Future<OperationResult<UpsertNotificationPreferenceData, UpsertNotificationPreferenceVariables>> execute() {
    return ref().execute();
  }

  MutationRef<UpsertNotificationPreferenceData, UpsertNotificationPreferenceVariables> ref() {
    UpsertNotificationPreferenceVariables vars= UpsertNotificationPreferenceVariables(userUid: userUid,category: category,enabled: enabled,reminderTime: _reminderTime,);
    return _dataConnect.mutation("UpsertNotificationPreference", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class UpsertNotificationPreferenceNotificationPreferenceUpsert {
  final String userUid;
  final String category;
  UpsertNotificationPreferenceNotificationPreferenceUpsert.fromJson(dynamic json):
  
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

    final UpsertNotificationPreferenceNotificationPreferenceUpsert otherTyped = other as UpsertNotificationPreferenceNotificationPreferenceUpsert;
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

  UpsertNotificationPreferenceNotificationPreferenceUpsert({
    required this.userUid,
    required this.category,
  });
}

@immutable
class UpsertNotificationPreferenceData {
  final UpsertNotificationPreferenceNotificationPreferenceUpsert notificationPreference_upsert;
  UpsertNotificationPreferenceData.fromJson(dynamic json):
  
  notificationPreference_upsert = UpsertNotificationPreferenceNotificationPreferenceUpsert.fromJson(json['notificationPreference_upsert']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final UpsertNotificationPreferenceData otherTyped = other as UpsertNotificationPreferenceData;
    return notificationPreference_upsert == otherTyped.notificationPreference_upsert;
    
  }
  @override
  int get hashCode => notificationPreference_upsert.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['notificationPreference_upsert'] = notificationPreference_upsert.toJson();
    return json;
  }

  UpsertNotificationPreferenceData({
    required this.notificationPreference_upsert,
  });
}

@immutable
class UpsertNotificationPreferenceVariables {
  final String userUid;
  final String category;
  final bool enabled;
  late final Optional<String>reminderTime;
  @Deprecated('fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  UpsertNotificationPreferenceVariables.fromJson(Map<String, dynamic> json):
  
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

    final UpsertNotificationPreferenceVariables otherTyped = other as UpsertNotificationPreferenceVariables;
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

  UpsertNotificationPreferenceVariables({
    required this.userUid,
    required this.category,
    required this.enabled,
    required this.reminderTime,
  });
}

