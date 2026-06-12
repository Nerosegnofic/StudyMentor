import 'dart:io';

void main() async {
  final fileBloc = File('lib/src/bloc/auth/auth_bloc.dart');
  var contentBloc = await fileBloc.readAsString();
  contentBloc = contentBloc.replaceAll('StudentLegacyProfileUpdateError', 'LegacyStudentProfileUpdateError');
  await fileBloc.writeAsString(contentBloc);
  
  final fileState = File('lib/src/bloc/auth/auth_state.dart');
  var contentState = await fileState.readAsString();
  contentState = contentState.replaceAll('LegacyStudentLegacyProfileUpdateError', 'LegacyStudentProfileUpdateError');
  await fileState.writeAsString(contentState);
}
