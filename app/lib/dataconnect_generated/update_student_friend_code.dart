part of 'generated.dart';

class UpdateStudentFriendCodeVariablesBuilder {
  String friendCode;

  final FirebaseDataConnect _dataConnect;
  UpdateStudentFriendCodeVariablesBuilder(this._dataConnect, {required  this.friendCode,});
  Deserializer<UpdateStudentFriendCodeData> dataDeserializer = (dynamic json)  => UpdateStudentFriendCodeData.fromJson(jsonDecode(json));
  Serializer<UpdateStudentFriendCodeVariables> varsSerializer = (UpdateStudentFriendCodeVariables vars) => jsonEncode(vars.toJson());
  Future<OperationResult<UpdateStudentFriendCodeData, UpdateStudentFriendCodeVariables>> execute() {
    return ref().execute();
  }

  MutationRef<UpdateStudentFriendCodeData, UpdateStudentFriendCodeVariables> ref() {
    UpdateStudentFriendCodeVariables vars= UpdateStudentFriendCodeVariables(friendCode: friendCode,);
    return _dataConnect.mutation("UpdateStudentFriendCode", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class UpdateStudentFriendCodeStudentUpdate {
  final String uid;
  UpdateStudentFriendCodeStudentUpdate.fromJson(dynamic json):
  
  uid = nativeFromJson<String>(json['uid']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final UpdateStudentFriendCodeStudentUpdate otherTyped = other as UpdateStudentFriendCodeStudentUpdate;
    return uid == otherTyped.uid;
    
  }
  @override
  int get hashCode => uid.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['uid'] = nativeToJson<String>(uid);
    return json;
  }

  UpdateStudentFriendCodeStudentUpdate({
    required this.uid,
  });
}

@immutable
class UpdateStudentFriendCodeData {
  final UpdateStudentFriendCodeStudentUpdate? student_update;
  UpdateStudentFriendCodeData.fromJson(dynamic json):
  
  student_update = json['student_update'] == null ? null : UpdateStudentFriendCodeStudentUpdate.fromJson(json['student_update']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final UpdateStudentFriendCodeData otherTyped = other as UpdateStudentFriendCodeData;
    return student_update == otherTyped.student_update;
    
  }
  @override
  int get hashCode => student_update.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    if (student_update != null) {
      json['student_update'] = student_update!.toJson();
    }
    return json;
  }

  UpdateStudentFriendCodeData({
    this.student_update,
  });
}

@immutable
class UpdateStudentFriendCodeVariables {
  final String friendCode;
  @Deprecated('fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  UpdateStudentFriendCodeVariables.fromJson(Map<String, dynamic> json):
  
  friendCode = nativeFromJson<String>(json['friendCode']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final UpdateStudentFriendCodeVariables otherTyped = other as UpdateStudentFriendCodeVariables;
    return friendCode == otherTyped.friendCode;
    
  }
  @override
  int get hashCode => friendCode.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['friendCode'] = nativeToJson<String>(friendCode);
    return json;
  }

  UpdateStudentFriendCodeVariables({
    required this.friendCode,
  });
}

