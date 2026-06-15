part of 'generated.dart';

class UpdateStudentLastActiveAtVariablesBuilder {
  
  final FirebaseDataConnect _dataConnect;
  UpdateStudentLastActiveAtVariablesBuilder(this._dataConnect, );
  Deserializer<UpdateStudentLastActiveAtData> dataDeserializer = (dynamic json)  => UpdateStudentLastActiveAtData.fromJson(jsonDecode(json));
  
  Future<OperationResult<UpdateStudentLastActiveAtData, void>> execute() {
    return ref().execute();
  }

  MutationRef<UpdateStudentLastActiveAtData, void> ref() {
    
    return _dataConnect.mutation("UpdateStudentLastActiveAt", dataDeserializer, emptySerializer, null);
  }
}

@immutable
class UpdateStudentLastActiveAtStudentUpdate {
  final String uid;
  UpdateStudentLastActiveAtStudentUpdate.fromJson(dynamic json):
  
  uid = nativeFromJson<String>(json['uid']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final UpdateStudentLastActiveAtStudentUpdate otherTyped = other as UpdateStudentLastActiveAtStudentUpdate;
    return uid == otherTyped.uid;
    
  }
  @override
  int get hashCode => uid.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['uid'] = nativeToJson<String>(uid);
    return json;
  }

  UpdateStudentLastActiveAtStudentUpdate({
    required this.uid,
  });
}

@immutable
class UpdateStudentLastActiveAtData {
  final UpdateStudentLastActiveAtStudentUpdate? student_update;
  UpdateStudentLastActiveAtData.fromJson(dynamic json):
  
  student_update = json['student_update'] == null ? null : UpdateStudentLastActiveAtStudentUpdate.fromJson(json['student_update']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final UpdateStudentLastActiveAtData otherTyped = other as UpdateStudentLastActiveAtData;
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

  UpdateStudentLastActiveAtData({
    this.student_update,
  });
}

