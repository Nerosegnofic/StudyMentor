part of 'generated.dart';

class GetStudentSettingsVariablesBuilder {
  String studentUid;

  final FirebaseDataConnect _dataConnect;
  GetStudentSettingsVariablesBuilder(this._dataConnect, {required  this.studentUid,});
  Deserializer<GetStudentSettingsData> dataDeserializer = (dynamic json)  => GetStudentSettingsData.fromJson(jsonDecode(json));
  Serializer<GetStudentSettingsVariables> varsSerializer = (GetStudentSettingsVariables vars) => jsonEncode(vars.toJson());
  Future<QueryResult<GetStudentSettingsData, GetStudentSettingsVariables>> execute({QueryFetchPolicy fetchPolicy = QueryFetchPolicy.preferCache}) {
    return ref().execute(fetchPolicy: fetchPolicy);
  }

  QueryRef<GetStudentSettingsData, GetStudentSettingsVariables> ref() {
    GetStudentSettingsVariables vars= GetStudentSettingsVariables(studentUid: studentUid,);
    return _dataConnect.query("GetStudentSettings", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class GetStudentSettingsStudentSettings {
  final bool notificationsEnabled;
  final bool soundEffectsEnabled;
  final bool backgroundMusicEnabled;
  GetStudentSettingsStudentSettings.fromJson(dynamic json):
  
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

    final GetStudentSettingsStudentSettings otherTyped = other as GetStudentSettingsStudentSettings;
    return notificationsEnabled == otherTyped.notificationsEnabled && 
    soundEffectsEnabled == otherTyped.soundEffectsEnabled && 
    backgroundMusicEnabled == otherTyped.backgroundMusicEnabled;
    
  }
  @override
  int get hashCode => Object.hashAll([notificationsEnabled.hashCode, soundEffectsEnabled.hashCode, backgroundMusicEnabled.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['notificationsEnabled'] = nativeToJson<bool>(notificationsEnabled);
    json['soundEffectsEnabled'] = nativeToJson<bool>(soundEffectsEnabled);
    json['backgroundMusicEnabled'] = nativeToJson<bool>(backgroundMusicEnabled);
    return json;
  }

  GetStudentSettingsStudentSettings({
    required this.notificationsEnabled,
    required this.soundEffectsEnabled,
    required this.backgroundMusicEnabled,
  });
}

@immutable
class GetStudentSettingsData {
  final GetStudentSettingsStudentSettings? studentSettings;
  GetStudentSettingsData.fromJson(dynamic json):
  
  studentSettings = json['studentSettings'] == null ? null : GetStudentSettingsStudentSettings.fromJson(json['studentSettings']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final GetStudentSettingsData otherTyped = other as GetStudentSettingsData;
    return studentSettings == otherTyped.studentSettings;
    
  }
  @override
  int get hashCode => studentSettings.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    if (studentSettings != null) {
      json['studentSettings'] = studentSettings!.toJson();
    }
    return json;
  }

  GetStudentSettingsData({
    this.studentSettings,
  });
}

@immutable
class GetStudentSettingsVariables {
  final String studentUid;
  @Deprecated('fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  GetStudentSettingsVariables.fromJson(Map<String, dynamic> json):
  
  studentUid = nativeFromJson<String>(json['studentUid']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final GetStudentSettingsVariables otherTyped = other as GetStudentSettingsVariables;
    return studentUid == otherTyped.studentUid;
    
  }
  @override
  int get hashCode => studentUid.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['studentUid'] = nativeToJson<String>(studentUid);
    return json;
  }

  GetStudentSettingsVariables({
    required this.studentUid,
  });
}

