part of 'generated.dart';

class UpsertCurrentUserVariablesBuilder {
  Optional<String> _email = Optional.optional(nativeFromJson, nativeToJson);
  Optional<String> _fullName = Optional.optional(nativeFromJson, nativeToJson);
  Role role;

  final FirebaseDataConnect _dataConnect;
  UpsertCurrentUserVariablesBuilder email(String? t) {
   _email.value = t;
   return this;
  }
  UpsertCurrentUserVariablesBuilder fullName(String? t) {
   _fullName.value = t;
   return this;
  }

  UpsertCurrentUserVariablesBuilder(this._dataConnect, {required  this.role,});
  Deserializer<UpsertCurrentUserData> dataDeserializer = (dynamic json)  => UpsertCurrentUserData.fromJson(jsonDecode(json));
  Serializer<UpsertCurrentUserVariables> varsSerializer = (UpsertCurrentUserVariables vars) => jsonEncode(vars.toJson());
  Future<OperationResult<UpsertCurrentUserData, UpsertCurrentUserVariables>> execute() {
    return ref().execute();
  }

  MutationRef<UpsertCurrentUserData, UpsertCurrentUserVariables> ref() {
    UpsertCurrentUserVariables vars= UpsertCurrentUserVariables(email: _email,fullName: _fullName,role: role,);
    return _dataConnect.mutation("UpsertCurrentUser", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class UpsertCurrentUserUserUpdate {
  final String uid;
  UpsertCurrentUserUserUpdate.fromJson(dynamic json):
  
  uid = nativeFromJson<String>(json['uid']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final UpsertCurrentUserUserUpdate otherTyped = other as UpsertCurrentUserUserUpdate;
    return uid == otherTyped.uid;
    
  }
  @override
  int get hashCode => uid.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['uid'] = nativeToJson<String>(uid);
    return json;
  }

  UpsertCurrentUserUserUpdate({
    required this.uid,
  });
}

@immutable
class UpsertCurrentUserData {
  final UpsertCurrentUserUserUpdate? user_update;
  UpsertCurrentUserData.fromJson(dynamic json):
  
  user_update = json['user_update'] == null ? null : UpsertCurrentUserUserUpdate.fromJson(json['user_update']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final UpsertCurrentUserData otherTyped = other as UpsertCurrentUserData;
    return user_update == otherTyped.user_update;
    
  }
  @override
  int get hashCode => user_update.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    if (user_update != null) {
      json['user_update'] = user_update!.toJson();
    }
    return json;
  }

  UpsertCurrentUserData({
    this.user_update,
  });
}

@immutable
class UpsertCurrentUserVariables {
  late final Optional<String>email;
  late final Optional<String>fullName;
  final Role role;
  @Deprecated('fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  UpsertCurrentUserVariables.fromJson(Map<String, dynamic> json):
  
  role = Role.values.byName(json['role']) {
  
  
    email = Optional.optional(nativeFromJson, nativeToJson);
    email.value = json['email'] == null ? null : nativeFromJson<String>(json['email']);
  
  
    fullName = Optional.optional(nativeFromJson, nativeToJson);
    fullName.value = json['fullName'] == null ? null : nativeFromJson<String>(json['fullName']);
  
  
  }
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final UpsertCurrentUserVariables otherTyped = other as UpsertCurrentUserVariables;
    return email == otherTyped.email && 
    fullName == otherTyped.fullName && 
    role == otherTyped.role;
    
  }
  @override
  int get hashCode => Object.hashAll([email.hashCode, fullName.hashCode, role.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    if(email.state == OptionalState.set) {
      json['email'] = email.toJson();
    }
    if(fullName.state == OptionalState.set) {
      json['fullName'] = fullName.toJson();
    }
    json['role'] = 
    role.name
    ;
    return json;
  }

  UpsertCurrentUserVariables({
    required this.email,
    required this.fullName,
    required this.role,
  });
}

