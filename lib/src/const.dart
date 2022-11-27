const allUsersDesktopEntryInstallationDirectoryPath = '/usr/share/applications/';
const ubuntuDesktopEntryInstallationDirectoryPath = '/usr/share/ubuntu/applications';
// WARNING: When using Context.join,
// If a part is an absolute path, then anything before that will be ignored:
// context.join('path', '/to', 'foo'); // -> '/to/foo'.
// It is for this reason that there is no slash at the beginning of this string.
const localUserDesktopEntryInstallationDirectoryPath = '.local/share/applications/';
const localDbusServiceInstallationDirectoryPath = '.local/share/dbus-1/services/';