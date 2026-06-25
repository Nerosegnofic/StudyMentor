part of 'generated.dart';

class InsertParentVariablesBuilder {
  
  final FirebaseDataConnect _dataConnect;
  InsertParentVariablesBuilder(this._dataConnect, );
  Deserializer<InsertParentData> dataDeserializer = (dynamic json)  => InsertParentData.fromJson(jsonDecode(json));
  
  Future<OperationResult<InsertParentData, void>> execute() {
    return ref().execute();
  }

  MutationRef<InsertParentData, void> ref() {
    
    return _dataConnect.mutation("InsertParent", dataDeserializer, emptySerializer, null);
  }
}

@immutable
class InsertParentParentInsert {
  final String uid;
  InsertParentParentInsert.fromJson(dynamic json):
  
  uid = nativeFromJson<String>(json['uid']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final InsertParentParentInsert otherTyped = other as InsertParentParentInsert;
    return uid == otherTyped.uid;
    
  }
  @override
  int get hashCode => uid.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['uid'] = nativeToJson<String>(uid);
    return json;
  }

  InsertParentParentInsert({
    required this.uid,
  });
}

@immutable
class InsertParentData {
  final InsertParentParentInsert parent_insert;
  InsertParentData.fromJson(dynamic json):
  
  parent_insert = InsertParentParentInsert.fromJson(json['parent_insert']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final InsertParentData otherTyped = other as InsertParentData;
    return parent_insert == otherTyped.parent_insert;
    
  }
  @override
  int get hashCode => parent_insert.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['parent_insert'] = parent_insert.toJson();
    return json;
  }

  InsertParentData({
    required this.parent_insert,
  });
}

