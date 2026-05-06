part of 'generated.dart';

class GetStudentOwnedItemsVariablesBuilder {
  String studentUid;

  final FirebaseDataConnect _dataConnect;
  GetStudentOwnedItemsVariablesBuilder(this._dataConnect, {required  this.studentUid,});
  Deserializer<GetStudentOwnedItemsData> dataDeserializer = (dynamic json)  => GetStudentOwnedItemsData.fromJson(jsonDecode(json));
  Serializer<GetStudentOwnedItemsVariables> varsSerializer = (GetStudentOwnedItemsVariables vars) => jsonEncode(vars.toJson());
  Future<QueryResult<GetStudentOwnedItemsData, GetStudentOwnedItemsVariables>> execute() {
    return ref().execute();
  }

  QueryRef<GetStudentOwnedItemsData, GetStudentOwnedItemsVariables> ref() {
    GetStudentOwnedItemsVariables vars= GetStudentOwnedItemsVariables(studentUid: studentUid,);
    return _dataConnect.query("GetStudentOwnedItems", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class GetStudentOwnedItemsStudentOwnedItems {
  final String itemId;
  GetStudentOwnedItemsStudentOwnedItems.fromJson(dynamic json):
  
  itemId = nativeFromJson<String>(json['itemId']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final GetStudentOwnedItemsStudentOwnedItems otherTyped = other as GetStudentOwnedItemsStudentOwnedItems;
    return itemId == otherTyped.itemId;
    
  }
  @override
  int get hashCode => itemId.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['itemId'] = nativeToJson<String>(itemId);
    return json;
  }

  GetStudentOwnedItemsStudentOwnedItems({
    required this.itemId,
  });
}

@immutable
class GetStudentOwnedItemsData {
  final List<GetStudentOwnedItemsStudentOwnedItems> studentOwnedItems;
  GetStudentOwnedItemsData.fromJson(dynamic json):
  
  studentOwnedItems = (json['studentOwnedItems'] as List<dynamic>)
        .map((e) => GetStudentOwnedItemsStudentOwnedItems.fromJson(e))
        .toList();
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final GetStudentOwnedItemsData otherTyped = other as GetStudentOwnedItemsData;
    return studentOwnedItems == otherTyped.studentOwnedItems;
    
  }
  @override
  int get hashCode => studentOwnedItems.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['studentOwnedItems'] = studentOwnedItems.map((e) => e.toJson()).toList();
    return json;
  }

  GetStudentOwnedItemsData({
    required this.studentOwnedItems,
  });
}

@immutable
class GetStudentOwnedItemsVariables {
  final String studentUid;
  @Deprecated('fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  GetStudentOwnedItemsVariables.fromJson(Map<String, dynamic> json):
  
  studentUid = nativeFromJson<String>(json['studentUid']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final GetStudentOwnedItemsVariables otherTyped = other as GetStudentOwnedItemsVariables;
    return studentUid == otherTyped.studentUid;
    
  }
  @override
  int get hashCode => studentUid.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['studentUid'] = nativeToJson<String>(studentUid);
    return json;
  }

  GetStudentOwnedItemsVariables({
    required this.studentUid,
  });
}

