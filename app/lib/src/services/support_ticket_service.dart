import '../data/providers/dataconnect_provider.dart';

/// Submits student help / support tickets to DataConnect.
class SupportTicketService {
  final DataConnectProvider _dataConnect;

  SupportTicketService(this._dataConnect);

  Future<void> submit({
    required String userId,
    required String userName,
    required String issueType,
    required String message,
  }) async {
    await _dataConnect.insertSupportTicket(
      userId: userId,
      userName: userName,
      issueType: issueType,
      message: message,
    );
  }
}
