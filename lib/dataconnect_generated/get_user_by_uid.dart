part of 'generated.dart';

class GetUserByUidVariablesBuilder {
  String uid;

  final FirebaseDataConnect _dataConnect;
  GetUserByUidVariablesBuilder(this._dataConnect, {required  this.uid,});
  Deserializer<GetUserByUidData> dataDeserializer = (dynamic json)  => GetUserByUidData.fromJson(jsonDecode(json));
  Serializer<GetUserByUidVariables> varsSerializer = (GetUserByUidVariables vars) => jsonEncode(vars.toJson());
  Future<QueryResult<GetUserByUidData, GetUserByUidVariables>> execute() {
    return ref().execute();
  }

  QueryRef<GetUserByUidData, GetUserByUidVariables> ref() {
    GetUserByUidVariables vars= GetUserByUidVariables(uid: uid,);
    return _dataConnect.query("GetUserByUid", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class GetUserByUidUser {
  final String uid;
  final String email;
  final String? fullName;
  final EnumValue<Role> role;
  final bool isActive;
  final Timestamp? createdAt;
  GetUserByUidUser.fromJson(dynamic json):
  
  uid = nativeFromJson<String>(json['uid']),
  email = nativeFromJson<String>(json['email']),
  fullName = json['fullName'] == null ? null : nativeFromJson<String>(json['fullName']),
  role = roleDeserializer(json['role']),
  isActive = nativeFromJson<bool>(json['isActive']),
  createdAt = json['createdAt'] == null ? null : Timestamp.fromJson(json['createdAt']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final GetUserByUidUser otherTyped = other as GetUserByUidUser;
    return uid == otherTyped.uid && 
    email == otherTyped.email && 
    fullName == otherTyped.fullName && 
    role == otherTyped.role && 
    isActive == otherTyped.isActive && 
    createdAt == otherTyped.createdAt;
    
  }
  @override
  int get hashCode => Object.hashAll([uid.hashCode, email.hashCode, fullName.hashCode, role.hashCode, isActive.hashCode, createdAt.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['uid'] = nativeToJson<String>(uid);
    json['email'] = nativeToJson<String>(email);
    if (fullName != null) {
      json['fullName'] = nativeToJson<String?>(fullName);
    }
    json['role'] = 
    roleSerializer(role)
    ;
    json['isActive'] = nativeToJson<bool>(isActive);
    if (createdAt != null) {
      json['createdAt'] = createdAt!.toJson();
    }
    return json;
  }

  GetUserByUidUser({
    required this.uid,
    required this.email,
    this.fullName,
    required this.role,
    required this.isActive,
    this.createdAt,
  });
}

@immutable
class GetUserByUidData {
  final GetUserByUidUser? user;
  GetUserByUidData.fromJson(dynamic json):
  
  user = json['user'] == null ? null : GetUserByUidUser.fromJson(json['user']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final GetUserByUidData otherTyped = other as GetUserByUidData;
    return user == otherTyped.user;
    
  }
  @override
  int get hashCode => user.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    if (user != null) {
      json['user'] = user!.toJson();
    }
    return json;
  }

  GetUserByUidData({
    this.user,
  });
}

@immutable
class GetUserByUidVariables {
  final String uid;
  @Deprecated('fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  GetUserByUidVariables.fromJson(Map<String, dynamic> json):
  
  uid = nativeFromJson<String>(json['uid']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final GetUserByUidVariables otherTyped = other as GetUserByUidVariables;
    return uid == otherTyped.uid;
    
  }
  @override
  int get hashCode => uid.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['uid'] = nativeToJson<String>(uid);
    return json;
  }

  GetUserByUidVariables({
    required this.uid,
  });
}

