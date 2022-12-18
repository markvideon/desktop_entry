# desktop_entry_example

### Custom Scheme indicative usage

You could `desktop_entry` in conjunction with [app_links](https://pub.dev/packages/app_links) to 
support custom schemes on all mobile and desktop platforms in Flutter!

The example project demonstrates this. Using DBus, Desktop Entry files, and a DBus Service file, 
it is possible to have your app handle custom URI schemes. 

The approach in this project: 
- A DBus service is used to allow the application to receive messages - at launch and anytime during
 the session lifecycle.
- An Desktop Entry file for a 'launcher' is created - this is a simple bash script that sends a 
 message to the application via DBus, which activates the first instance if there is no instance 
 active. Custom URI schemes are registered against the launcher, not the application directly.
- A Desktop Entry file for the application is created, to register the DBus service.