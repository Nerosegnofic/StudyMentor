part of 'generated.dart';

class DeleteAllOwnedItemsForStudentVariablesBuilder {
  String studentUid;

  final FirebaseDataConnect _dataConnect;
  DeleteAllOwnedItemsForStudentVariablesBuilder(this._dataConnect, {required  this.studentUid,});
  Deserializer<DeleteAllOwnedItemsForStudentData> dataDeserializer = (dynamic json)  => DeleteAllOwnedItemsForStudentData.fromJson(jsonDecode(json));
  Serializer<DeleteAllOwnedItemsForStudentVariables> varsSerializer = (DeleteAllOwnedItemsForStudentVariables vars) => jsonEncode(vars.toJson());
  Future<OperationResult<DeleteAllOwnedItemsForStudentData, DeleteAllOwnedItemsForStudentVariables>> execute() {
    return ref().execute();
  }

  MutationRef<DeleteAllOwnedItemsForStudentData, DeleteAllOwnedItemsForStudentVariables> ref() {
    DeleteAllOwnedItemsForStudentVariables vars= DeleteAllOwnedItemsForStudentVariables(studentUid: studentUid,);
    return _dataConnect.mutation("DeleteAllOwnedItemsForStudent", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class DeleteAllOwnedItemsForStudentData {
  final int studentOwnedItem_deleteMany;
  DeleteAllOwnedItemsForStudentData.fromJson(dynamic json):
  
  studentOwnedItem_deleteMany = nativeFromJson<int>(json['studentOwnedItem_deleteMany']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final DeleteAllOwnedItemsForStudentData otherTyped = other as DeleteAllOwnedItemsForStudentData;
    return studentOwnedItem_deleteMany == otherTyped.studentOwnedItem_deleteMany;
    
  }
  @override
  int get hashCode => studentOwnedItem_deleteMany.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['studentOwnedItem_deleteMany'] = nativeToJson<int>(studentOwnedItem_deleteMany);
    return json;
  }

  DeleteAllOwnedItemsForStudentData({
    required this.studentOwnedItem_deleteMany,
  });
}

@immutable
class DeleteAllOwnedItemsForStudentVariables {
  final String studentUid;
  @Deprecated('fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  DeleteAllOwnedItemsForStudentVariables.fromJson(Map<String, dynamic> json):
  
  studentUid = nativeFromJson<String>(json['studentUid']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final DeleteAllOwnedItemsForStudentVariables otherTyped = other as DeleteAllOwnedItemsForStudentVariables;
    return studentUid == otherTyped.studentUid;
    
  }
  @override
  int get hashCode => studentUid.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['studentUid'] = nativeToJson<String>(studentUid);
    return json;
  }

  DeleteAllOwnedItemsForStudentVariables({
    required this.studentUid,
  });
}

