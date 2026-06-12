import re

with open('lib/src/bloc/auth/auth_bloc.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Remove constructor registrations
content = re.sub(r'^\s*on<CreateStudentRequested>\(_onCreateStudent\);\n', '', content, flags=re.MULTILINE)
content = re.sub(r'^\s*on<LoadStudentsRequested>\(_onLoadStudents\);\n', '', content, flags=re.MULTILINE)
content = re.sub(r'^\s*on<RefreshStudentVerificationsRequested>\(_onRefreshStudentVerifications\);\n', '', content, flags=re.MULTILINE)
content = re.sub(r'^\s*on<DeleteStudentRequested>\(_onDeleteStudent\);\n', '', content, flags=re.MULTILINE)

# Rename event registrations
content = content.replace('on<LoadAppRulesRequested>(_onLoadAppRules);', 'on<LegacyLoadAppRulesRequested>(_onLoadAppRules);')
content = content.replace('on<SaveAppRulesRequested>(_onSaveAppRules);', 'on<LegacySaveAppRulesRequested>(_onSaveAppRules);')
content = content.replace('on<RefreshStudentDataRequested>(_onRefreshStudentData);', 'on<LegacyRefreshStudentDataRequested>(_onRefreshStudentData);')

# Rename event classes in method signatures
content = content.replace('LoadAppRulesRequested event', 'LegacyLoadAppRulesRequested event')
content = content.replace('SaveAppRulesRequested event', 'LegacySaveAppRulesRequested event')
content = content.replace('RefreshStudentDataRequested event', 'LegacyRefreshStudentDataRequested event')

# Rename state classes
content = content.replace('ProfileUpdateLoading', 'LegacyProfileUpdateLoading') # Assuming it exists, if not we'll handle it
content = content.replace('ProfileUpdateSuccess', 'LegacyProfileUpdateSuccess')
content = content.replace('ProfileUpdateError', 'LegacyProfileUpdateError')
content = content.replace('AppConfigLoading', 'LegacyAppConfigLoading')
content = content.replace('AppRulesLoaded', 'LegacyAppRulesLoaded')
content = content.replace('AppConfigSaving', 'LegacyAppConfigSaving')
content = content.replace('AppConfigSaved', 'LegacyAppConfigSaved')
content = content.replace('AppConfigError', 'LegacyAppConfigError')
content = content.replace('StudentDataRefreshing', 'LegacyStudentDataRefreshing')
content = content.replace('ParentAccountDeleteLoading', 'LegacyParentAccountDeleteLoading')
content = content.replace('ParentAccountDeleted', 'LegacyParentAccountDeleted')
content = content.replace('ParentAccountDeleteError', 'LegacyParentAccountDeleteError')
content = content.replace('StudentProfileUpdateLoading', 'StudentLegacyProfileUpdateLoading')
content = content.replace('StudentProfileUpdateSuccess', 'StudentLegacyProfileUpdateSuccess')
content = content.replace('StudentProfileUpdateError', 'LegacyStudentLegacyProfileUpdateError')

# Delete handlers (using a simple approach of finding the method start and end)
def remove_method(content, method_name):
    # Regex to find method block. Assumes no deeply nested un-matched braces that would fool a simple greedy match.
    # Actually, greedy match doesn't work for braces. Let's use string manipulation.
    idx = content.find(f'Future<void> {method_name}(')
    if idx == -1:
        return content
    
    start_idx = idx
    # find the opening brace of the method body
    brace_idx = content.find('{', start_idx)
    brace_count = 1
    i = brace_idx + 1
    while brace_count > 0 and i < len(content):
        if content[i] == '{':
            brace_count += 1
        elif content[i] == '}':
            brace_count -= 1
        i += 1
    
    return content[:start_idx] + content[i:]

content = remove_method(content, '_onCreateStudent')
content = remove_method(content, '_onLoadStudents')
content = remove_method(content, '_onRefreshStudentVerifications')
content = remove_method(content, '_onDeleteStudent')

# Fix updateProfile (needs parentUid)
content = content.replace('final updatedUser = await repository.updateProfile(\\n        newFullName: event.newFullName,', 
                          'final updatedUser = await repository.updateProfile(\\n        parentUid: \\'\\', // TODO: fix parentUid\\n        newFullName: event.newFullName,')

# Fix deleteParentAccount
content = content.replace('await repository.deleteParentAccount(\\n        currentPassword: event.currentPassword,\\n      );', 
                          'await repository.deleteParentAccount(event.currentPassword);')

# Fix updateStudentProfile return type and pendingEmail
# In the original, it was inal pendingEmail = await repository.updateStudentProfile(...
# But now it returns a StudentModel, and doesn't return pendingEmail.
old_update_student = '''final pendingEmail = await repository.updateStudentProfile(
        studentUid: event.studentUid,
        studentEmail: event.studentEmail,
        newFullName: event.newFullName,
        newEmail: event.newEmail,
        currentPassword: event.currentPassword,
        newPassword: event.newPassword,
      );'''

new_update_student = '''await repository.updateStudentProfile(
        studentUid: event.studentUid,
        studentEmail: event.studentEmail,
        newFullName: event.newFullName,
        newEmail: event.newEmail,
        currentPassword: event.currentPassword,
        newPassword: event.newPassword,
      );'''
content = content.replace(old_update_student, new_update_student)
content = content.replace('pendingEmail: pendingEmail,', 'pendingEmail: null,')

with open('lib/src/bloc/auth/auth_bloc.dart', 'w', encoding='utf-8') as f:
    f.write(content)

print("Modifications applied.")
