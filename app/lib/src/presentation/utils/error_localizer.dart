import '../../../l10n/app_localizations.dart';

String localizeError(String message, AppLocalizations loc) {
  switch (message) {
    // Auth login/general errors
    case 'Invalid email or password. Please try again.':
      return loc.errInvalidCredentials;
    case 'Network error. Check your connection.':
      return loc.errNetworkError;
    case 'Network error. Check your connection and try again.':
      return loc.errNetworkErrorRetry;
    case 'Password is too weak.':
      return loc.errWeakPassword;
    // Auth registration errors
    case 'Password is too weak. Please use at least 6 characters.':
      return loc.errWeakPasswordDetailed;
    case 'That email address is already registered. Please use a different one.':
      return loc.errEmailAlreadyInUse;
    case "That email address doesn't look right. Please check it.":
      return loc.errInvalidEmailFormat;
    case 'Session expired. Please log out and log in again.':
      return loc.errSessionExpired;
    case 'Too many attempts. Please wait a moment and try again.':
      return loc.errTooManyAttempts;
    case 'Registration failed. Please try again.':
      return loc.errRegistrationFailed;
    // Email verification errors
    case 'No signed-in account found. Please log in again.':
      return loc.errNoSignedInAccount;
    case 'Could not send verification email. Please try again.':
      return loc.errVerificationEmailFailed;
    // Profile update errors
    case 'Current password is incorrect.':
      return loc.errWrongCurrentPassword;
    case 'New password is too weak. Use at least 6 characters.':
      return loc.errNewPasswordTooWeak;
    case 'That email address is already in use by another account.':
      return loc.errEmailAlreadyInUseOther;
    case 'Update failed. Please try again.':
      return loc.errUpdateFailed;
    // Upload errors
    case 'Upload failed. Please try again.':
      return loc.errUploadFailed;
    case 'A document for this subject is still being processed. '
          'Please wait until it finishes before uploading another.':
      return loc.errSubjectStillProcessing;
    // Quiz generation rejected because the subject is still ingesting (409 backstop).
    case 'This subject is still being prepared. Please try again in a moment.':
      return loc.quizSubjectStillPreparing;
    // Account deletion errors
    case 'Unable to delete account. Please try again.':
      return loc.errDeleteAccountFailed;
    // Student registration errors (from StudentsBloc)
    case 'Session expired. Please log out and log in again before adding a student.':
      return loc.errStudentSessionExpired;
    case 'This email is already registered. Try logging in or resetting the password.':
      return loc.errStudentEmailAlreadyRegistered;
    case 'The password provided is too weak. Please use at least 6 characters.':
      return loc.errStudentWeakPassword;
    case 'The email address is badly formatted.':
      return loc.errStudentInvalidEmail;
    case 'An unexpected error occurred. Please try again.':
      return loc.errUnexpected;
    case 'Could not load your profile. Please try again.':
      return loc.errCouldNotLoadProfile;
    case 'Invalid parent credentials. Logout denied.':
      return loc.errInvalidParentCredentials;
    case 'Invalid credentials':
      return loc.errWrongCurrentPassword;
    default:
      return message;
  }
}
