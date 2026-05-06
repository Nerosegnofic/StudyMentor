part of 'generated.dart';

class GetFriendsForStudentVariablesBuilder {
  String studentUid;

  final FirebaseDataConnect _dataConnect;
  GetFriendsForStudentVariablesBuilder(this._dataConnect, {required  this.studentUid,});
  Deserializer<GetFriendsForStudentData> dataDeserializer = (dynamic json)  => GetFriendsForStudentData.fromJson(jsonDecode(json));
  Serializer<GetFriendsForStudentVariables> varsSerializer = (GetFriendsForStudentVariables vars) => jsonEncode(vars.toJson());
  Future<QueryResult<GetFriendsForStudentData, GetFriendsForStudentVariables>> execute() {
    return ref().execute();
  }

  QueryRef<GetFriendsForStudentData, GetFriendsForStudentVariables> ref() {
    GetFriendsForStudentVariables vars= GetFriendsForStudentVariables(studentUid: studentUid,);
    return _dataConnect.query("GetFriendsForStudent", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class GetFriendsForStudentFriendships {
  final String id;
  final String friendUid;
  final GetFriendsForStudentFriendshipsFriend friend;
  GetFriendsForStudentFriendships.fromJson(dynamic json):
  
  id = nativeFromJson<String>(json['id']),
  friendUid = nativeFromJson<String>(json['friendUid']),
  friend = GetFriendsForStudentFriendshipsFriend.fromJson(json['friend']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final GetFriendsForStudentFriendships otherTyped = other as GetFriendsForStudentFriendships;
    return id == otherTyped.id && 
    friendUid == otherTyped.friendUid && 
    friend == otherTyped.friend;
    
  }
  @override
  int get hashCode => Object.hashAll([id.hashCode, friendUid.hashCode, friend.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    json['friendUid'] = nativeToJson<String>(friendUid);
    json['friend'] = friend.toJson();
    return json;
  }

  GetFriendsForStudentFriendships({
    required this.id,
    required this.friendUid,
    required this.friend,
  });
}

@immutable
class GetFriendsForStudentFriendshipsFriend {
  final String uid;
  final int? totalXp;
  final int? weeklyXp;
  final Timestamp? lastActiveAt;
  final GetFriendsForStudentFriendshipsFriendUser user;
  GetFriendsForStudentFriendshipsFriend.fromJson(dynamic json):
  
  uid = nativeFromJson<String>(json['uid']),
  totalXp = json['totalXp'] == null ? null : nativeFromJson<int>(json['totalXp']),
  weeklyXp = json['weeklyXp'] == null ? null : nativeFromJson<int>(json['weeklyXp']),
  lastActiveAt = json['lastActiveAt'] == null ? null : Timestamp.fromJson(json['lastActiveAt']),
  user = GetFriendsForStudentFriendshipsFriendUser.fromJson(json['user']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final GetFriendsForStudentFriendshipsFriend otherTyped = other as GetFriendsForStudentFriendshipsFriend;
    return uid == otherTyped.uid && 
    totalXp == otherTyped.totalXp && 
    weeklyXp == otherTyped.weeklyXp && 
    lastActiveAt == otherTyped.lastActiveAt && 
    user == otherTyped.user;
    
  }
  @override
  int get hashCode => Object.hashAll([uid.hashCode, totalXp.hashCode, weeklyXp.hashCode, lastActiveAt.hashCode, user.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['uid'] = nativeToJson<String>(uid);
    if (totalXp != null) {
      json['totalXp'] = nativeToJson<int?>(totalXp);
    }
    if (weeklyXp != null) {
      json['weeklyXp'] = nativeToJson<int?>(weeklyXp);
    }
    if (lastActiveAt != null) {
      json['lastActiveAt'] = lastActiveAt!.toJson();
    }
    json['user'] = user.toJson();
    return json;
  }

  GetFriendsForStudentFriendshipsFriend({
    required this.uid,
    this.totalXp,
    this.weeklyXp,
    this.lastActiveAt,
    required this.user,
  });
}

@immutable
class GetFriendsForStudentFriendshipsFriendUser {
  final String fullName;
  GetFriendsForStudentFriendshipsFriendUser.fromJson(dynamic json):
  
  fullName = nativeFromJson<String>(json['fullName']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final GetFriendsForStudentFriendshipsFriendUser otherTyped = other as GetFriendsForStudentFriendshipsFriendUser;
    return fullName == otherTyped.fullName;
    
  }
  @override
  int get hashCode => fullName.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['fullName'] = nativeToJson<String>(fullName);
    return json;
  }

  GetFriendsForStudentFriendshipsFriendUser({
    required this.fullName,
  });
}

@immutable
class GetFriendsForStudentData {
  final List<GetFriendsForStudentFriendships> friendships;
  GetFriendsForStudentData.fromJson(dynamic json):
  
  friendships = (json['friendships'] as List<dynamic>)
        .map((e) => GetFriendsForStudentFriendships.fromJson(e))
        .toList();
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final GetFriendsForStudentData otherTyped = other as GetFriendsForStudentData;
    return friendships == otherTyped.friendships;
    
  }
  @override
  int get hashCode => friendships.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['friendships'] = friendships.map((e) => e.toJson()).toList();
    return json;
  }

  GetFriendsForStudentData({
    required this.friendships,
  });
}

@immutable
class GetFriendsForStudentVariables {
  final String studentUid;
  @Deprecated('fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  GetFriendsForStudentVariables.fromJson(Map<String, dynamic> json):
  
  studentUid = nativeFromJson<String>(json['studentUid']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final GetFriendsForStudentVariables otherTyped = other as GetFriendsForStudentVariables;
    return studentUid == otherTyped.studentUid;
    
  }
  @override
  int get hashCode => studentUid.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['studentUid'] = nativeToJson<String>(studentUid);
    return json;
  }

  GetFriendsForStudentVariables({
    required this.studentUid,
  });
}

