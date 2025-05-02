import 'dart:io';

void main() async {
  final directory = Directory('lib');
  await updateImportsInDirectory(directory);
  
  // Don't forget to update widget_test.dart
  final widgetTestFile = File('test/widget_test.dart');
  if (await widgetTestFile.exists()) {
    await updateImportsInFile(widgetTestFile);
  }
  
  print('Import replacement complete.');
}

Future<void> updateImportsInDirectory(Directory directory) async {
  final entities = await directory.list(recursive: true).toList();
  
  for (var entity in entities) {
    if (entity is File && entity.path.endsWith('.dart')) {
      await updateImportsInFile(entity);
    }
  }
}

Future<void> updateImportsInFile(File file) async {
  try {
    String content = await file.readAsString();
    if (content.contains("package:ecom/")) {
      content = content.replaceAll("package:ecom/", "package:gudmerchant/");
      await file.writeAsString(content);
      print('Updated imports in ${file.path}');
    }
  } catch (e) {
    print('Error updating ${file.path}: $e');
  }
} 