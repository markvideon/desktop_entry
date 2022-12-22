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

A Dart package for managing Desktop Entry files (.desktop) and DBus Service files in Linux 
environments.

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

## Scope

The API at this time handles creation of .desktop specification files and DBus service files, and
installing them to the local user directory. It has been written to the 2020 version of the Desktop 
Entry specification. This library does not perform validation of the various keys to ensure 
correctness at this time. 

However, the choice to implement various types (language concept) that 
correspond to the various 'types' (specification concept) of the specification is a deliberate one, 
intended to make hint that these values are not quite simple strings.


## Additional information

`desktop_entry` has been tested on Ubuntu 22.04 LTS. Suggestions for improvements or contributions to improve 
compatibility of the package with other Linux variants, or improve the conformity of the package to the 
[Desktop Entry specification](https://specifications.freedesktop.org/desktop-entry-spec/desktop-entry-spec-latest.html) 
are welcome.