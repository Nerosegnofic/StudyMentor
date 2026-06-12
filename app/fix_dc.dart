import 'dart:io';

void main() async {
  final dir = Directory('lib/dataconnect_generated');
  await for (var file in dir.list(recursive: true)) {
    if (file is File && file.path.endsWith('.dart')) {
      var content = await file.readAsString();
      if (content.contains('nativeFromJson<String>')) {
        content = content.replaceAll(RegExp(r"nativeFromJson<String>\(json\['([^']+)'\]\)"), r"json['$1']?.toString() ?? ''");
        await file.writeAsString(content);
      }
    }
  }
}
