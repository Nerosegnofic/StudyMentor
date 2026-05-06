part of 'generated.dart';

class CreateFriendshipVariablesBuilder {
  String studentUid;
  String friendUid;

  final FirebaseDataConnect _dataConnect;
  CreateFriendshipVariablesBuilder(this._dataConnect, {required  this.studentUid,required  this.friendUid,});
  Deserializer<CreateFriendshipData> dataDeserializer = (dynamic json)  => CreateFriendshipData.fromJson(jsonDecode(json));
  Serializer<CreateFriendshipVariables> varsSerializer = (CreateFriendshipVariables vars) => jsonEncode(vars.toJson());
  Future<OperationResult<CreateFriendshipData, CreateFriendshipVariables>> execute() {
    return ref().execute();
  }

  MutationRef<CreateFriendshipData, CreateFriendshipVariables> ref() {
    CreateFriendshipVariables vars= CreateFriendshipVariables(studentUid: studentUid,friendUid: friendUid,);
    return _dataConnect.mutation("CreateFriendship", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class CreateFriendshipFriendshipInsert {
  final String id;
  CreateFriendshipFriendshipInsert.fromJson(dynamic json):
  
  id = nativeFromJson<String>(json['id']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final CreateFriendshipFriendshipInsert otherTyped = other as CreateFriendshipFriendshipInsert;
    return id == otherTyped.id;
    
  }
  @override
  int get hashCode => id.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    return json;
  }

  CreateFriendshipFriendshipInsert({
    required this.id,
  });
}

@immutable
class CreateFriendshipData {
  final CreateFriendshipFriendshipInsert friendship_insert;
  CreateFriendshipData.fromJson(dynamic json):
  
  friendship_insert = CreateFriendshipFriendshipInsert.fromJson(json['friendship_insert']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final CreateFriendshipData otherTyped = other as CreateFriendshipData;
    return friendship_insert == otherTyped.friendship_insert;
    
  }
  @override
  int get hashCode => friendship_insert.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['friendship_insert'] = friendship_insert.toJson();
    return json;
  }

  CreateFriendshipData({
    required this.friendship_insert,
  });
}

@immutable
class CreateFriendshipVariables {
  final String studentUid;
  final String friendUid;
  @Deprecated('fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  CreateFriendshipVariables.fromJson(Map<String, dynamic> json):
  
  studentUid = nativeFromJson<String>(json['studentUid']),
  friendUid = nativeFromJson<String>(json['friendUid']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final CreateFriendshipVariables otherTyped = other as CreateFriendshipVariables;
    return studentUid == otherTyped.studentUid && 
    friendUid == otherTyped.friendUid;
    
  }
  @override
  int get hashCode => Object.hashAll([studentUid.hashCode, friendUid.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['studentUid'] = nativeToJson<String>(studentUid);
    json['friendUid'] = nativeToJson<String>(friendUid);
    return json;
  }

  CreateFriendshipVariables({
    required this.studentUid,
    required this.friendUid,
  });
}

