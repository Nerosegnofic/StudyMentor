part of 'generated.dart';

class UpsertStudentAvatarVariablesBuilder {
  String studentUid;
  String gender;
  String skinTone;
  Optional<String> _equippedHair = Optional.optional(nativeFromJson, nativeToJson);
  Optional<String> _equippedOutfit = Optional.optional(nativeFromJson, nativeToJson);
  Optional<String> _equippedBottom = Optional.optional(nativeFromJson, nativeToJson);
  Optional<String> _equippedShoes = Optional.optional(nativeFromJson, nativeToJson);
  Optional<String> _equippedAccessory = Optional.optional(nativeFromJson, nativeToJson);
  Optional<String> _equippedBackground = Optional.optional(nativeFromJson, nativeToJson);
  Optional<String> _equippedSpecial = Optional.optional(nativeFromJson, nativeToJson);
  Optional<String> _avatarConfig = Optional.optional(nativeFromJson, nativeToJson);

  final FirebaseDataConnect _dataConnect;  UpsertStudentAvatarVariablesBuilder equippedHair(String? t) {
   _equippedHair.value = t;
   return this;
  }
  UpsertStudentAvatarVariablesBuilder equippedOutfit(String? t) {
   _equippedOutfit.value = t;
   return this;
  }
  UpsertStudentAvatarVariablesBuilder equippedBottom(String? t) {
   _equippedBottom.value = t;
   return this;
  }
  UpsertStudentAvatarVariablesBuilder equippedShoes(String? t) {
   _equippedShoes.value = t;
   return this;
  }
  UpsertStudentAvatarVariablesBuilder equippedAccessory(String? t) {
   _equippedAccessory.value = t;
   return this;
  }
  UpsertStudentAvatarVariablesBuilder equippedBackground(String? t) {
   _equippedBackground.value = t;
   return this;
  }
  UpsertStudentAvatarVariablesBuilder equippedSpecial(String? t) {
   _equippedSpecial.value = t;
   return this;
  }
  UpsertStudentAvatarVariablesBuilder avatarConfig(String? t) {
   _avatarConfig.value = t;
   return this;
  }

  UpsertStudentAvatarVariablesBuilder(this._dataConnect, {required  this.studentUid,required  this.gender,required  this.skinTone,});
  Deserializer<UpsertStudentAvatarData> dataDeserializer = (dynamic json)  => UpsertStudentAvatarData.fromJson(jsonDecode(json));
  Serializer<UpsertStudentAvatarVariables> varsSerializer = (UpsertStudentAvatarVariables vars) => jsonEncode(vars.toJson());
  Future<OperationResult<UpsertStudentAvatarData, UpsertStudentAvatarVariables>> execute() {
    return ref().execute();
  }

