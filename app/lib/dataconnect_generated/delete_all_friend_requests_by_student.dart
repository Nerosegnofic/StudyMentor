part of 'generated.dart';

class DeleteAllFriendRequestsByStudentVariablesBuilder {
  String studentUid;

  final FirebaseDataConnect _dataConnect;
  DeleteAllFriendRequestsByStudentVariablesBuilder(this._dataConnect, {required  this.studentUid,});
  Deserializer<DeleteAllFriendRequestsByStudentData> dataDeserializer = (dynamic json)  => DeleteAllFriendRequestsByStudentData.fromJson(jsonDecode(json));
  Serializer<DeleteAllFriendRequestsByStudentVariables> varsSerializer = (DeleteAllFriendRequestsByStudentVariables vars) => jsonEncode(vars.toJson());
  Future<OperationResult<DeleteAllFriendRequestsByStudentData, DeleteAllFriendRequestsByStudentVariables>> execute() {
    return ref().execute();
  }

  MutationRef<DeleteAllFriendRequestsByStudentData, DeleteAllFriendRequestsByStudentVariables> ref() {
    DeleteAllFriendRequestsByStudentVariables vars= DeleteAllFriendRequestsByStudentVariables(studentUid: studentUid,);
    return _dataConnect.mutation("DeleteAllFriendRequestsByStudent", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class DeleteAllFriendRequestsByStudentData {
  final int friendRequest_deleteMany;
  DeleteAllFriendRequestsByStudentData.fromJson(dynamic json):
  
  friendRequest_deleteMany = nativeFromJson<int>(json['friendRequest_deleteMany']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final DeleteAllFriendRequestsByStudentData otherTyped = other as DeleteAllFriendRequestsByStudentData;
    return friendRequest_deleteMany == otherTyped.friendRequest_deleteMany;
    
  }
  @override
  int get hashCode => friendRequest_deleteMany.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['friendRequest_deleteMany'] = nativeToJson<int>(friendRequest_deleteMany);
    return json;
  }

  DeleteAllFriendRequestsByStudentData({
    required this.friendRequest_deleteMany,
  });
}

@immutable
class DeleteAllFriendRequestsByStudentVariables {
  final String studentUid;
  @Deprecated('fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  DeleteAllFriendRequestsByStudentVariables.fromJson(Map<String, dynamic> json):
  
  studentUid = nativeFromJson<String>(json['studentUid']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final DeleteAllFriendRequestsByStudentVariables otherTyped = other as DeleteAllFriendRequestsByStudentVariables;
    return studentUid == otherTyped.studentUid;
    
  }
  @override
  int get hashCode => studentUid.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['studentUid'] = nativeToJson<String>(studentUid);
    return json;
  }

  DeleteAllFriendRequestsByStudentVariables({
    required this.studentUid,
  });
}

