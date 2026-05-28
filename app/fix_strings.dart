import 'dart:io';

void main() async {
  var dir = Directory('lib/dataconnect_generated');
  await for (var f in dir.list(recursive: true)) {
    if (f is File && f.path.endsWith('.dart')) {
      var c = await f.readAsString();
      if (c.contains('nativeFromJson<String>')) {
        c = c.replaceAllMapped(
            RegExp(r"nativeFromJson<String>\(json\['([^']+)'\]\)"),
            (m) => "json['${m.group(1)}']?.toString() ?? ''"
        );
        await f.writeAsString(c);
      }
    }
  }
}
