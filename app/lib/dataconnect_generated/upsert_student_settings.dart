part of 'generated.dart';

class UpsertStudentSettingsVariablesBuilder {
  String studentUid;
  bool notificationsEnabled;
  bool soundEffectsEnabled;
  bool backgroundMusicEnabled;

  final FirebaseDataConnect _dataConnect;
  UpsertStudentSettingsVariablesBuilder(this._dataConnect, {required  this.studentUid,required  this.notificationsEnabled,required  this.soundEffectsEnabled,required  this.backgroundMusicEnabled,});
  Deserializer<UpsertStudentSettingsData> dataDeserializer = (dynamic json)  => UpsertStudentSettingsData.fromJson(jsonDecode(json));
  Serializer<UpsertStudentSettingsVariables> varsSerializer = (UpsertStudentSettingsVariables vars) => jsonEncode(vars.toJson());
  Future<OperationResult<UpsertStudentSettingsData, UpsertStudentSettingsVariables>> execute() {
    return ref().execute();
  }

  MutationRef<UpsertStudentSettingsData, UpsertStudentSettingsVariables> ref() {
    UpsertStudentSettingsVariables vars= UpsertStudentSettingsVariables(studentUid: studentUid,notificationsEnabled: notificationsEnabled,soundEffectsEnabled: soundEffectsEnabled,backgroundMusicEnabled: backgroundMusicEnabled,);
    return _dataConnect.mutation("UpsertStudentSettings", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class UpsertStudentSettingsStudentSettingsUpsert {
  final String studentUid;
  UpsertStudentSettingsStudentSettingsUpsert.fromJson(dynamic json):
  
  studentUid = nativeFromJson<String>(json['studentUid']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final UpsertStudentSettingsStudentSettingsUpsert otherTyped = other as UpsertStudentSettingsStudentSettingsUpsert;
    return studentUid == otherTyped.studentUid;
    
  }
  @override
  int get hashCode => studentUid.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['studentUid'] = nativeToJson<String>(studentUid);
    return json;
  }

  UpsertStudentSettingsStudentSettingsUpsert({
    required this.studentUid,
  });
}

@immutable
class UpsertStudentSettingsData {
  final UpsertStudentSettingsStudentSettingsUpsert studentSettings_upsert;
  UpsertStudentSettingsData.fromJson(dynamic json):
  
  studentSettings_upsert = UpsertStudentSettingsStudentSettingsUpsert.fromJson(json['studentSettings_upsert']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final UpsertStudentSettingsData otherTyped = other as UpsertStudentSettingsData;
    return studentSettings_upsert == otherTyped.studentSettings_upsert;
    
  }
  @override
  int get hashCode => studentSettings_upsert.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['studentSettings_upsert'] = studentSettings_upsert.toJson();
    return json;
  }

  UpsertStudentSettingsData({
    required this.studentSettings_upsert,
  });
}

@immutable
class UpsertStudentSettingsVariables {
  final String studentUid;
  final bool notificationsEnabled;
  final bool soundEffectsEnabled;
  final bool backgroundMusicEnabled;
  @Deprecated('fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  UpsertStudentSettingsVariables.fromJson(Map<String, dynamic> json):
  
  studentUid = nativeFromJson<String>(json['studentUid']),
  notificationsEnabled = nativeFromJson<bool>(json['notificationsEnabled']),
  soundEffectsEnabled = nativeFromJson<bool>(json['soundEffectsEnabled']),
  backgroundMusicEnabled = nativeFromJson<bool>(json['backgroundMusicEnabled']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final UpsertStudentSettingsVariables otherTyped = other as UpsertStudentSettingsVariables;
    return studentUid == otherTyped.studentUid && 
    notificationsEnabled == otherTyped.notificationsEnabled && 
    soundEffectsEnabled == otherTyped.soundEffectsEnabled && 
    backgroundMusicEnabled == otherTyped.backgroundMusicEnabled;
    
  }
  @override
  int get hashCode => Object.hashAll([studentUid.hashCode, notificationsEnabled.hashCode, soundEffectsEnabled.hashCode, backgroundMusicEnabled.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['studentUid'] = nativeToJson<String>(studentUid);
    json['notificationsEnabled'] = nativeToJson<bool>(notificationsEnabled);
    json['soundEffectsEnabled'] = nativeToJson<bool>(soundEffectsEnabled);
    json['backgroundMusicEnabled'] = nativeToJson<bool>(backgroundMusicEnabled);
    return json;
  }

  UpsertStudentSettingsVariables({
    required this.studentUid,
    required this.notificationsEnabled,
    required this.soundEffectsEnabled,
    required this.backgroundMusicEnabled,
  });
}

