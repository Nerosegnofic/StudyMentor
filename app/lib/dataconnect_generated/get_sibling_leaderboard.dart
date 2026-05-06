part of 'generated.dart';

class GetSiblingLeaderboardVariablesBuilder {
  String parentUid;

  final FirebaseDataConnect _dataConnect;
  GetSiblingLeaderboardVariablesBuilder(this._dataConnect, {required  this.parentUid,});
  Deserializer<GetSiblingLeaderboardData> dataDeserializer = (dynamic json)  => GetSiblingLeaderboardData.fromJson(jsonDecode(json));
  Serializer<GetSiblingLeaderboardVariables> varsSerializer = (GetSiblingLeaderboardVariables vars) => jsonEncode(vars.toJson());
  Future<QueryResult<GetSiblingLeaderboardData, GetSiblingLeaderboardVariables>> execute() {
    return ref().execute();
  }

  QueryRef<GetSiblingLeaderboardData, GetSiblingLeaderboardVariables> ref() {
    GetSiblingLeaderboardVariables vars= GetSiblingLeaderboardVariables(parentUid: parentUid,);
    return _dataConnect.query("GetSiblingLeaderboard", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class GetSiblingLeaderboardStudents {
  final String uid;
  final String username;
  final int? weeklyXp;
  final int? totalXp;
  final Timestamp? lastActiveAt;
  GetSiblingLeaderboardStudents.fromJson(dynamic json):
  
  uid = nativeFromJson<String>(json['uid']),
  username = nativeFromJson<String>(json['username']),
  weeklyXp = json['weeklyXp'] == null ? null : nativeFromJson<int>(json['weeklyXp']),
  totalXp = json['totalXp'] == null ? null : nativeFromJson<int>(json['totalXp']),
  lastActiveAt = json['lastActiveAt'] == null ? null : Timestamp.fromJson(json['lastActiveAt']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final GetSiblingLeaderboardStudents otherTyped = other as GetSiblingLeaderboardStudents;
    return uid == otherTyped.uid && 
    username == otherTyped.username && 
    weeklyXp == otherTyped.weeklyXp && 
    totalXp == otherTyped.totalXp && 
    lastActiveAt == otherTyped.lastActiveAt;
    
  }
  @override
  int get hashCode => Object.hashAll([uid.hashCode, username.hashCode, weeklyXp.hashCode, totalXp.hashCode, lastActiveAt.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['uid'] = nativeToJson<String>(uid);
    json['username'] = nativeToJson<String>(username);
    if (weeklyXp != null) {
      json['weeklyXp'] = nativeToJson<int?>(weeklyXp);
    }
    if (totalXp != null) {
      json['totalXp'] = nativeToJson<int?>(totalXp);
    }
    if (lastActiveAt != null) {
      json['lastActiveAt'] = lastActiveAt!.toJson();
    }
    return json;
  }

  GetSiblingLeaderboardStudents({
    required this.uid,
    required this.username,
    this.weeklyXp,
    this.totalXp,
    this.lastActiveAt,
  });
}

@immutable
class GetSiblingLeaderboardData {
  final List<GetSiblingLeaderboardStudents> students;
  GetSiblingLeaderboardData.fromJson(dynamic json):
  
  students = (json['students'] as List<dynamic>)
        .map((e) => GetSiblingLeaderboardStudents.fromJson(e))
        .toList();
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final GetSiblingLeaderboardData otherTyped = other as GetSiblingLeaderboardData;
    return students == otherTyped.students;
    
  }
  @override
  int get hashCode => students.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['students'] = students.map((e) => e.toJson()).toList();
    return json;
  }

  GetSiblingLeaderboardData({
    required this.students,
  });
}

@immutable
class GetSiblingLeaderboardVariables {
  final String parentUid;
  @Deprecated('fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  GetSiblingLeaderboardVariables.fromJson(Map<String, dynamic> json):
  
  parentUid = nativeFromJson<String>(json['parentUid']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final GetSiblingLeaderboardVariables otherTyped = other as GetSiblingLeaderboardVariables;
    return parentUid == otherTyped.parentUid;
    
  }
  @override
  int get hashCode => parentUid.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['parentUid'] = nativeToJson<String>(parentUid);
    return json;
  }

  GetSiblingLeaderboardVariables({
    required this.parentUid,
  });
}

