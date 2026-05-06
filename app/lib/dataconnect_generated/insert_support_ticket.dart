part of 'generated.dart';

class InsertSupportTicketVariablesBuilder {
  String userId;
  String userName;
  String issueType;
  String message;

  final FirebaseDataConnect _dataConnect;
  InsertSupportTicketVariablesBuilder(this._dataConnect, {required  this.userId,required  this.userName,required  this.issueType,required  this.message,});
  Deserializer<InsertSupportTicketData> dataDeserializer = (dynamic json)  => InsertSupportTicketData.fromJson(jsonDecode(json));
  Serializer<InsertSupportTicketVariables> varsSerializer = (InsertSupportTicketVariables vars) => jsonEncode(vars.toJson());
  Future<OperationResult<InsertSupportTicketData, InsertSupportTicketVariables>> execute() {
    return ref().execute();
  }

  MutationRef<InsertSupportTicketData, InsertSupportTicketVariables> ref() {
    InsertSupportTicketVariables vars= InsertSupportTicketVariables(userId: userId,userName: userName,issueType: issueType,message: message,);
    return _dataConnect.mutation("InsertSupportTicket", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class InsertSupportTicketSupportTicketInsert {
  final String id;
  InsertSupportTicketSupportTicketInsert.fromJson(dynamic json):
  
  id = nativeFromJson<String>(json['id']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final InsertSupportTicketSupportTicketInsert otherTyped = other as InsertSupportTicketSupportTicketInsert;
    return id == otherTyped.id;
    
  }
  @override
  int get hashCode => id.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    return json;
  }

  InsertSupportTicketSupportTicketInsert({
    required this.id,
  });
}

@immutable
class InsertSupportTicketData {
  final InsertSupportTicketSupportTicketInsert supportTicket_insert;
  InsertSupportTicketData.fromJson(dynamic json):
  
  supportTicket_insert = InsertSupportTicketSupportTicketInsert.fromJson(json['supportTicket_insert']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final InsertSupportTicketData otherTyped = other as InsertSupportTicketData;
    return supportTicket_insert == otherTyped.supportTicket_insert;
    
  }
  @override
  int get hashCode => supportTicket_insert.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['supportTicket_insert'] = supportTicket_insert.toJson();
    return json;
  }

  InsertSupportTicketData({
    required this.supportTicket_insert,
  });
}

@immutable
class InsertSupportTicketVariables {
  final String userId;
  final String userName;
  final String issueType;
  final String message;
  @Deprecated('fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  InsertSupportTicketVariables.fromJson(Map<String, dynamic> json):
  
  userId = nativeFromJson<String>(json['userId']),
  userName = nativeFromJson<String>(json['userName']),
  issueType = nativeFromJson<String>(json['issueType']),
  message = nativeFromJson<String>(json['message']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final InsertSupportTicketVariables otherTyped = other as InsertSupportTicketVariables;
    return userId == otherTyped.userId && 
    userName == otherTyped.userName && 
    issueType == otherTyped.issueType && 
    message == otherTyped.message;
    
  }
  @override
  int get hashCode => Object.hashAll([userId.hashCode, userName.hashCode, issueType.hashCode, message.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['userId'] = nativeToJson<String>(userId);
    json['userName'] = nativeToJson<String>(userName);
    json['issueType'] = nativeToJson<String>(issueType);
    json['message'] = nativeToJson<String>(message);
    return json;
  }

  InsertSupportTicketVariables({
    required this.userId,
    required this.userName,
    required this.issueType,
    required this.message,
  });
}

