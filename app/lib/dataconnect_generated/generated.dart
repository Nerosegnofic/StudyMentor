library dataconnect_generated;
import 'package:firebase_data_connect/firebase_data_connect.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart';

part 'insert_user.dart';

part 'upsert_current_user.dart';

part 'delete_user.dart';

part 'insert_parent.dart';

part 'insert_student.dart';

part 'set_user_inactive.dart';

part 'mark_email_verified.dart';

part 'insert_app_rule.dart';

part 'delete_all_app_rules_for_student.dart';

part 'update_student_friend_code.dart';

part 'update_last_active_at.dart';

part 'send_friend_request.dart';

part 'create_friendship.dart';

part 'remove_friend.dart';

part 'update_friend_request_status.dart';

part 'upsert_student_settings.dart';

part 'insert_support_ticket.dart';

part 'insert_student_owned_item.dart';

part 'update_student_coins.dart';

part 'upsert_student_avatar.dart';

part 'update_student_xp_and_coins.dart';

part 'delete_all_owned_items_for_student.dart';

part 'delete_student_avatar.dart';

part 'delete_student_settings.dart';

part 'delete_student_config.dart';

part 'delete_all_friend_requests_by_student.dart';

part 'delete_all_friendships_for_student.dart';

part 'delete_student_record.dart';

part 'delete_user_record.dart';

part 'update_student_full_name.dart';

part 'delete_parent_record.dart';

part 'upsert_student_config.dart';

part 'upsert_subject_progress.dart';

part 'get_user_by_uid.dart';

part 'get_students_by_parent.dart';

part 'get_student_with_parent.dart';

part 'get_installed_apps_for_student.dart';

part 'insert_installed_app.dart';

part 'delete_all_installed_apps_for_student.dart';

part 'get_student_profile.dart';

part 'get_student_by_username.dart';

part 'get_weekly_leaderboard.dart';

part 'get_student_by_friend_code.dart';

part 'get_sent_friend_requests.dart';

part 'get_friends_for_student.dart';

part 'get_pending_friend_requests_for_parent.dart';

part 'get_student_settings.dart';

part 'get_student_owned_items.dart';

part 'get_student_avatar.dart';

part 'get_app_config_for_student.dart';

part 'get_sibling_leaderboard.dart';

part 'get_all_subject_progress.dart';



  enum Role {
    
      Parent,
    
      Student,
    
  }
  
  String roleSerializer(EnumValue<Role> e) {
    return e.stringValue;
  }
  EnumValue<Role> roleDeserializer(dynamic data) {
    switch (data) {
      
      case 'Parent':
        return const Known(Role.Parent);
      
      case 'Student':
        return const Known(Role.Student);
      
      default:
        return Unknown(data);
    }
  }
  



String enumSerializer(Enum e) {
  return e.name;
}



/// A sealed class representing either a known enum value or an unknown string value.
@immutable
sealed class EnumValue<T extends Enum> {
  const EnumValue();

  

  /// The string representation of the value.
  String get stringValue;
  @override
  String toString() {
    return "EnumValue($stringValue)";
  }
}

/// Represents a known, valid enum value.
class Known<T extends Enum> extends EnumValue<T> {
  /// The actual enum value.
  final T value;

  const Known(this.value);

  @override
  String get stringValue => value.name;

  @override
  String toString() {
    return "Known($stringValue)";
  }
}
/// Represents an unknown or unrecognized enum value.
class Unknown extends EnumValue<Never> {
  /// The raw string value that couldn't be mapped to a known enum.
  @override
  final String stringValue;

  const Unknown(this.stringValue);
  @override
  String toString() {
    return "Unknown($stringValue)";
  }
}

