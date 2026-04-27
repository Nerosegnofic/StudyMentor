part of 'generated.dart';

class InsertParentVariablesBuilder {
  Optional<String> _pinCode = Optional.optional(nativeFromJson, nativeToJson);
  Optional<String> _phoneNumber = Optional.optional(nativeFromJson, nativeToJson);

  final FirebaseDataConnect _dataConnect;
  InsertParentVariablesBuilder pinCode(String? t) {
   _pinCode.value = t;
   return this;
  }
  InsertParentVariablesBuilder phoneNumber(String? t) {
   _phoneNumber.value = t;
   return this;
  }

  InsertParentVariablesBuilder(this._dataConnect, );
  Deserializer<InsertParentData> dataDeserializer = (dynamic json)  => InsertParentData.fromJson(jsonDecode(json));
  Serializer<InsertParentVariables> varsSerializer = (InsertParentVariables vars) => jsonEncode(vars.toJson());
  Future<OperationResult<InsertParentData, InsertParentVariables>> execute() {
    return ref().execute();
  }

  MutationRef<InsertParentData, InsertParentVariables> ref() {
    InsertParentVariables vars= InsertParentVariables(pinCode: _pinCode,phoneNumber: _phoneNumber,);
    return _dataConnect.mutation("InsertParent", dataDeserializer, varsSerializer, vars);
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

@immutable
class InsertParentVariables {
  late final Optional<String>pinCode;
  late final Optional<String>phoneNumber;
  @Deprecated('fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  InsertParentVariables.fromJson(Map<String, dynamic> json) {
  
  
    pinCode = Optional.optional(nativeFromJson, nativeToJson);
    pinCode.value = json['pinCode'] == null ? null : nativeFromJson<String>(json['pinCode']);
  
  
    phoneNumber = Optional.optional(nativeFromJson, nativeToJson);
    phoneNumber.value = json['phoneNumber'] == null ? null : nativeFromJson<String>(json['phoneNumber']);
  
  }
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final InsertParentVariables otherTyped = other as InsertParentVariables;
    return pinCode == otherTyped.pinCode && 
    phoneNumber == otherTyped.phoneNumber;
    
  }
  @override
  int get hashCode => Object.hashAll([pinCode.hashCode, phoneNumber.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    if(pinCode.state == OptionalState.set) {
      json['pinCode'] = pinCode.toJson();
    }
    if(phoneNumber.state == OptionalState.set) {
      json['phoneNumber'] = phoneNumber.toJson();
    }
    return json;
  }

  InsertParentVariables({
    required this.pinCode,
    required this.phoneNumber,
  });
}

