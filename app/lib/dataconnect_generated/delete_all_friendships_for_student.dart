part of 'generated.dart';

class DeleteAllFriendshipsForStudentVariablesBuilder {
  String studentUid;

  final FirebaseDataConnect _dataConnect;
  DeleteAllFriendshipsForStudentVariablesBuilder(this._dataConnect, {required  this.studentUid,});
  Deserializer<DeleteAllFriendshipsForStudentData> dataDeserializer = (dynamic json)  => DeleteAllFriendshipsForStudentData.fromJson(jsonDecode(json));
  Serializer<DeleteAllFriendshipsForStudentVariables> varsSerializer = (DeleteAllFriendshipsForStudentVariables vars) => jsonEncode(vars.toJson());
  Future<OperationResult<DeleteAllFriendshipsForStudentData, DeleteAllFriendshipsForStudentVariables>> execute() {
    return ref().execute();
  }

  MutationRef<DeleteAllFriendshipsForStudentData, DeleteAllFriendshipsForStudentVariables> ref() {
    DeleteAllFriendshipsForStudentVariables vars= DeleteAllFriendshipsForStudentVariables(studentUid: studentUid,);
    return _dataConnect.mutation("DeleteAllFriendshipsForStudent", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class DeleteAllFriendshipsForStudentData {
  final int friendship_deleteMany;
  DeleteAllFriendshipsForStudentData.fromJson(dynamic json):
  
  friendship_deleteMany = nativeFromJson<int>(json['friendship_deleteMany']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final DeleteAllFriendshipsForStudentData otherTyped = other as DeleteAllFriendshipsForStudentData;
    return friendship_deleteMany == otherTyped.friendship_deleteMany;
    
  }
  @override
  int get hashCode => friendship_deleteMany.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['friendship_deleteMany'] = nativeToJson<int>(friendship_deleteMany);
    return json;
  }

  DeleteAllFriendshipsForStudentData({
    required this.friendship_deleteMany,
  });
}

@immutable
class DeleteAllFriendshipsForStudentVariables {
  final String studentUid;
  @Deprecated('fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  DeleteAllFriendshipsForStudentVariables.fromJson(Map<String, dynamic> json):
  
  studentUid = nativeFromJson<String>(json['studentUid']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final DeleteAllFriendshipsForStudentVariables otherTyped = other as DeleteAllFriendshipsForStudentVariables;
    return studentUid == otherTyped.studentUid;
    
  }
  @override
  int get hashCode => studentUid.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['studentUid'] = nativeToJson<String>(studentUid);
    return json;
  }

  DeleteAllFriendshipsForStudentVariables({
    required this.studentUid,
  });
}

