part of 'generated.dart';

class GetSentFriendRequestsVariablesBuilder {
  String fromStudentUid;

  final FirebaseDataConnect _dataConnect;
  GetSentFriendRequestsVariablesBuilder(this._dataConnect, {required  this.fromStudentUid,});
  Deserializer<GetSentFriendRequestsData> dataDeserializer = (dynamic json)  => GetSentFriendRequestsData.fromJson(jsonDecode(json));
  Serializer<GetSentFriendRequestsVariables> varsSerializer = (GetSentFriendRequestsVariables vars) => jsonEncode(vars.toJson());
  Future<QueryResult<GetSentFriendRequestsData, GetSentFriendRequestsVariables>> execute() {
    return ref().execute();
  }

  QueryRef<GetSentFriendRequestsData, GetSentFriendRequestsVariables> ref() {
    GetSentFriendRequestsVariables vars= GetSentFriendRequestsVariables(fromStudentUid: fromStudentUid,);
    return _dataConnect.query("GetSentFriendRequests", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class GetSentFriendRequestsFriendRequests {
  final String id;
  final String toFriendCode;
  final String toStudentName;
  final String status;
  final Timestamp createdAt;
  GetSentFriendRequestsFriendRequests.fromJson(dynamic json):
  
  id = nativeFromJson<String>(json['id']),
  toFriendCode = nativeFromJson<String>(json['toFriendCode']),
  toStudentName = nativeFromJson<String>(json['toStudentName']),
  status = nativeFromJson<String>(json['status']),
  createdAt = Timestamp.fromJson(json['createdAt']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final GetSentFriendRequestsFriendRequests otherTyped = other as GetSentFriendRequestsFriendRequests;
    return id == otherTyped.id && 
    toFriendCode == otherTyped.toFriendCode && 
    toStudentName == otherTyped.toStudentName && 
    status == otherTyped.status && 
    createdAt == otherTyped.createdAt;
    
  }
  @override
  int get hashCode => Object.hashAll([id.hashCode, toFriendCode.hashCode, toStudentName.hashCode, status.hashCode, createdAt.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    json['toFriendCode'] = nativeToJson<String>(toFriendCode);
    json['toStudentName'] = nativeToJson<String>(toStudentName);
    json['status'] = nativeToJson<String>(status);
    json['createdAt'] = createdAt.toJson();
    return json;
  }

  GetSentFriendRequestsFriendRequests({
    required this.id,
    required this.toFriendCode,
    required this.toStudentName,
    required this.status,
    required this.createdAt,
  });
}

@immutable
class GetSentFriendRequestsData {
  final List<GetSentFriendRequestsFriendRequests> friendRequests;
  GetSentFriendRequestsData.fromJson(dynamic json):
  
  friendRequests = (json['friendRequests'] as List<dynamic>)
        .map((e) => GetSentFriendRequestsFriendRequests.fromJson(e))
        .toList();
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final GetSentFriendRequestsData otherTyped = other as GetSentFriendRequestsData;
    return friendRequests == otherTyped.friendRequests;
    
  }
  @override
  int get hashCode => friendRequests.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['friendRequests'] = friendRequests.map((e) => e.toJson()).toList();
    return json;
  }

  GetSentFriendRequestsData({
    required this.friendRequests,
  });
}

@immutable
class GetSentFriendRequestsVariables {
  final String fromStudentUid;
  @Deprecated('fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  GetSentFriendRequestsVariables.fromJson(Map<String, dynamic> json):
  
  fromStudentUid = nativeFromJson<String>(json['fromStudentUid']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final GetSentFriendRequestsVariables otherTyped = other as GetSentFriendRequestsVariables;
    return fromStudentUid == otherTyped.fromStudentUid;
    
  }
  @override
  int get hashCode => fromStudentUid.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['fromStudentUid'] = nativeToJson<String>(fromStudentUid);
    return json;
  }

  GetSentFriendRequestsVariables({
    required this.fromStudentUid,
  });
}

