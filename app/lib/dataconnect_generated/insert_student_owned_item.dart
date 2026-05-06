part of 'generated.dart';

class InsertStudentOwnedItemVariablesBuilder {
  String studentUid;
  String itemId;

  final FirebaseDataConnect _dataConnect;
  InsertStudentOwnedItemVariablesBuilder(this._dataConnect, {required  this.studentUid,required  this.itemId,});
  Deserializer<InsertStudentOwnedItemData> dataDeserializer = (dynamic json)  => InsertStudentOwnedItemData.fromJson(jsonDecode(json));
  Serializer<InsertStudentOwnedItemVariables> varsSerializer = (InsertStudentOwnedItemVariables vars) => jsonEncode(vars.toJson());
  Future<OperationResult<InsertStudentOwnedItemData, InsertStudentOwnedItemVariables>> execute() {
    return ref().execute();
  }

  MutationRef<InsertStudentOwnedItemData, InsertStudentOwnedItemVariables> ref() {
    InsertStudentOwnedItemVariables vars= InsertStudentOwnedItemVariables(studentUid: studentUid,itemId: itemId,);
    return _dataConnect.mutation("InsertStudentOwnedItem", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class InsertStudentOwnedItemStudentOwnedItemInsert {
  final String id;
  InsertStudentOwnedItemStudentOwnedItemInsert.fromJson(dynamic json):
  
  id = nativeFromJson<String>(json['id']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final InsertStudentOwnedItemStudentOwnedItemInsert otherTyped = other as InsertStudentOwnedItemStudentOwnedItemInsert;
    return id == otherTyped.id;
    
  }
  @override
  int get hashCode => id.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    return json;
  }

  InsertStudentOwnedItemStudentOwnedItemInsert({
    required this.id,
  });
}

@immutable
class InsertStudentOwnedItemData {
  final InsertStudentOwnedItemStudentOwnedItemInsert studentOwnedItem_insert;
  InsertStudentOwnedItemData.fromJson(dynamic json):
  
  studentOwnedItem_insert = InsertStudentOwnedItemStudentOwnedItemInsert.fromJson(json['studentOwnedItem_insert']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final InsertStudentOwnedItemData otherTyped = other as InsertStudentOwnedItemData;
    return studentOwnedItem_insert == otherTyped.studentOwnedItem_insert;
    
  }
  @override
  int get hashCode => studentOwnedItem_insert.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['studentOwnedItem_insert'] = studentOwnedItem_insert.toJson();
    return json;
  }

  InsertStudentOwnedItemData({
    required this.studentOwnedItem_insert,
  });
}

@immutable
class InsertStudentOwnedItemVariables {
  final String studentUid;
  final String itemId;
  @Deprecated('fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  InsertStudentOwnedItemVariables.fromJson(Map<String, dynamic> json):
  
  studentUid = nativeFromJson<String>(json['studentUid']),
  itemId = nativeFromJson<String>(json['itemId']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final InsertStudentOwnedItemVariables otherTyped = other as InsertStudentOwnedItemVariables;
    return studentUid == otherTyped.studentUid && 
    itemId == otherTyped.itemId;
    
  }
  @override
  int get hashCode => Object.hashAll([studentUid.hashCode, itemId.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['studentUid'] = nativeToJson<String>(studentUid);
    json['itemId'] = nativeToJson<String>(itemId);
    return json;
  }

  InsertStudentOwnedItemVariables({
    required this.studentUid,
    required this.itemId,
  });
}