  MutationRef<UpsertStudentAvatarData, UpsertStudentAvatarVariables> ref() {
    UpsertStudentAvatarVariables vars= UpsertStudentAvatarVariables(studentUid: studentUid,gender: gender,skinTone: skinTone,equippedHair: _equippedHair,equippedOutfit: _equippedOutfit,equippedBottom: _equippedBottom,equippedShoes: _equippedShoes,equippedAccessory: _equippedAccessory,equippedBackground: _equippedBackground,equippedSpecial: _equippedSpecial,avatarConfig: _avatarConfig,);
    return _dataConnect.mutation("UpsertStudentAvatar", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class UpsertStudentAvatarStudentAvatarUpsert {
  final String studentUid;
  UpsertStudentAvatarStudentAvatarUpsert.fromJson(dynamic json):
  
  studentUid = nativeFromJson<String>(json['studentUid']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final UpsertStudentAvatarStudentAvatarUpsert otherTyped = other as UpsertStudentAvatarStudentAvatarUpsert;
    return studentUid == otherTyped.studentUid;
    
  }
  @override
  int get hashCode => studentUid.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['studentUid'] = nativeToJson<String>(studentUid);
    return json;
  }

  UpsertStudentAvatarStudentAvatarUpsert({
    required this.studentUid,
  });
}

@immutable
class UpsertStudentAvatarData {
  final UpsertStudentAvatarStudentAvatarUpsert studentAvatar_upsert;
  UpsertStudentAvatarData.fromJson(dynamic json):
  
  studentAvatar_upsert = UpsertStudentAvatarStudentAvatarUpsert.fromJson(json['studentAvatar_upsert']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final UpsertStudentAvatarData otherTyped = other as UpsertStudentAvatarData;
    return studentAvatar_upsert == otherTyped.studentAvatar_upsert;
    
  }
  @override
  int get hashCode => studentAvatar_upsert.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['studentAvatar_upsert'] = studentAvatar_upsert.toJson();
    return json;
  }

  UpsertStudentAvatarData({
    required this.studentAvatar_upsert,
  });
}

@immutable
class UpsertStudentAvatarVariables {
  final String studentUid;
  final String gender;
  final String skinTone;
  late final Optional<String>equippedHair;
  late final Optional<String>equippedOutfit;
  late final Optional<String>equippedBottom;
  late final Optional<String>equippedShoes;
  late final Optional<String>equippedAccessory;
  late final Optional<String>equippedBackground;
  late final Optional<String>equippedSpecial;
  late final Optional<String>avatarConfig;
  @Deprecated('fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  UpsertStudentAvatarVariables.fromJson(Map<String, dynamic> json):
  
  studentUid = nativeFromJson<String>(json['studentUid']),
  gender = nativeFromJson<String>(json['gender']),
  skinTone = nativeFromJson<String>(json['skinTone']) {
  
  
  
  
  
    equippedHair = Optional.optional(nativeFromJson, nativeToJson);
    equippedHair.value = json['equippedHair'] == null ? null : nativeFromJson<String>(json['equippedHair']);
  
  
    equippedOutfit = Optional.optional(nativeFromJson, nativeToJson);
    equippedOutfit.value = json['equippedOutfit'] == null ? null : nativeFromJson<String>(json['equippedOutfit']);
  
  
    equippedBottom = Optional.optional(nativeFromJson, nativeToJson);
    equippedBottom.value = json['equippedBottom'] == null ? null : nativeFromJson<String>(json['equippedBottom']);
  
  
    equippedShoes = Optional.optional(nativeFromJson, nativeToJson);
    equippedShoes.value = json['equippedShoes'] == null ? null : nativeFromJson<String>(json['equippedShoes']);
  
  
    equippedAccessory = Optional.optional(nativeFromJson, nativeToJson);
    equippedAccessory.value = json['equippedAccessory'] == null ? null : nativeFromJson<String>(json['equippedAccessory']);
  
  
    equippedBackground = Optional.optional(nativeFromJson, nativeToJson);
    equippedBackground.value = json['equippedBackground'] == null ? null : nativeFromJson<String>(json['equippedBackground']);
  
  
    equippedSpecial = Optional.optional(nativeFromJson, nativeToJson);
    equippedSpecial.value = json['equippedSpecial'] == null ? null : nativeFromJson<String>(json['equippedSpecial']);
  
  
    avatarConfig = Optional.optional(nativeFromJson, nativeToJson);
    avatarConfig.value = json['avatarConfig'] == null ? null : nativeFromJson<String>(json['avatarConfig']);
  
  }
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final UpsertStudentAvatarVariables otherTyped = other as UpsertStudentAvatarVariables;
    return studentUid == otherTyped.studentUid && 
    gender == otherTyped.gender && 
    skinTone == otherTyped.skinTone && 
    equippedHair == otherTyped.equippedHair && 
    equippedOutfit == otherTyped.equippedOutfit && 
    equippedBottom == otherTyped.equippedBottom && 
    equippedShoes == otherTyped.equippedShoes && 
    equippedAccessory == otherTyped.equippedAccessory && 
    equippedBackground == otherTyped.equippedBackground && 
    equippedSpecial == otherTyped.equippedSpecial && 
    avatarConfig == otherTyped.avatarConfig;
    
  }
  @override
  int get hashCode => Object.hashAll([studentUid.hashCode, gender.hashCode, skinTone.hashCode, equippedHair.hashCode, equippedOutfit.hashCode, equippedBottom.hashCode, equippedShoes.hashCode, equippedAccessory.hashCode, equippedBackground.hashCode, equippedSpecial.hashCode, avatarConfig.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['studentUid'] = nativeToJson<String>(studentUid);
    json['gender'] = nativeToJson<String>(gender);
    json['skinTone'] = nativeToJson<String>(skinTone);
    if(equippedHair.state == OptionalState.set) {
      json['equippedHair'] = equippedHair.toJson();
    }
    if(equippedOutfit.state == OptionalState.set) {
      json['equippedOutfit'] = equippedOutfit.toJson();
    }
    if(equippedBottom.state == OptionalState.set) {
      json['equippedBottom'] = equippedBottom.toJson();
    }
    if(equippedShoes.state == OptionalState.set) {
      json['equippedShoes'] = equippedShoes.toJson();
    }
    if(equippedAccessory.state == OptionalState.set) {
      json['equippedAccessory'] = equippedAccessory.toJson();
    }
    if(equippedBackground.state == OptionalState.set) {
      json['equippedBackground'] = equippedBackground.toJson();
    }
    if(equippedSpecial.state == OptionalState.set) {
      json['equippedSpecial'] = equippedSpecial.toJson();
    }
    if(avatarConfig.state == OptionalState.set) {
      json['avatarConfig'] = avatarConfig.toJson();
    }
    return json;
  }

  UpsertStudentAvatarVariables({
    required this.studentUid,
    required this.gender,
    required this.skinTone,
    required this.equippedHair,
    required this.equippedOutfit,
    required this.equippedBottom,
    required this.equippedShoes,
    required this.equippedAccessory,
    required this.equippedBackground,
    required this.equippedSpecial,
    required this.avatarConfig,
  });
}

