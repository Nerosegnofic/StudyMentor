import 'package:flutter/material.dart';
import '../../../data/providers/dataconnect_provider.dart';
import '../../../services/support_ticket_service.dart';
import '../../../../l10n/app_localizations.dart';

class ParentHelpCenter extends StatefulWidget {
  final String uid;
  final String fullName;

  const ParentHelpCenter({
    super.key,
    required this.uid,
    required this.fullName,
  });

  @override
  State<ParentHelpCenter> createState() => _ParentHelpCenterState();
}

class _ParentHelpCenterState extends State<ParentHelpCenter> {
  static const _issueTypes = [
    _IssueType(
      id: 'appNotWorking',
      icon: Icons.bug_report_outlined,
      iconBg: Color(0xFFFFEBEE),
      iconColor: Color(0xFFE53935),
    ),
    _IssueType(
      id: 'quizQuestionError',
      icon: Icons.menu_book_outlined,
      iconBg: Color(0xFFE3F2FD),
      iconColor: Color(0xFF1E88E5),
    ),
    _IssueType(
      id: 'howDoI',
      icon: Icons.help_outline,
      iconBg: Color(0xFFE3F2FD),
      iconColor: Color(0xFF1E88E5),
    ),
  ];

  String _issueLabel(AppLocalizations loc, String id) => switch (id) {
        'appNotWorking' => loc.issueAppNotWorking,
        'quizQuestionError' => loc.issueQuizQuestionError,
        'howDoI' => loc.issueHowDoI,
        _ => id,
      };

  String? _selectedIssue;
  final TextEditingController _messageController = TextEditingController();
  int _charCount = 0;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _messageController.addListener(
      () => setState(() => _charCount = _messageController.text.length),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  bool get _canSend =>
      _selectedIssue != null &&
      _messageController.text.trim().isNotEmpty &&
      !_sending;

  // English text sent to the backend, independent of the UI locale, so
  // existing support-ticket records stay in a consistent format.
  static const _issueTypeBackendLabels = {
    'appNotWorking': "App isn't working properly",
    'quizQuestionError': 'Quiz question has an error',
    'howDoI': 'How do I...?',
  };

  Future<void> _send() async {
    if (!_canSend) return;
    final loc = AppLocalizations.of(context);
    setState(() => _sending = true);
    try {
      final service = SupportTicketService(DataConnectProvider());
      await service.submit(
        userId: widget.uid,
        userName: widget.fullName,
        issueType: _issueTypeBackendLabels[_selectedIssue!] ?? _selectedIssue!,
        message: _messageController.text.trim(),
      );
      if (!mounted) return;
      _messageController.clear();
      setState(() {
        _selectedIssue = null;
        _charCount = 0;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(loc.messageSentSuccessMessage),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(loc.messageSendErrorMessage),
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFFE53935),
        ),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final firstName = widget.fullName.trim().split(RegExp(r'\s+')).first;
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FF),
      appBar: AppBar(
        title: Text(loc.helpCenterTitle),
        backgroundColor: const Color(0xFFF5F7FF),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildMascotCard(firstName),
            const SizedBox(height: 20),
            Text(
              loc.whatCanWeHelpWithTitle,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1A1A2E),
              ),
            ),
            const SizedBox(height: 12),
            ..._issueTypes.map(_buildIssueCard),
            const SizedBox(height: 20),
            Text(
              loc.tellUsMoreTitle,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1A1A2E),
              ),
            ),
            const SizedBox(height: 10),
            _buildMessageField(),
            const SizedBox(height: 20),
            _buildSendButton(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // ── Mascot greeting card ─────────────────────────────────────────────────

  Widget _buildMascotCard(String firstName) {
    final loc = AppLocalizations.of(context);
    final greeting = loc.needHelpGreeting(firstName);
    final nameIndex = greeting.indexOf(firstName);
    final before = nameIndex >= 0 ? greeting.substring(0, nameIndex) : greeting;
    final after = nameIndex >= 0
        ? greeting.substring(nameIndex + firstName.length)
        : '';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F8E9),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFA5D6A7)),
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: const BoxDecoration(
              color: Color(0xFFFFB300),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.support_agent,
              color: Colors.white,
              size: 30,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF1A1A2E),
                  height: 1.4,
                ),
                children: [
                  TextSpan(text: before),
                  TextSpan(
                    text: firstName,
                    style: const TextStyle(
                      color: Color(0xFF43A047),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  TextSpan(text: after),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Issue type cards ─────────────────────────────────────────────────────

  Widget _buildIssueCard(_IssueType issue) {
    final loc = AppLocalizations.of(context);
    final selected = _selectedIssue == issue.id;
    return GestureDetector(
      onTap: () => setState(() => _selectedIssue = issue.id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF4A6CF7) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected
                ? const Color(0xFF4A6CF7)
                : Colors.grey.shade200,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: selected ? Colors.white.withOpacity(0.2) : issue.iconBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                issue.icon,
                color: selected ? Colors.white : issue.iconColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                _issueLabel(loc, issue.id),
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: selected ? Colors.white : const Color(0xFF1A1A2E),
                ),
              ),
            ),
            if (selected)
              const Icon(Icons.check_circle, color: Colors.white, size: 20),
          ],
        ),
      ),
    );
  }

  // ── Message field ────────────────────────────────────────────────────────

  Widget _buildMessageField() {
    final loc = AppLocalizations.of(context);
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          TextField(
            controller: _messageController,
            maxLines: 5,
            maxLength: 500,
            buildCounter: (_, {required currentLength, required isFocused, maxLength}) =>
                null,
            decoration: InputDecoration(
              hintText: loc.describeIssueHint,
              hintStyle:
                  TextStyle(color: Colors.grey.shade400, fontSize: 13),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(14),
            ),
          ),
          Container(
            padding: const EdgeInsetsDirectional.only(end: 12, bottom: 8),
            alignment: AlignmentDirectional.centerEnd,
            child: Text(
              loc.charCounterLabel(_charCount),
              style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
            ),
          ),
        ],
      ),
    );
  }

  // ── Send button ──────────────────────────────────────────────────────────

  Widget _buildSendButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _canSend ? _send : null,
        icon: _sending
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : const Icon(Icons.send_outlined, size: 18),
        label: Text(AppLocalizations.of(context).sendToTeamButton),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
          backgroundColor: const Color(0xFF4A6CF7),
          foregroundColor: Colors.white,
          disabledBackgroundColor: Colors.grey.shade200,
          disabledForegroundColor: Colors.grey.shade400,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
      ),
    );
  }
}

class _IssueType {
  final String id;
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  const _IssueType({
    required this.id,
    required this.icon,
    required this.iconBg,
    required this.iconColor,
  });
}
