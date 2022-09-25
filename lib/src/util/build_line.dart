buildListLine(String key, List<String> values) {
  StringBuffer line = StringBuffer("");
  line.write('$key=');

  for (var element in values) {
    // Escape semi-colons if they are present in the value
    final escapedLine = element.replaceAll(';', r'\;');
    line.write('$escapedLine;');

    if (element == values.last) {
      line.write('\n');
    }
  }
  return line.toString();
}

buildLine(String key, [String? value]) {
  if (value is! String) {
    return '$key\n';
  }

  return '$key=$value\n';
}