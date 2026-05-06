part of 'generated.dart';

class GetWeeklyLeaderboardVariablesBuilder {
  
  final FirebaseDataConnect _dataConnect;
  GetWeeklyLeaderboardVariablesBuilder(this._dataConnect, );
  Deserializer<GetWeeklyLeaderboardData> dataDeserializer = (dynamic json)  => GetWeeklyLeaderboardData.fromJson(jsonDecode(json));
  
  Future<QueryResult<GetWeeklyLeaderboardData, void>> execute() {
    return ref().execute();
  }

  QueryRef<GetWeeklyLeaderboardData, void> ref() {
    
    return _dataConnect.query("GetWeeklyLeaderboard", dataDeserializer, emptySerializer, null);
  }
}

@immutable
class GetWeeklyLeaderboardStudents {
  final String uid;
  final int? weeklyXp;
  final int? totalXp;
  final Timestamp? lastActiveAt;
  final GetWeeklyLeaderboardStudentsUser user;
  GetWeeklyLeaderboardStudents.fromJson(dynamic json):
  
  uid = nativeFromJson<String>(json['uid']),
  weeklyXp = json['weeklyXp'] == null ? null : nativeFromJson<int>(json['weeklyXp']),
  totalXp = json['totalXp'] == null ? null : nativeFromJson<int>(json['totalXp']),
  lastActiveAt = json['lastActiveAt'] == null ? null : Timestamp.fromJson(json['lastActiveAt']),
  user = GetWeeklyLeaderboardStudentsUser.fromJson(json['user']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final GetWeeklyLeaderboardStudents otherTyped = other as GetWeeklyLeaderboardStudents;
    return uid == otherTyped.uid && 
    weeklyXp == otherTyped.weeklyXp && 
    totalXp == otherTyped.totalXp && 
    lastActiveAt == otherTyped.lastActiveAt && 
    user == otherTyped.user;
    
  }
  @override
  int get hashCode => Object.hashAll([uid.hashCode, weeklyXp.hashCode, totalXp.hashCode, lastActiveAt.hashCode, user.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['uid'] = nativeToJson<String>(uid);
    if (weeklyXp != null) {
      json['weeklyXp'] = nativeToJson<int?>(weeklyXp);
    }
    if (totalXp != null) {
      json['totalXp'] = nativeToJson<int?>(totalXp);
    }
    if (lastActiveAt != null) {
      json['lastActiveAt'] = lastActiveAt!.toJson();
    }
    json['user'] = user.toJson();
    return json;
  }

  GetWeeklyLeaderboardStudents({
    required this.uid,
    this.weeklyXp,
    this.totalXp,
    this.lastActiveAt,
    required this.user,
  });
}

@immutable
class GetWeeklyLeaderboardStudentsUser {
  final String fullName;
  GetWeeklyLeaderboardStudentsUser.fromJson(dynamic json):
  
  fullName = nativeFromJson<String>(json['fullName']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final GetWeeklyLeaderboardStudentsUser otherTyped = other as GetWeeklyLeaderboardStudentsUser;
    return fullName == otherTyped.fullName;
    
  }
  @override
  int get hashCode => fullName.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['fullName'] = nativeToJson<String>(fullName);
    return json;
  }

  GetWeeklyLeaderboardStudentsUser({
    required this.fullName,
  });
}

@immutable
class GetWeeklyLeaderboardData {
  final List<GetWeeklyLeaderboardStudents> students;
  GetWeeklyLeaderboardData.fromJson(dynamic json):
  
  students = (json['students'] as List<dynamic>)
        .map((e) => GetWeeklyLeaderboardStudents.fromJson(e))
        .toList();
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final GetWeeklyLeaderboardData otherTyped = other as GetWeeklyLeaderboardData;
    return students == otherTyped.students;
    
  }
  @override
  int get hashCode => students.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['students'] = students.map((e) => e.toJson()).toList();
    return json;
  }

  GetWeeklyLeaderboardData({
    required this.students,
  });
}

