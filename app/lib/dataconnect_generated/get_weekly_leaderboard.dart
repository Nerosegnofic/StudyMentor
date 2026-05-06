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
  final String username;
  final int? weeklyXp;
  final int? totalXp;
  final Timestamp? lastActiveAt;
  GetWeeklyLeaderboardStudents.fromJson(dynamic json):
  
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

    final GetWeeklyLeaderboardStudents otherTyped = other as GetWeeklyLeaderboardStudents;
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

  GetWeeklyLeaderboardStudents({
    required this.uid,
    required this.username,
    this.weeklyXp,
    this.totalXp,
    this.lastActiveAt,
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