class ExampleConnector {
  
  
  InsertUserVariablesBuilder insertUser ({required String email, required String fullName, required Role role, }) {
    return InsertUserVariablesBuilder(dataConnect, email: email,fullName: fullName,role: role,);
  }
  
  
  UpsertCurrentUserVariablesBuilder upsertCurrentUser ({required Role role, }) {
    return UpsertCurrentUserVariablesBuilder(dataConnect, role: role,);
  }
  
  
  DeleteUserVariablesBuilder deleteUser () {
    return DeleteUserVariablesBuilder(dataConnect, );
  }
  
  
  InsertParentVariablesBuilder insertParent () {
    return InsertParentVariablesBuilder(dataConnect, );
  }
  
  
  InsertStudentVariablesBuilder insertStudent ({required String parentUid, required String username, }) {
    return InsertStudentVariablesBuilder(dataConnect, parentUid: parentUid,username: username,);
  }
  
  
  SetUserInactiveVariablesBuilder setUserInactive () {
    return SetUserInactiveVariablesBuilder(dataConnect, );
  }
  
  
  MarkEmailVerifiedVariablesBuilder markEmailVerified () {
    return MarkEmailVerifiedVariablesBuilder(dataConnect, );
  }
  
  
  InsertAppRuleVariablesBuilder insertAppRule ({required String studentUid, required String packageName, required String appLabel, required bool isPaused, }) {
    return InsertAppRuleVariablesBuilder(dataConnect, studentUid: studentUid,packageName: packageName,appLabel: appLabel,isPaused: isPaused,);
  }
  
  
  DeleteAllAppRulesForStudentVariablesBuilder deleteAllAppRulesForStudent ({required String studentUid, }) {
    return DeleteAllAppRulesForStudentVariablesBuilder(dataConnect, studentUid: studentUid,);
  }
  
  
  UpdateStudentFriendCodeVariablesBuilder updateStudentFriendCode ({required String friendCode, }) {
    return UpdateStudentFriendCodeVariablesBuilder(dataConnect, friendCode: friendCode,);
  }
  
  
  UpdateLastActiveAtVariablesBuilder updateLastActiveAt () {
    return UpdateLastActiveAtVariablesBuilder(dataConnect, );
  }
  
  
  SendFriendRequestVariablesBuilder sendFriendRequest ({required String fromStudentUid, required String toFriendCode, required String toStudentUid, required String toStudentName, }) {
    return SendFriendRequestVariablesBuilder(dataConnect, fromStudentUid: fromStudentUid,toFriendCode: toFriendCode,toStudentUid: toStudentUid,toStudentName: toStudentName,);
  }
  
  
  CreateFriendshipVariablesBuilder createFriendship ({required String studentUid, required String friendUid, }) {
    return CreateFriendshipVariablesBuilder(dataConnect, studentUid: studentUid,friendUid: friendUid,);
  }
  
  
  RemoveFriendVariablesBuilder removeFriend ({required String id, }) {
    return RemoveFriendVariablesBuilder(dataConnect, id: id,);
  }
  
  
  UpdateFriendRequestStatusVariablesBuilder updateFriendRequestStatus ({required String id, required String status, }) {
    return UpdateFriendRequestStatusVariablesBuilder(dataConnect, id: id,status: status,);
  }
  
  
  UpsertStudentSettingsVariablesBuilder upsertStudentSettings ({required String studentUid, required bool notificationsEnabled, required bool soundEffectsEnabled, required bool backgroundMusicEnabled, }) {
    return UpsertStudentSettingsVariablesBuilder(dataConnect, studentUid: studentUid,notificationsEnabled: notificationsEnabled,soundEffectsEnabled: soundEffectsEnabled,backgroundMusicEnabled: backgroundMusicEnabled,);
  }
  
  
  InsertSupportTicketVariablesBuilder insertSupportTicket ({required String userId, required String userName, required String issueType, required String message, }) {
    return InsertSupportTicketVariablesBuilder(dataConnect, userId: userId,userName: userName,issueType: issueType,message: message,);
  }
  
  
  InsertStudentOwnedItemVariablesBuilder insertStudentOwnedItem ({required String studentUid, required String itemId, }) {
    return InsertStudentOwnedItemVariablesBuilder(dataConnect, studentUid: studentUid,itemId: itemId,);
  }
  
  
  UpdateStudentCoinsVariablesBuilder updateStudentCoins ({required int totalCoins, }) {
    return UpdateStudentCoinsVariablesBuilder(dataConnect, totalCoins: totalCoins,);
  }
  
  
  UpsertStudentAvatarVariablesBuilder upsertStudentAvatar ({required String studentUid, required String gender, required String skinTone, }) {
    return UpsertStudentAvatarVariablesBuilder(dataConnect, studentUid: studentUid,gender: gender,skinTone: skinTone,);
  }
  
  
  UpdateStudentXpAndCoinsVariablesBuilder updateStudentXpAndCoins ({required int totalXp, required int weeklyXp, required int totalCoins, required int totalQuestionsAnswered, required int currentStreak, }) {
    return UpdateStudentXpAndCoinsVariablesBuilder(dataConnect, totalXp: totalXp,weeklyXp: weeklyXp,totalCoins: totalCoins,totalQuestionsAnswered: totalQuestionsAnswered,currentStreak: currentStreak,);
  }
  
  
  DeleteAllOwnedItemsForStudentVariablesBuilder deleteAllOwnedItemsForStudent ({required String studentUid, }) {
    return DeleteAllOwnedItemsForStudentVariablesBuilder(dataConnect, studentUid: studentUid,);
  }
  
  
  DeleteStudentAvatarVariablesBuilder deleteStudentAvatar ({required String studentUid, }) {
    return DeleteStudentAvatarVariablesBuilder(dataConnect, studentUid: studentUid,);
  }
  
  
  DeleteStudentSettingsVariablesBuilder deleteStudentSettings ({required String studentUid, }) {
    return DeleteStudentSettingsVariablesBuilder(dataConnect, studentUid: studentUid,);
  }
  
  
  DeleteStudentConfigVariablesBuilder deleteStudentConfig ({required String studentUid, }) {
    return DeleteStudentConfigVariablesBuilder(dataConnect, studentUid: studentUid,);
  }
  
  
  DeleteAllFriendRequestsByStudentVariablesBuilder deleteAllFriendRequestsByStudent ({required String studentUid, }) {
    return DeleteAllFriendRequestsByStudentVariablesBuilder(dataConnect, studentUid: studentUid,);
  }
  
  
  DeleteAllFriendshipsForStudentVariablesBuilder deleteAllFriendshipsForStudent ({required String studentUid, }) {
    return DeleteAllFriendshipsForStudentVariablesBuilder(dataConnect, studentUid: studentUid,);
  }
  
  
  DeleteStudentRecordVariablesBuilder deleteStudentRecord ({required String uid, }) {
    return DeleteStudentRecordVariablesBuilder(dataConnect, uid: uid,);
  }
  
  
  DeleteUserRecordVariablesBuilder deleteUserRecord ({required String uid, }) {
    return DeleteUserRecordVariablesBuilder(dataConnect, uid: uid,);
  }
  
  
  UpdateStudentFullNameVariablesBuilder updateStudentFullName ({required String uid, required String fullName, }) {
    return UpdateStudentFullNameVariablesBuilder(dataConnect, uid: uid,fullName: fullName,);
  }
  
  
  DeleteParentRecordVariablesBuilder deleteParentRecord () {
    return DeleteParentRecordVariablesBuilder(dataConnect, );
  }
  
  
  UpsertStudentConfigVariablesBuilder upsertStudentConfig ({required String studentUid, required int usageHours, required int usageMinutes, required int cooldownHours, required int cooldownMinutes, required String quizCount, }) {
    return UpsertStudentConfigVariablesBuilder(dataConnect, studentUid: studentUid,usageHours: usageHours,usageMinutes: usageMinutes,cooldownHours: cooldownHours,cooldownMinutes: cooldownMinutes,quizCount: quizCount,);
  }
  
  
  UpsertSubjectProgressVariablesBuilder upsertSubjectProgress ({required String studentUid, required String subjectKey, required int totalXp, required int level, }) {
    return UpsertSubjectProgressVariablesBuilder(dataConnect, studentUid: studentUid,subjectKey: subjectKey,totalXp: totalXp,level: level,);
  }
  
  
  GetUserByUidVariablesBuilder getUserByUid ({required String uid, }) {
    return GetUserByUidVariablesBuilder(dataConnect, uid: uid,);
  }
  
  
  GetStudentsByParentVariablesBuilder getStudentsByParent ({required String parentUid, }) {
    return GetStudentsByParentVariablesBuilder(dataConnect, parentUid: parentUid,);
  }
  
  
  GetStudentWithParentVariablesBuilder getStudentWithParent ({required String uid, }) {
    return GetStudentWithParentVariablesBuilder(dataConnect, uid: uid,);
  }
  
  
  GetInstalledAppsForStudentVariablesBuilder getInstalledAppsForStudent ({required String studentUid, }) {
    return GetInstalledAppsForStudentVariablesBuilder(dataConnect, studentUid: studentUid,);
  }
  
  
  InsertInstalledAppVariablesBuilder insertInstalledApp ({required String studentUid, required String packageName, required String appLabel, required bool isSystemApp, }) {
    return InsertInstalledAppVariablesBuilder(dataConnect, studentUid: studentUid,packageName: packageName,appLabel: appLabel,isSystemApp: isSystemApp,);
  }
  
  
  DeleteAllInstalledAppsForStudentVariablesBuilder deleteAllInstalledAppsForStudent ({required String studentUid, }) {
    return DeleteAllInstalledAppsForStudentVariablesBuilder(dataConnect, studentUid: studentUid,);
  }
  
  
  GetStudentProfileVariablesBuilder getStudentProfile ({required String uid, }) {
    return GetStudentProfileVariablesBuilder(dataConnect, uid: uid,);
  }
  
  
  GetStudentByUsernameVariablesBuilder getStudentByUsername ({required String username, }) {
    return GetStudentByUsernameVariablesBuilder(dataConnect, username: username,);
  }
  
  
  GetWeeklyLeaderboardVariablesBuilder getWeeklyLeaderboard () {
    return GetWeeklyLeaderboardVariablesBuilder(dataConnect, );
  }
  
  
  GetStudentByFriendCodeVariablesBuilder getStudentByFriendCode ({required String friendCode, }) {
    return GetStudentByFriendCodeVariablesBuilder(dataConnect, friendCode: friendCode,);
  }
  
  
  GetSentFriendRequestsVariablesBuilder getSentFriendRequests ({required String fromStudentUid, }) {
    return GetSentFriendRequestsVariablesBuilder(dataConnect, fromStudentUid: fromStudentUid,);
  }
  
  
  GetFriendsForStudentVariablesBuilder getFriendsForStudent ({required String studentUid, }) {
    return GetFriendsForStudentVariablesBuilder(dataConnect, studentUid: studentUid,);
  }
  
  
  GetPendingFriendRequestsForParentVariablesBuilder getPendingFriendRequestsForParent ({required String parentUid, }) {
    return GetPendingFriendRequestsForParentVariablesBuilder(dataConnect, parentUid: parentUid,);
  }
  
  
  GetStudentSettingsVariablesBuilder getStudentSettings ({required String studentUid, }) {
    return GetStudentSettingsVariablesBuilder(dataConnect, studentUid: studentUid,);
  }
  
  
  GetStudentOwnedItemsVariablesBuilder getStudentOwnedItems ({required String studentUid, }) {
    return GetStudentOwnedItemsVariablesBuilder(dataConnect, studentUid: studentUid,);
  }
  
  
  GetStudentAvatarVariablesBuilder getStudentAvatar ({required String studentUid, }) {
    return GetStudentAvatarVariablesBuilder(dataConnect, studentUid: studentUid,);
  }
  
  
  GetAppConfigForStudentVariablesBuilder getAppConfigForStudent ({required String studentUid, }) {
    return GetAppConfigForStudentVariablesBuilder(dataConnect, studentUid: studentUid,);
  }
  
  
  GetSiblingLeaderboardVariablesBuilder getSiblingLeaderboard ({required String parentUid, }) {
    return GetSiblingLeaderboardVariablesBuilder(dataConnect, parentUid: parentUid,);
  }
  
  
  GetAllSubjectProgressVariablesBuilder getAllSubjectProgress ({required String studentUid, }) {
    return GetAllSubjectProgressVariablesBuilder(dataConnect, studentUid: studentUid,);
  }
  

  static ConnectorConfig connectorConfig = ConnectorConfig(
    'us-east1',
    'example',
    'studymentor',
  );

  ExampleConnector({required this.dataConnect});
  static ExampleConnector get instance {
    
    return ExampleConnector(
        dataConnect: FirebaseDataConnect.instanceFor(
            connectorConfig: connectorConfig,
            
            sdkType: CallerSDKType.generated));
  }

  FirebaseDataConnect dataConnect;
}
