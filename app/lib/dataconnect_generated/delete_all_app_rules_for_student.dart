part of 'generated.dart';

class DeleteAllAppRulesForStudentVariablesBuilder {
  String studentUid;

  final FirebaseDataConnect _dataConnect;
  DeleteAllAppRulesForStudentVariablesBuilder(this._dataConnect, {required  this.studentUid,});
  Deserializer<DeleteAllAppRulesForStudentData> dataDeserializer = (dynamic json)  => DeleteAllAppRulesForStudentData.fromJson(jsonDecode(json));
  Serializer<DeleteAllAppRulesForStudentVariables> varsSerializer = (DeleteAllAppRulesForStudentVariables vars) => jsonEncode(vars.toJson());
  Future<OperationResult<DeleteAllAppRulesForStudentData, DeleteAllAppRulesForStudentVariables>> execute() {
    return ref().execute();
  }

  MutationRef<DeleteAllAppRulesForStudentData, DeleteAllAppRulesForStudentVariables> ref() {
    DeleteAllAppRulesForStudentVariables vars= DeleteAllAppRulesForStudentVariables(studentUid: studentUid,);
    return _dataConnect.mutation("DeleteAllAppRulesForStudent", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class DeleteAllAppRulesForStudentData {
  final int appRule_deleteMany;
  DeleteAllAppRulesForStudentData.fromJson(dynamic json):
  
  appRule_deleteMany = nativeFromJson<int>(json['appRule_deleteMany']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final DeleteAllAppRulesForStudentData otherTyped = other as DeleteAllAppRulesForStudentData;
    return appRule_deleteMany == otherTyped.appRule_deleteMany;
    
  }
  @override
  int get hashCode => appRule_deleteMany.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['appRule_deleteMany'] = nativeToJson<int>(appRule_deleteMany);
    return json;
  }

  DeleteAllAppRulesForStudentData({
    required this.appRule_deleteMany,
  });
}

@immutable
class DeleteAllAppRulesForStudentVariables {
  final String studentUid;
  @Deprecated('fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  DeleteAllAppRulesForStudentVariables.fromJson(Map<String, dynamic> json):
  
  studentUid = nativeFromJson<String>(json['studentUid']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final DeleteAllAppRulesForStudentVariables otherTyped = other as DeleteAllAppRulesForStudentVariables;
    return studentUid == otherTyped.studentUid;
    
  }
  @override
  int get hashCode => studentUid.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['studentUid'] = nativeToJson<String>(studentUid);
    return json;
  }

  DeleteAllAppRulesForStudentVariables({
    required this.studentUid,
  });
}

