part of 'generated.dart';

class UpdateStudentCoinsVariablesBuilder {
  int totalCoins;

  final FirebaseDataConnect _dataConnect;
  UpdateStudentCoinsVariablesBuilder(this._dataConnect, {required  this.totalCoins,});
  Deserializer<UpdateStudentCoinsData> dataDeserializer = (dynamic json)  => UpdateStudentCoinsData.fromJson(jsonDecode(json));
  Serializer<UpdateStudentCoinsVariables> varsSerializer = (UpdateStudentCoinsVariables vars) => jsonEncode(vars.toJson());
  Future<OperationResult<UpdateStudentCoinsData, UpdateStudentCoinsVariables>> execute() {
    return ref().execute();
  }

  MutationRef<UpdateStudentCoinsData, UpdateStudentCoinsVariables> ref() {
    UpdateStudentCoinsVariables vars= UpdateStudentCoinsVariables(totalCoins: totalCoins,);
    return _dataConnect.mutation("UpdateStudentCoins", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class UpdateStudentCoinsStudentUpdate {
  final String uid;
  UpdateStudentCoinsStudentUpdate.fromJson(dynamic json):
  
  uid = nativeFromJson<String>(json['uid']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final UpdateStudentCoinsStudentUpdate otherTyped = other as UpdateStudentCoinsStudentUpdate;
    return uid == otherTyped.uid;
    
  }
  @override
  int get hashCode => uid.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['uid'] = nativeToJson<String>(uid);
    return json;
  }

  UpdateStudentCoinsStudentUpdate({
    required this.uid,
  });
}

@immutable
class UpdateStudentCoinsData {
  final UpdateStudentCoinsStudentUpdate? student_update;
  UpdateStudentCoinsData.fromJson(dynamic json):
  
  student_update = json['student_update'] == null ? null : UpdateStudentCoinsStudentUpdate.fromJson(json['student_update']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final UpdateStudentCoinsData otherTyped = other as UpdateStudentCoinsData;
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

  UpdateStudentCoinsData({
    this.student_update,
  });
}

@immutable
class UpdateStudentCoinsVariables {
  final int totalCoins;
  @Deprecated('fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  UpdateStudentCoinsVariables.fromJson(Map<String, dynamic> json):
  
  totalCoins = nativeFromJson<int>(json['totalCoins']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final UpdateStudentCoinsVariables otherTyped = other as UpdateStudentCoinsVariables;
    return totalCoins == otherTyped.totalCoins;
    
  }
  @override
  int get hashCode => totalCoins.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['totalCoins'] = nativeToJson<int>(totalCoins);
    return json;
  }

  UpdateStudentCoinsVariables({
    required this.totalCoins,
  });
}

