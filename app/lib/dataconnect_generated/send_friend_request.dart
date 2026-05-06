part of 'generated.dart';

class SendFriendRequestVariablesBuilder {
  String fromStudentUid;
  String toFriendCode;
  String toStudentUid;
  String toStudentName;

  final FirebaseDataConnect _dataConnect;
  SendFriendRequestVariablesBuilder(this._dataConnect, {required  this.fromStudentUid,required  this.toFriendCode,required  this.toStudentUid,required  this.toStudentName,});
  Deserializer<SendFriendRequestData> dataDeserializer = (dynamic json)  => SendFriendRequestData.fromJson(jsonDecode(json));
  Serializer<SendFriendRequestVariables> varsSerializer = (SendFriendRequestVariables vars) => jsonEncode(vars.toJson());
  Future<OperationResult<SendFriendRequestData, SendFriendRequestVariables>> execute() {
    return ref().execute();
  }

  MutationRef<SendFriendRequestData, SendFriendRequestVariables> ref() {
    SendFriendRequestVariables vars= SendFriendRequestVariables(fromStudentUid: fromStudentUid,toFriendCode: toFriendCode,toStudentUid: toStudentUid,toStudentName: toStudentName,);
    return _dataConnect.mutation("SendFriendRequest", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class SendFriendRequestFriendRequestInsert {
  final String id;
  SendFriendRequestFriendRequestInsert.fromJson(dynamic json):
  
  id = nativeFromJson<String>(json['id']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final SendFriendRequestFriendRequestInsert otherTyped = other as SendFriendRequestFriendRequestInsert;
    return id == otherTyped.id;
    
  }
  @override
  int get hashCode => id.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    return json;
  }

  SendFriendRequestFriendRequestInsert({
    required this.id,
  });
}

@immutable
class SendFriendRequestData {
  final SendFriendRequestFriendRequestInsert friendRequest_insert;
  SendFriendRequestData.fromJson(dynamic json):
  
  friendRequest_insert = SendFriendRequestFriendRequestInsert.fromJson(json['friendRequest_insert']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final SendFriendRequestData otherTyped = other as SendFriendRequestData;
    return friendRequest_insert == otherTyped.friendRequest_insert;
    
  }
  @override
  int get hashCode => friendRequest_insert.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['friendRequest_insert'] = friendRequest_insert.toJson();
    return json;
  }

  SendFriendRequestData({
    required this.friendRequest_insert,
  });
}

@immutable
class SendFriendRequestVariables {
  final String fromStudentUid;
  final String toFriendCode;
  final String toStudentUid;
  final String toStudentName;
  @Deprecated('fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  SendFriendRequestVariables.fromJson(Map<String, dynamic> json):
  
  fromStudentUid = nativeFromJson<String>(json['fromStudentUid']),
  toFriendCode = nativeFromJson<String>(json['toFriendCode']),
  toStudentUid = nativeFromJson<String>(json['toStudentUid']),
  toStudentName = nativeFromJson<String>(json['toStudentName']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final SendFriendRequestVariables otherTyped = other as SendFriendRequestVariables;
    return fromStudentUid == otherTyped.fromStudentUid && 
    toFriendCode == otherTyped.toFriendCode && 
    toStudentUid == otherTyped.toStudentUid && 
    toStudentName == otherTyped.toStudentName;
    
  }
  @override
  int get hashCode => Object.hashAll([fromStudentUid.hashCode, toFriendCode.hashCode, toStudentUid.hashCode, toStudentName.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['fromStudentUid'] = nativeToJson<String>(fromStudentUid);
    json['toFriendCode'] = nativeToJson<String>(toFriendCode);
    json['toStudentUid'] = nativeToJson<String>(toStudentUid);
    json['toStudentName'] = nativeToJson<String>(toStudentName);
    return json;
  }

  SendFriendRequestVariables({
    required this.fromStudentUid,
    required this.toFriendCode,
    required this.toStudentUid,
    required this.toStudentName,
  });
}

