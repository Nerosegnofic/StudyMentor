part of 'generated.dart';

class GetPendingFriendRequestsForParentVariablesBuilder {
  String parentUid;

  final FirebaseDataConnect _dataConnect;
  GetPendingFriendRequestsForParentVariablesBuilder(this._dataConnect, {required  this.parentUid,});
  Deserializer<GetPendingFriendRequestsForParentData> dataDeserializer = (dynamic json)  => GetPendingFriendRequestsForParentData.fromJson(jsonDecode(json));
  Serializer<GetPendingFriendRequestsForParentVariables> varsSerializer = (GetPendingFriendRequestsForParentVariables vars) => jsonEncode(vars.toJson());
  Future<QueryResult<GetPendingFriendRequestsForParentData, GetPendingFriendRequestsForParentVariables>> execute() {
    return ref().execute();
  }

  QueryRef<GetPendingFriendRequestsForParentData, GetPendingFriendRequestsForParentVariables> ref() {
    GetPendingFriendRequestsForParentVariables vars= GetPendingFriendRequestsForParentVariables(parentUid: parentUid,);
    return _dataConnect.query("GetPendingFriendRequestsForParent", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class GetPendingFriendRequestsForParentFriendRequests {
  final String id;
  final String toFriendCode;
  final String toStudentName;
  final String toStudentUid;
  final Timestamp createdAt;
  final String fromStudentUid;
  final GetPendingFriendRequestsForParentFriendRequestsFromStudent fromStudent;
  GetPendingFriendRequestsForParentFriendRequests.fromJson(dynamic json):
  
  id = nativeFromJson<String>(json['id']),
  toFriendCode = nativeFromJson<String>(json['toFriendCode']),
  toStudentName = nativeFromJson<String>(json['toStudentName']),
  toStudentUid = nativeFromJson<String>(json['toStudentUid']),
  createdAt = Timestamp.fromJson(json['createdAt']),
  fromStudentUid = nativeFromJson<String>(json['fromStudentUid']),
  fromStudent = GetPendingFriendRequestsForParentFriendRequestsFromStudent.fromJson(json['fromStudent']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final GetPendingFriendRequestsForParentFriendRequests otherTyped = other as GetPendingFriendRequestsForParentFriendRequests;
    return id == otherTyped.id && 
    toFriendCode == otherTyped.toFriendCode && 
    toStudentName == otherTyped.toStudentName && 
    toStudentUid == otherTyped.toStudentUid && 
    createdAt == otherTyped.createdAt && 
    fromStudentUid == otherTyped.fromStudentUid && 
    fromStudent == otherTyped.fromStudent;
    
  }
  @override
  int get hashCode => Object.hashAll([id.hashCode, toFriendCode.hashCode, toStudentName.hashCode, toStudentUid.hashCode, createdAt.hashCode, fromStudentUid.hashCode, fromStudent.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    json['toFriendCode'] = nativeToJson<String>(toFriendCode);
    json['toStudentName'] = nativeToJson<String>(toStudentName);
    json['toStudentUid'] = nativeToJson<String>(toStudentUid);
    json['createdAt'] = createdAt.toJson();
    json['fromStudentUid'] = nativeToJson<String>(fromStudentUid);
    json['fromStudent'] = fromStudent.toJson();
    return json;
  }

  GetPendingFriendRequestsForParentFriendRequests({
    required this.id,
    required this.toFriendCode,
    required this.toStudentName,
    required this.toStudentUid,
    required this.createdAt,
    required this.fromStudentUid,
    required this.fromStudent,
  });
}

@immutable
class GetPendingFriendRequestsForParentFriendRequestsFromStudent {
  final String uid;
  final GetPendingFriendRequestsForParentFriendRequestsFromStudentUser user;
  GetPendingFriendRequestsForParentFriendRequestsFromStudent.fromJson(dynamic json):
  
  uid = nativeFromJson<String>(json['uid']),
  user = GetPendingFriendRequestsForParentFriendRequestsFromStudentUser.fromJson(json['user']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final GetPendingFriendRequestsForParentFriendRequestsFromStudent otherTyped = other as GetPendingFriendRequestsForParentFriendRequestsFromStudent;
    return uid == otherTyped.uid && 
    user == otherTyped.user;
    
  }
  @override
  int get hashCode => Object.hashAll([uid.hashCode, user.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['uid'] = nativeToJson<String>(uid);
    json['user'] = user.toJson();
    return json;
  }

  GetPendingFriendRequestsForParentFriendRequestsFromStudent({
    required this.uid,
    required this.user,
  });
}

@immutable
class GetPendingFriendRequestsForParentFriendRequestsFromStudentUser {
  final String fullName;
  GetPendingFriendRequestsForParentFriendRequestsFromStudentUser.fromJson(dynamic json):
  
  fullName = nativeFromJson<String>(json['fullName']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final GetPendingFriendRequestsForParentFriendRequestsFromStudentUser otherTyped = other as GetPendingFriendRequestsForParentFriendRequestsFromStudentUser;
    return fullName == otherTyped.fullName;
    
  }
  @override
  int get hashCode => fullName.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['fullName'] = nativeToJson<String>(fullName);
    return json;
  }

  GetPendingFriendRequestsForParentFriendRequestsFromStudentUser({
    required this.fullName,
  });
}

@immutable
class GetPendingFriendRequestsForParentData {
  final List<GetPendingFriendRequestsForParentFriendRequests> friendRequests;
  GetPendingFriendRequestsForParentData.fromJson(dynamic json):
  
  friendRequests = (json['friendRequests'] as List<dynamic>)
        .map((e) => GetPendingFriendRequestsForParentFriendRequests.fromJson(e))
        .toList();
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final GetPendingFriendRequestsForParentData otherTyped = other as GetPendingFriendRequestsForParentData;
    return friendRequests == otherTyped.friendRequests;
    
  }
  @override
  int get hashCode => friendRequests.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['friendRequests'] = friendRequests.map((e) => e.toJson()).toList();
    return json;
  }

  GetPendingFriendRequestsForParentData({
    required this.friendRequests,
  });
}

@immutable
class GetPendingFriendRequestsForParentVariables {
  final String parentUid;
  @Deprecated('fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  GetPendingFriendRequestsForParentVariables.fromJson(Map<String, dynamic> json):
  
  parentUid = nativeFromJson<String>(json['parentUid']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final GetPendingFriendRequestsForParentVariables otherTyped = other as GetPendingFriendRequestsForParentVariables;
    return parentUid == otherTyped.parentUid;
    
  }
  @override
  int get hashCode => parentUid.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['parentUid'] = nativeToJson<String>(parentUid);
    return json;
  }

  GetPendingFriendRequestsForParentVariables({
    required this.parentUid,
  });
}

