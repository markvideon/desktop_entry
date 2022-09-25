<!--
This README describes the package. If you publish this package to pub.dev,
this README's contents appear on the landing page for your package.

For information about how to write a good package README, see the guide for
[writing package pages](https://dart.dev/guides/libraries/writing-package-pages).

For general information about developing packages, see the Dart guide for
[creating packages](https://dart.dev/guides/libraries/create-library-packages)
and the Flutter guide for
[developing packages and plugins](https://flutter.dev/developing-packages).
-->

## desktop_entry

[![pub package](https://img.shields.io/pub/v/desktop_entry.svg)](https://pub.dev/packages/desktop_entry)

A Flutter plugin for managing Desktop Entry files (.desktop) on Linux.

## Getting started

Define a Desktop Entry file for your application. If you intend to define a custom scheme, the `MimeType` field of your 
Desktop Entry file should contain `x-scheme-handler/yourScheme` in addition to any other relevant values. 

The contents of an example Desktop Entry file are below, as referenced in the 
[Desktop Entry specification](https://specifications.freedesktop.org/desktop-entry-spec/desktop-entry-spec-latest.html):

```
[Desktop Entry]
Version=1.0
Type=Application
Name=Foo Viewer
Comment=The best viewer for Foo objects available!
TryExec=fooview
Exec=fooview %F
Icon=fooview
MimeType=image/x-foo;
Actions=Gallery;Create;

[Desktop Action Gallery]
Exec=fooview --gallery
Name=Browse Gallery

[Desktop Action Create]
Exec=fooview --create-new
Name=Create a new Foo!
Icon=fooview-new
```

## Usage

### Installing / Uninstalling Desktop Entry files

```
// Example: Generating Desktop Entry file from inside the application itself
//
final desktopEntryFromInsideApp = DesktopEntry(
    type: entryType,
    entryName: entryName,
    exec: string('${Platform.resolvedExecutable} %u')
);


// Example: Generating Desktop Entry file from inside an installer or
//          launcher external to the end user application
//
final uri = Uri.parse(Platform.resolvedExecutable);
final pathToDirectoryComponents = uri.pathSegments
    .sublist(0, uri.pathSegments.length - 1)
    .join('/');
const yourExecName = 'externalFlutterApp';
final validPathToExecutable = '/$pathToDirectoryComponents/$yourExecName';

final desktopEntryFromOutsideApp = DesktopEntry(
    type: entryType,
    entryName: entryName,
    exec: string('$validPathToExecutable %u')
);

// Example: Your application installation flow has created an alias on the
// user's machine.
//
const alias = 'yourAppAlias';

final desktopEntryForAppWithAlias = DesktopEntry(
    type: entryType,
    entryName: entryName,
    exec: string('$alias %u')
);

// Install - filename parameter should not include extension. All Desktop Entry files end in [.desktop].
installFromMemory(entry: entry, filename: filename);

// Uninstall - 
uninstall(File file)

```

### Custom Scheme indicative usage

Use `desktop_entry` in conjunction with [app_links](https://pub.dev/packages/app_links) to support custom schemes on 
all mobile and desktop platforms in Flutter!
```
// e.g. Custom Scheme is fooview://arg1=val1&arg2=val2
const baseScheme = 'fooview';

void main(List<String> arguments) {
    // ...
  
    arguments.forEach((argument) {
      try {
        final uriCandidate = uri.parse(argument);
        
        if (uriCandidate.isScheme(baseScheme)) {
          handleUri(uriCandidate);
        }
      } catch (exception) {
        // Exception is thrown inside [Uri.parse] 
        // if argument is not a valid URI
      }
    });
    
    // ...
}

void handleUri(Uri candidate) {
  // Your application-specific logic.
}
```

## Additional information

`desktop_entry` has been tested on Ubuntu 22.04 LTS. Suggestions for improvements or contributions to improve 
compatibility of the package with other Linux variants, or improve the conformity of the package to the 
[Desktop Entry specification](https://specifications.freedesktop.org/desktop-entry-spec/desktop-entry-spec-latest.html) 
are welcome.