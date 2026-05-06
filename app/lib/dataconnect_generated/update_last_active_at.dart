part of 'generated.dart';

class UpdateLastActiveAtVariablesBuilder {
  
  final FirebaseDataConnect _dataConnect;
  UpdateLastActiveAtVariablesBuilder(this._dataConnect, );
  Deserializer<UpdateLastActiveAtData> dataDeserializer = (dynamic json)  => UpdateLastActiveAtData.fromJson(jsonDecode(json));
  
  Future<OperationResult<UpdateLastActiveAtData, void>> execute() {
    return ref().execute();
  }

  MutationRef<UpdateLastActiveAtData, void> ref() {
    
    return _dataConnect.mutation("UpdateLastActiveAt", dataDeserializer, emptySerializer, null);
  }
}

@immutable
class UpdateLastActiveAtStudentUpdate {
  final String uid;
  UpdateLastActiveAtStudentUpdate.fromJson(dynamic json):
  
  uid = nativeFromJson<String>(json['uid']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final UpdateLastActiveAtStudentUpdate otherTyped = other as UpdateLastActiveAtStudentUpdate;
    return uid == otherTyped.uid;
    
  }
  @override
  int get hashCode => uid.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['uid'] = nativeToJson<String>(uid);
    return json;
  }

  UpdateLastActiveAtStudentUpdate({
    required this.uid,
  });
}

@immutable
class UpdateLastActiveAtData {
  final UpdateLastActiveAtStudentUpdate? student_update;
  UpdateLastActiveAtData.fromJson(dynamic json):
  
  student_update = json['student_update'] == null ? null : UpdateLastActiveAtStudentUpdate.fromJson(json['student_update']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final UpdateLastActiveAtData otherTyped = other as UpdateLastActiveAtData;
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

  UpdateLastActiveAtData({
    this.student_update,
  });
}

