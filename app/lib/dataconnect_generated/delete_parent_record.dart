part of 'generated.dart';

class DeleteParentRecordVariablesBuilder {
  
  final FirebaseDataConnect _dataConnect;
  DeleteParentRecordVariablesBuilder(this._dataConnect, );
  Deserializer<DeleteParentRecordData> dataDeserializer = (dynamic json)  => DeleteParentRecordData.fromJson(jsonDecode(json));
  
  Future<OperationResult<DeleteParentRecordData, void>> execute() {
    return ref().execute();
  }

  MutationRef<DeleteParentRecordData, void> ref() {
    
    return _dataConnect.mutation("DeleteParentRecord", dataDeserializer, emptySerializer, null);
  }
}

@immutable
class DeleteParentRecordParentDelete {
  final String uid;
  DeleteParentRecordParentDelete.fromJson(dynamic json):
  
  uid = nativeFromJson<String>(json['uid']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final DeleteParentRecordParentDelete otherTyped = other as DeleteParentRecordParentDelete;
    return uid == otherTyped.uid;
    
  }
  @override
  int get hashCode => uid.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['uid'] = nativeToJson<String>(uid);
    return json;
  }

  DeleteParentRecordParentDelete({
    required this.uid,
  });
}

@immutable
class DeleteParentRecordData {
  final DeleteParentRecordParentDelete? parent_delete;
  DeleteParentRecordData.fromJson(dynamic json):
  
  parent_delete = json['parent_delete'] == null ? null : DeleteParentRecordParentDelete.fromJson(json['parent_delete']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final DeleteParentRecordData otherTyped = other as DeleteParentRecordData;
    return parent_delete == otherTyped.parent_delete;
    
  }
  @override
  int get hashCode => parent_delete.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    if (parent_delete != null) {
      json['parent_delete'] = parent_delete!.toJson();
    }
    return json;
  }

  DeleteParentRecordData({
    this.parent_delete,
  });
}

