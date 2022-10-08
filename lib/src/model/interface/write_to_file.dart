import 'dart:io' if (dart.library.html) 'dart:html' show File;

abstract class FileWritable {
  writeToFile(File file);
}