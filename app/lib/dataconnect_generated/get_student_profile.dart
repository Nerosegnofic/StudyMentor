part of 'generated.dart';

class GetStudentProfileVariablesBuilder {
  String uid;

  final FirebaseDataConnect _dataConnect;
  GetStudentProfileVariablesBuilder(this._dataConnect, {required  this.uid,});
  Deserializer<GetStudentProfileData> dataDeserializer = (dynamic json)  => GetStudentProfileData.fromJson(jsonDecode(json));
  Serializer<GetStudentProfileVariables> varsSerializer = (GetStudentProfileVariables vars) => jsonEncode(vars.toJson());
  Future<QueryResult<GetStudentProfileData, GetStudentProfileVariables>> execute() {
    return ref().execute();
  }

  QueryRef<GetStudentProfileData, GetStudentProfileVariables> ref() {
    GetStudentProfileVariables vars= GetStudentProfileVariables(uid: uid,);
    return _dataConnect.query("GetStudentProfile", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class GetStudentProfileStudent {
  final String uid;
  final String? friendCode;
  final int? totalXp;
  final int? totalCoins;
  final int? gradeLevel;
  final int? totalQuestionsAnswered;
  final int? currentStreak;
  GetStudentProfileStudent.fromJson(dynamic json):
  
  uid = nativeFromJson<String>(json['uid']),
  friendCode = json['friendCode'] == null ? null : nativeFromJson<String>(json['friendCode']),
  totalXp = json['totalXp'] == null ? null : nativeFromJson<int>(json['totalXp']),
  totalCoins = json['totalCoins'] == null ? null : nativeFromJson<int>(json['totalCoins']),
  gradeLevel = json['gradeLevel'] == null ? null : nativeFromJson<int>(json['gradeLevel']),
  totalQuestionsAnswered = json['totalQuestionsAnswered'] == null ? null : nativeFromJson<int>(json['totalQuestionsAnswered']),
  currentStreak = json['currentStreak'] == null ? null : nativeFromJson<int>(json['currentStreak']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final GetStudentProfileStudent otherTyped = other as GetStudentProfileStudent;
    return uid == otherTyped.uid && 
    friendCode == otherTyped.friendCode && 
    totalXp == otherTyped.totalXp && 
    totalCoins == otherTyped.totalCoins && 
    gradeLevel == otherTyped.gradeLevel && 
    totalQuestionsAnswered == otherTyped.totalQuestionsAnswered && 
    currentStreak == otherTyped.currentStreak;
    
  }
  @override
  int get hashCode => Object.hashAll([uid.hashCode, friendCode.hashCode, totalXp.hashCode, totalCoins.hashCode, gradeLevel.hashCode, totalQuestionsAnswered.hashCode, currentStreak.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['uid'] = nativeToJson<String>(uid);
    if (friendCode != null) {
      json['friendCode'] = nativeToJson<String?>(friendCode);
    }
    if (totalXp != null) {
      json['totalXp'] = nativeToJson<int?>(totalXp);
    }
    if (totalCoins != null) {
      json['totalCoins'] = nativeToJson<int?>(totalCoins);
    }
    if (gradeLevel != null) {
      json['gradeLevel'] = nativeToJson<int?>(gradeLevel);
    }
    if (totalQuestionsAnswered != null) {
      json['totalQuestionsAnswered'] = nativeToJson<int?>(totalQuestionsAnswered);
    }
    if (currentStreak != null) {
      json['currentStreak'] = nativeToJson<int?>(currentStreak);
    }
    return json;
  }

  GetStudentProfileStudent({
    required this.uid,
    this.friendCode,
    this.totalXp,
    this.totalCoins,
    this.gradeLevel,
    this.totalQuestionsAnswered,
    this.currentStreak,
  });
}

@immutable
class GetStudentProfileData {
  final GetStudentProfileStudent? student;
  GetStudentProfileData.fromJson(dynamic json):
  
  student = json['student'] == null ? null : GetStudentProfileStudent.fromJson(json['student']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final GetStudentProfileData otherTyped = other as GetStudentProfileData;
    return student == otherTyped.student;
    
  }
  @override
  int get hashCode => student.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    if (student != null) {
      json['student'] = student!.toJson();
    }
    return json;
  }

  GetStudentProfileData({
    this.student,
  });
}

@immutable
class GetStudentProfileVariables {
  final String uid;
  @Deprecated('fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  GetStudentProfileVariables.fromJson(Map<String, dynamic> json):
  
  uid = nativeFromJson<String>(json['uid']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final GetStudentProfileVariables otherTyped = other as GetStudentProfileVariables;
    return uid == otherTyped.uid;
    
  }
  @override
  int get hashCode => uid.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['uid'] = nativeToJson<String>(uid);
    return json;
  }

  GetStudentProfileVariables({
    required this.uid,
  });
}

