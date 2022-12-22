## 1.0.1
* Changed the lint to [package:lints/recommended.yaml].
* Breaking change in the API - a [Directory] must now be provided to the [install...] functions which 
 should be a [Directory] that the process has the capability to write to. This was 
 previously handled by [path_provider] within this package.
* Added Flutter & Flutter tests as [dev_dependencies].

## 1.0.0+1 
* Removed dependency on Flutter. 
* Generated documentation using dart doc. 

## 1.0.0

* Initial release.
  * Support for creating Desktop Entry files at runtime, or parsing from a file.
  * Support for creating DBus Service files at runtime, or parsing from a file.
  * Support for installing Desktop Entry files to the shared user folder.
  * Support for uninstalling Desktop Entry files. 
  * Support for creating DBus Service files at runtime, or parsing from a file.
  * Support for installing DBus Service files to the shared user folder.
  * Support for uninstalling DBus Service files.

