part of 'generated.dart';

class UpdateStudentFullNameVariablesBuilder {
  String uid;
  String fullName;

  final FirebaseDataConnect _dataConnect;
  UpdateStudentFullNameVariablesBuilder(this._dataConnect, {required  this.uid,required  this.fullName,});
  Deserializer<UpdateStudentFullNameData> dataDeserializer = (dynamic json)  => UpdateStudentFullNameData.fromJson(jsonDecode(json));
  Serializer<UpdateStudentFullNameVariables> varsSerializer = (UpdateStudentFullNameVariables vars) => jsonEncode(vars.toJson());
  Future<OperationResult<UpdateStudentFullNameData, UpdateStudentFullNameVariables>> execute() {
    return ref().execute();
  }

  MutationRef<UpdateStudentFullNameData, UpdateStudentFullNameVariables> ref() {
    UpdateStudentFullNameVariables vars= UpdateStudentFullNameVariables(uid: uid,fullName: fullName,);
    return _dataConnect.mutation("UpdateStudentFullName", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class UpdateStudentFullNameUserUpdate {
  final String uid;
  UpdateStudentFullNameUserUpdate.fromJson(dynamic json):
  
  uid = nativeFromJson<String>(json['uid']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final UpdateStudentFullNameUserUpdate otherTyped = other as UpdateStudentFullNameUserUpdate;
    return uid == otherTyped.uid;
    
  }
  @override
  int get hashCode => uid.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['uid'] = nativeToJson<String>(uid);
    return json;
  }

  UpdateStudentFullNameUserUpdate({
    required this.uid,
  });
}

@immutable
class UpdateStudentFullNameData {
  final UpdateStudentFullNameUserUpdate? user_update;
  UpdateStudentFullNameData.fromJson(dynamic json):
  
  user_update = json['user_update'] == null ? null : UpdateStudentFullNameUserUpdate.fromJson(json['user_update']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final UpdateStudentFullNameData otherTyped = other as UpdateStudentFullNameData;
    return user_update == otherTyped.user_update;
    
  }
  @override
  int get hashCode => user_update.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    if (user_update != null) {
      json['user_update'] = user_update!.toJson();
    }
    return json;
  }

  UpdateStudentFullNameData({
    this.user_update,
  });
}

@immutable
class UpdateStudentFullNameVariables {
  final String uid;
  final String fullName;
  @Deprecated('fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  UpdateStudentFullNameVariables.fromJson(Map<String, dynamic> json):
  
  uid = nativeFromJson<String>(json['uid']),
  fullName = nativeFromJson<String>(json['fullName']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final UpdateStudentFullNameVariables otherTyped = other as UpdateStudentFullNameVariables;
    return uid == otherTyped.uid && 
    fullName == otherTyped.fullName;
    
  }
  @override
  int get hashCode => Object.hashAll([uid.hashCode, fullName.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['uid'] = nativeToJson<String>(uid);
    json['fullName'] = nativeToJson<String>(fullName);
    return json;
  }

  UpdateStudentFullNameVariables({
    required this.uid,
    required this.fullName,
  });
}

