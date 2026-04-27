part of 'generated.dart';

class InsertUserVariablesBuilder {
  String email;
  String fullName;
  Role role;

  final FirebaseDataConnect _dataConnect;
  InsertUserVariablesBuilder(this._dataConnect, {required  this.email,required  this.fullName,required  this.role,});
  Deserializer<InsertUserData> dataDeserializer = (dynamic json)  => InsertUserData.fromJson(jsonDecode(json));
  Serializer<InsertUserVariables> varsSerializer = (InsertUserVariables vars) => jsonEncode(vars.toJson());
  Future<OperationResult<InsertUserData, InsertUserVariables>> execute() {
    return ref().execute();
  }

  MutationRef<InsertUserData, InsertUserVariables> ref() {
    InsertUserVariables vars= InsertUserVariables(email: email,fullName: fullName,role: role,);
    return _dataConnect.mutation("InsertUser", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class InsertUserUserInsert {
  final String uid;
  InsertUserUserInsert.fromJson(dynamic json):
  
  uid = nativeFromJson<String>(json['uid']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final InsertUserUserInsert otherTyped = other as InsertUserUserInsert;
    return uid == otherTyped.uid;
    
  }
  @override
  int get hashCode => uid.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['uid'] = nativeToJson<String>(uid);
    return json;
  }

  InsertUserUserInsert({
    required this.uid,
  });
}

@immutable
class InsertUserData {
  final InsertUserUserInsert user_insert;
  InsertUserData.fromJson(dynamic json):
  
  user_insert = InsertUserUserInsert.fromJson(json['user_insert']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final InsertUserData otherTyped = other as InsertUserData;
    return user_insert == otherTyped.user_insert;
    
  }
  @override
  int get hashCode => user_insert.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['user_insert'] = user_insert.toJson();
    return json;
  }

  InsertUserData({
    required this.user_insert,
  });
}

@immutable
class InsertUserVariables {
  final String email;
  final String fullName;
  final Role role;
  @Deprecated('fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  InsertUserVariables.fromJson(Map<String, dynamic> json):
  
  email = nativeFromJson<String>(json['email']),
  fullName = nativeFromJson<String>(json['fullName']),
  role = Role.values.byName(json['role']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final InsertUserVariables otherTyped = other as InsertUserVariables;
    return email == otherTyped.email && 
    fullName == otherTyped.fullName && 
    role == otherTyped.role;
    
  }
  @override
  int get hashCode => Object.hashAll([email.hashCode, fullName.hashCode, role.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['email'] = nativeToJson<String>(email);
    json['fullName'] = nativeToJson<String>(fullName);
    json['role'] = 
    role.name
    ;
    return json;
  }

  InsertUserVariables({
    required this.email,
    required this.fullName,
    required this.role,
  });
}

