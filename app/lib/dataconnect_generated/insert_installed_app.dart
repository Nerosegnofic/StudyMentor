part of 'generated.dart';

class InsertInstalledAppVariablesBuilder {
  String studentUid;
  String packageName;
  String appLabel;
  bool isSystemApp;

  final FirebaseDataConnect _dataConnect;
  InsertInstalledAppVariablesBuilder(this._dataConnect, {required  this.studentUid,required  this.packageName,required  this.appLabel,required  this.isSystemApp,});
  Deserializer<InsertInstalledAppData> dataDeserializer = (dynamic json)  => InsertInstalledAppData.fromJson(jsonDecode(json));
  Serializer<InsertInstalledAppVariables> varsSerializer = (InsertInstalledAppVariables vars) => jsonEncode(vars.toJson());
  Future<OperationResult<InsertInstalledAppData, InsertInstalledAppVariables>> execute() {
    return ref().execute();
  }

  MutationRef<InsertInstalledAppData, InsertInstalledAppVariables> ref() {
    InsertInstalledAppVariables vars= InsertInstalledAppVariables(studentUid: studentUid,packageName: packageName,appLabel: appLabel,isSystemApp: isSystemApp,);
    return _dataConnect.mutation("InsertInstalledApp", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class InsertInstalledAppInstalledAppInsert {
  final String id;
  InsertInstalledAppInstalledAppInsert.fromJson(dynamic json):
  
  id = nativeFromJson<String>(json['id']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final InsertInstalledAppInstalledAppInsert otherTyped = other as InsertInstalledAppInstalledAppInsert;
    return id == otherTyped.id;
    
  }
  @override
  int get hashCode => id.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    return json;
  }

  InsertInstalledAppInstalledAppInsert({
    required this.id,
  });
}

@immutable
class InsertInstalledAppData {
  final InsertInstalledAppInstalledAppInsert installedApp_insert;
  InsertInstalledAppData.fromJson(dynamic json):
  
  installedApp_insert = InsertInstalledAppInstalledAppInsert.fromJson(json['installedApp_insert']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final InsertInstalledAppData otherTyped = other as InsertInstalledAppData;
    return installedApp_insert == otherTyped.installedApp_insert;
    
  }
  @override
  int get hashCode => installedApp_insert.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['installedApp_insert'] = installedApp_insert.toJson();
    return json;
  }

  InsertInstalledAppData({
    required this.installedApp_insert,
  });
}

@immutable
class InsertInstalledAppVariables {
  final String studentUid;
  final String packageName;
  final String appLabel;
  final bool isSystemApp;
  @Deprecated('fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  InsertInstalledAppVariables.fromJson(Map<String, dynamic> json):
  
  studentUid = nativeFromJson<String>(json['studentUid']),
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

    final InsertInstalledAppVariables otherTyped = other as InsertInstalledAppVariables;
    return studentUid == otherTyped.studentUid && 
    packageName == otherTyped.packageName && 
    appLabel == otherTyped.appLabel && 
    isSystemApp == otherTyped.isSystemApp;
    
  }
  @override
  int get hashCode => Object.hashAll([studentUid.hashCode, packageName.hashCode, appLabel.hashCode, isSystemApp.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['studentUid'] = nativeToJson<String>(studentUid);
    json['packageName'] = nativeToJson<String>(packageName);
    json['appLabel'] = nativeToJson<String>(appLabel);
    json['isSystemApp'] = nativeToJson<bool>(isSystemApp);
    return json;
  }

  InsertInstalledAppVariables({
    required this.studentUid,
    required this.packageName,
    required this.appLabel,
    required this.isSystemApp,
  });
}

