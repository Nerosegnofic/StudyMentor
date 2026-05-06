part of 'generated.dart';

class GetStudentAvatarVariablesBuilder {
  String studentUid;

  final FirebaseDataConnect _dataConnect;
  GetStudentAvatarVariablesBuilder(this._dataConnect, {required  this.studentUid,});
  Deserializer<GetStudentAvatarData> dataDeserializer = (dynamic json)  => GetStudentAvatarData.fromJson(jsonDecode(json));
  Serializer<GetStudentAvatarVariables> varsSerializer = (GetStudentAvatarVariables vars) => jsonEncode(vars.toJson());
  Future<QueryResult<GetStudentAvatarData, GetStudentAvatarVariables>> execute() {
    return ref().execute();
  }

  QueryRef<GetStudentAvatarData, GetStudentAvatarVariables> ref() {
    GetStudentAvatarVariables vars= GetStudentAvatarVariables(studentUid: studentUid,);
    return _dataConnect.query("GetStudentAvatar", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class GetStudentAvatarStudentAvatar {
  final String gender;
  final String skinTone;
  final String? equippedHair;
  final String? equippedOutfit;
  final String? equippedBottom;
  final String? equippedShoes;
  final String? equippedAccessory;
  final String? equippedBackground;
  final String? equippedSpecial;
  GetStudentAvatarStudentAvatar.fromJson(dynamic json):
  
  gender = nativeFromJson<String>(json['gender']),
  skinTone = nativeFromJson<String>(json['skinTone']),
  equippedHair = json['equippedHair'] == null ? null : nativeFromJson<String>(json['equippedHair']),
  equippedOutfit = json['equippedOutfit'] == null ? null : nativeFromJson<String>(json['equippedOutfit']),
  equippedBottom = json['equippedBottom'] == null ? null : nativeFromJson<String>(json['equippedBottom']),
  equippedShoes = json['equippedShoes'] == null ? null : nativeFromJson<String>(json['equippedShoes']),
  equippedAccessory = json['equippedAccessory'] == null ? null : nativeFromJson<String>(json['equippedAccessory']),
  equippedBackground = json['equippedBackground'] == null ? null : nativeFromJson<String>(json['equippedBackground']),
  equippedSpecial = json['equippedSpecial'] == null ? null : nativeFromJson<String>(json['equippedSpecial']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final GetStudentAvatarStudentAvatar otherTyped = other as GetStudentAvatarStudentAvatar;
    return gender == otherTyped.gender && 
    skinTone == otherTyped.skinTone && 
    equippedHair == otherTyped.equippedHair && 
    equippedOutfit == otherTyped.equippedOutfit && 
    equippedBottom == otherTyped.equippedBottom && 
    equippedShoes == otherTyped.equippedShoes && 
    equippedAccessory == otherTyped.equippedAccessory && 
    equippedBackground == otherTyped.equippedBackground && 
    equippedSpecial == otherTyped.equippedSpecial;
    
  }
  @override
  int get hashCode => Object.hashAll([gender.hashCode, skinTone.hashCode, equippedHair.hashCode, equippedOutfit.hashCode, equippedBottom.hashCode, equippedShoes.hashCode, equippedAccessory.hashCode, equippedBackground.hashCode, equippedSpecial.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['gender'] = nativeToJson<String>(gender);
    json['skinTone'] = nativeToJson<String>(skinTone);
    if (equippedHair != null) {
      json['equippedHair'] = nativeToJson<String?>(equippedHair);
    }
    if (equippedOutfit != null) {
      json['equippedOutfit'] = nativeToJson<String?>(equippedOutfit);
    }
    if (equippedBottom != null) {
      json['equippedBottom'] = nativeToJson<String?>(equippedBottom);
    }
    if (equippedShoes != null) {
      json['equippedShoes'] = nativeToJson<String?>(equippedShoes);
    }
    if (equippedAccessory != null) {
      json['equippedAccessory'] = nativeToJson<String?>(equippedAccessory);
    }
    if (equippedBackground != null) {
      json['equippedBackground'] = nativeToJson<String?>(equippedBackground);
    }
    if (equippedSpecial != null) {
      json['equippedSpecial'] = nativeToJson<String?>(equippedSpecial);
    }
    return json;
  }

  GetStudentAvatarStudentAvatar({
    required this.gender,
    required this.skinTone,
    this.equippedHair,
    this.equippedOutfit,
    this.equippedBottom,
    this.equippedShoes,
    this.equippedAccessory,
    this.equippedBackground,
    this.equippedSpecial,
  });
}

@immutable
class GetStudentAvatarData {
  final GetStudentAvatarStudentAvatar? studentAvatar;
  GetStudentAvatarData.fromJson(dynamic json):
  
  studentAvatar = json['studentAvatar'] == null ? null : GetStudentAvatarStudentAvatar.fromJson(json['studentAvatar']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final GetStudentAvatarData otherTyped = other as GetStudentAvatarData;
    return studentAvatar == otherTyped.studentAvatar;
    
  }
  @override
  int get hashCode => studentAvatar.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    if (studentAvatar != null) {
      json['studentAvatar'] = studentAvatar!.toJson();
    }
    return json;
  }

  GetStudentAvatarData({
    this.studentAvatar,
  });
}

@immutable
class GetStudentAvatarVariables {
  final String studentUid;
  @Deprecated('fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  GetStudentAvatarVariables.fromJson(Map<String, dynamic> json):
  
  studentUid = nativeFromJson<String>(json['studentUid']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final GetStudentAvatarVariables otherTyped = other as GetStudentAvatarVariables;
    return studentUid == otherTyped.studentUid;
    
  }
  @override
  int get hashCode => studentUid.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['studentUid'] = nativeToJson<String>(studentUid);
    return json;
  }

  GetStudentAvatarVariables({
    required this.studentUid,
  });
}

