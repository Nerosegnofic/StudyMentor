part of 'generated.dart';

class DeleteAllInstalledAppsForStudentVariablesBuilder {
  String studentUid;

  final FirebaseDataConnect _dataConnect;
  DeleteAllInstalledAppsForStudentVariablesBuilder(this._dataConnect, {required  this.studentUid,});
  Deserializer<DeleteAllInstalledAppsForStudentData> dataDeserializer = (dynamic json)  => DeleteAllInstalledAppsForStudentData.fromJson(jsonDecode(json));
  Serializer<DeleteAllInstalledAppsForStudentVariables> varsSerializer = (DeleteAllInstalledAppsForStudentVariables vars) => jsonEncode(vars.toJson());
  Future<OperationResult<DeleteAllInstalledAppsForStudentData, DeleteAllInstalledAppsForStudentVariables>> execute() {
    return ref().execute();
  }

  MutationRef<DeleteAllInstalledAppsForStudentData, DeleteAllInstalledAppsForStudentVariables> ref() {
    DeleteAllInstalledAppsForStudentVariables vars= DeleteAllInstalledAppsForStudentVariables(studentUid: studentUid,);
    return _dataConnect.mutation("DeleteAllInstalledAppsForStudent", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class DeleteAllInstalledAppsForStudentData {
  final int installedApp_deleteMany;
  DeleteAllInstalledAppsForStudentData.fromJson(dynamic json):
  
  installedApp_deleteMany = nativeFromJson<int>(json['installedApp_deleteMany']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final DeleteAllInstalledAppsForStudentData otherTyped = other as DeleteAllInstalledAppsForStudentData;
    return installedApp_deleteMany == otherTyped.installedApp_deleteMany;
    
  }
  @override
  int get hashCode => installedApp_deleteMany.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['installedApp_deleteMany'] = nativeToJson<int>(installedApp_deleteMany);
    return json;
  }

  DeleteAllInstalledAppsForStudentData({
    required this.installedApp_deleteMany,
  });
}

@immutable
class DeleteAllInstalledAppsForStudentVariables {
  final String studentUid;
  @Deprecated('fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  DeleteAllInstalledAppsForStudentVariables.fromJson(Map<String, dynamic> json):
  
  studentUid = nativeFromJson<String>(json['studentUid']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final DeleteAllInstalledAppsForStudentVariables otherTyped = other as DeleteAllInstalledAppsForStudentVariables;
    return studentUid == otherTyped.studentUid;
    
  }
  @override
  int get hashCode => studentUid.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['studentUid'] = nativeToJson<String>(studentUid);
    return json;
  }

  DeleteAllInstalledAppsForStudentVariables({
    required this.studentUid,
  });
}

