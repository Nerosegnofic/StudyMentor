part of 'generated.dart';

class UpsertCurrentUserVariablesBuilder {
  String email;
  Optional<String> _fullName = Optional.optional(nativeFromJson, nativeToJson);
  Role role;

  final FirebaseDataConnect _dataConnect;  UpsertCurrentUserVariablesBuilder fullName(String? t) {
   _fullName.value = t;
   return this;
  }

  UpsertCurrentUserVariablesBuilder(this._dataConnect, {required  this.email,required  this.role,});
  Deserializer<UpsertCurrentUserData> dataDeserializer = (dynamic json)  => UpsertCurrentUserData.fromJson(jsonDecode(json));
  Serializer<UpsertCurrentUserVariables> varsSerializer = (UpsertCurrentUserVariables vars) => jsonEncode(vars.toJson());
  Future<OperationResult<UpsertCurrentUserData, UpsertCurrentUserVariables>> execute() {
    return ref().execute();
  }

  MutationRef<UpsertCurrentUserData, UpsertCurrentUserVariables> ref() {
    UpsertCurrentUserVariables vars= UpsertCurrentUserVariables(email: email,fullName: _fullName,role: role,);
    return _dataConnect.mutation("UpsertCurrentUser", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class UpsertCurrentUserUserUpsert {
  final String uid;
  UpsertCurrentUserUserUpsert.fromJson(dynamic json):
  
  uid = nativeFromJson<String>(json['uid']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final UpsertCurrentUserUserUpsert otherTyped = other as UpsertCurrentUserUserUpsert;
    return uid == otherTyped.uid;
    
  }
  @override
  int get hashCode => uid.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['uid'] = nativeToJson<String>(uid);
    return json;
  }

  UpsertCurrentUserUserUpsert({
    required this.uid,
  });
}

@immutable
class UpsertCurrentUserData {
  final UpsertCurrentUserUserUpsert user_upsert;
  UpsertCurrentUserData.fromJson(dynamic json):
  
  user_upsert = UpsertCurrentUserUserUpsert.fromJson(json['user_upsert']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final UpsertCurrentUserData otherTyped = other as UpsertCurrentUserData;
    return user_upsert == otherTyped.user_upsert;
    
  }
  @override
  int get hashCode => user_upsert.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['user_upsert'] = user_upsert.toJson();
    return json;
  }

  UpsertCurrentUserData({
    required this.user_upsert,
  });
}

@immutable
class UpsertCurrentUserVariables {
  final String email;
  late final Optional<String>fullName;
  final Role role;
  @Deprecated('fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  UpsertCurrentUserVariables.fromJson(Map<String, dynamic> json):
  
  email = nativeFromJson<String>(json['email']),
  role = Role.values.byName(json['role']) {
  
  
  
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
    json['email'] = nativeToJson<String>(email);
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

