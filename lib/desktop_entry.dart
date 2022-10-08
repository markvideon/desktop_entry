library desktop_entry;

// todo: Verify consistency of the [toData] methods
// todo: Handle the web case
// todo: Example Flutter project
// todo: Exec key - bring closer toward the spec (escaping appropriately etc)
  // Escape equals signs etc as per spec
// todo: Look into infrastructure required to support receiving links while an
//    todo: application is already open
  // - Initial thoughts are that this is likely out of scope for the dependency
// todo: Handle groups that aren't actions
// todo: Comments handling - these should be preserved
// - Each key (and header) should store comments and write them to the class
export 'src/api/api.dart';
export 'src/const.dart';
export 'src/model/desktop_action.dart';
export 'src/model/desktop_contents.dart';
export 'src/model/desktop_entry.dart';
export 'src/model/group_name.dart';
export 'src/model/specification_types.dart';
export 'src/model/unrecognised/unrecognised_entry.dart';
export 'src/model/unrecognised/unrecognised_group.dart';
export 'src/util/util.dart';