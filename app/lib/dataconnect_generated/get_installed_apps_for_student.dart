part of 'generated.dart';

class GetInstalledAppsForStudentVariablesBuilder {
  String studentUid;

  final FirebaseDataConnect _dataConnect;
  GetInstalledAppsForStudentVariablesBuilder(this._dataConnect, {required  this.studentUid,});
  Deserializer<GetInstalledAppsForStudentData> dataDeserializer = (dynamic json)  => GetInstalledAppsForStudentData.fromJson(jsonDecode(json));
  Serializer<GetInstalledAppsForStudentVariables> varsSerializer = (GetInstalledAppsForStudentVariables vars) => jsonEncode(vars.toJson());
  Future<QueryResult<GetInstalledAppsForStudentData, GetInstalledAppsForStudentVariables>> execute({QueryFetchPolicy fetchPolicy = QueryFetchPolicy.preferCache}) {
    return ref().execute(fetchPolicy: fetchPolicy);
  }

  QueryRef<GetInstalledAppsForStudentData, GetInstalledAppsForStudentVariables> ref() {
    GetInstalledAppsForStudentVariables vars= GetInstalledAppsForStudentVariables(studentUid: studentUid,);
    return _dataConnect.query("GetInstalledAppsForStudent", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class GetInstalledAppsForStudentInstalledApps {
  final String id;
  final String packageName;
  final String appLabel;
  final bool isSystemApp;
  GetInstalledAppsForStudentInstalledApps.fromJson(dynamic json):
  
  id = nativeFromJson<String>(json['id']),
  packageName = nativeFromJson<String>(json['packageName']),
  appLabel = nativeFromJson<String>(json['appLabel']),
  isSystemApp = nativeFromJson<bool>(json['isSystemApp']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final GetInstalledAppsForStudentInstalledApps otherTyped = other as GetInstalledAppsForStudentInstalledApps;
    return id == otherTyped.id && 
    packageName == otherTyped.packageName && 
    appLabel == otherTyped.appLabel && 
    isSystemApp == otherTyped.isSystemApp;
    
  }
  @override
  int get hashCode => Object.hashAll([id.hashCode, packageName.hashCode, appLabel.hashCode, isSystemApp.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    json['packageName'] = nativeToJson<String>(packageName);
    json['appLabel'] = nativeToJson<String>(appLabel);
    json['isSystemApp'] = nativeToJson<bool>(isSystemApp);
    return json;
  }

  GetInstalledAppsForStudentInstalledApps({
    required this.id,
    required this.packageName,
    required this.appLabel,
    required this.isSystemApp,
  });
}

@immutable
class GetInstalledAppsForStudentData {
  final List<GetInstalledAppsForStudentInstalledApps> installedApps;
  GetInstalledAppsForStudentData.fromJson(dynamic json):
  
  installedApps = (json['installedApps'] as List<dynamic>)
        .map((e) => GetInstalledAppsForStudentInstalledApps.fromJson(e))
        .toList();
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final GetInstalledAppsForStudentData otherTyped = other as GetInstalledAppsForStudentData;
    return installedApps == otherTyped.installedApps;
    
  }
  @override
  int get hashCode => installedApps.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['installedApps'] = installedApps.map((e) => e.toJson()).toList();
    return json;
  }

  GetInstalledAppsForStudentData({
    required this.installedApps,
  });
}

@immutable
class GetInstalledAppsForStudentVariables {
  final String studentUid;
  @Deprecated('fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  GetInstalledAppsForStudentVariables.fromJson(Map<String, dynamic> json):
  
  studentUid = nativeFromJson<String>(json['studentUid']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final GetInstalledAppsForStudentVariables otherTyped = other as GetInstalledAppsForStudentVariables;
    return studentUid == otherTyped.studentUid;
    
  }
  @override
  int get hashCode => studentUid.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['studentUid'] = nativeToJson<String>(studentUid);
    return json;
  }

  GetInstalledAppsForStudentVariables({
    required this.studentUid,
  });
}

