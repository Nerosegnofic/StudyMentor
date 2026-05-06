part of 'generated.dart';

class UpdateStudentXpAndCoinsVariablesBuilder {
  int totalXp;
  int weeklyXp;
  int totalCoins;
  int totalQuestionsAnswered;
  int currentStreak;

  final FirebaseDataConnect _dataConnect;
  UpdateStudentXpAndCoinsVariablesBuilder(this._dataConnect, {required  this.totalXp,required  this.weeklyXp,required  this.totalCoins,required  this.totalQuestionsAnswered,required  this.currentStreak,});
  Deserializer<UpdateStudentXpAndCoinsData> dataDeserializer = (dynamic json)  => UpdateStudentXpAndCoinsData.fromJson(jsonDecode(json));
  Serializer<UpdateStudentXpAndCoinsVariables> varsSerializer = (UpdateStudentXpAndCoinsVariables vars) => jsonEncode(vars.toJson());
  Future<OperationResult<UpdateStudentXpAndCoinsData, UpdateStudentXpAndCoinsVariables>> execute() {
    return ref().execute();
  }

  MutationRef<UpdateStudentXpAndCoinsData, UpdateStudentXpAndCoinsVariables> ref() {
    UpdateStudentXpAndCoinsVariables vars= UpdateStudentXpAndCoinsVariables(totalXp: totalXp,weeklyXp: weeklyXp,totalCoins: totalCoins,totalQuestionsAnswered: totalQuestionsAnswered,currentStreak: currentStreak,);
    return _dataConnect.mutation("UpdateStudentXpAndCoins", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class UpdateStudentXpAndCoinsStudentUpdate {
  final String uid;
  UpdateStudentXpAndCoinsStudentUpdate.fromJson(dynamic json):
  
  uid = nativeFromJson<String>(json['uid']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final UpdateStudentXpAndCoinsStudentUpdate otherTyped = other as UpdateStudentXpAndCoinsStudentUpdate;
    return uid == otherTyped.uid;
    
  }
  @override
  int get hashCode => uid.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['uid'] = nativeToJson<String>(uid);
    return json;
  }

  UpdateStudentXpAndCoinsStudentUpdate({
    required this.uid,
  });
}

@immutable
class UpdateStudentXpAndCoinsData {
  final UpdateStudentXpAndCoinsStudentUpdate? student_update;
  UpdateStudentXpAndCoinsData.fromJson(dynamic json):
  
  student_update = json['student_update'] == null ? null : UpdateStudentXpAndCoinsStudentUpdate.fromJson(json['student_update']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final UpdateStudentXpAndCoinsData otherTyped = other as UpdateStudentXpAndCoinsData;
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

  UpdateStudentXpAndCoinsData({
    this.student_update,
  });
}

@immutable
class UpdateStudentXpAndCoinsVariables {
  final int totalXp;
  final int weeklyXp;
  final int totalCoins;
  final int totalQuestionsAnswered;
  final int currentStreak;
  @Deprecated('fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  UpdateStudentXpAndCoinsVariables.fromJson(Map<String, dynamic> json):
  
  totalXp = nativeFromJson<int>(json['totalXp']),
  weeklyXp = nativeFromJson<int>(json['weeklyXp']),
  totalCoins = nativeFromJson<int>(json['totalCoins']),
  totalQuestionsAnswered = nativeFromJson<int>(json['totalQuestionsAnswered']),
  currentStreak = nativeFromJson<int>(json['currentStreak']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final UpdateStudentXpAndCoinsVariables otherTyped = other as UpdateStudentXpAndCoinsVariables;
    return totalXp == otherTyped.totalXp && 
    weeklyXp == otherTyped.weeklyXp && 
    totalCoins == otherTyped.totalCoins && 
    totalQuestionsAnswered == otherTyped.totalQuestionsAnswered && 
    currentStreak == otherTyped.currentStreak;
    
  }
  @override
  int get hashCode => Object.hashAll([totalXp.hashCode, weeklyXp.hashCode, totalCoins.hashCode, totalQuestionsAnswered.hashCode, currentStreak.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['totalXp'] = nativeToJson<int>(totalXp);
    json['weeklyXp'] = nativeToJson<int>(weeklyXp);
    json['totalCoins'] = nativeToJson<int>(totalCoins);
    json['totalQuestionsAnswered'] = nativeToJson<int>(totalQuestionsAnswered);
    json['currentStreak'] = nativeToJson<int>(currentStreak);
    return json;
  }

  UpdateStudentXpAndCoinsVariables({
    required this.totalXp,
    required this.weeklyXp,
    required this.totalCoins,
    required this.totalQuestionsAnswered,
    required this.currentStreak,
  });
}

