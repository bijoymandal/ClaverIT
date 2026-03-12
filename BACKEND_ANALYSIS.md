# Backend Analysis: ClaverIT

## Scope and Key Components
- Storage: local SQLite via `sqflite` with `DatabaseHelper` singleton; seeding through `DatabaseSeeder`.
- Contacts: provider-managed in `ContactsProvider`, optional seed data in `contacts_data.dart`.
- Telephony bridge: `NativeCallService` method channel for calls and call-state callbacks.
- Permissions and default dialer: handled centrally in `HomeScreen` via `permission_handler` and a dedicated `MethodChannel`.
- Recents: `RecentScreen` pulls from `call_log` package, renders, and allows swipe-to-clear.

## Contact Sync Pipeline
Files: `lib/providers/contacts_provider.dart`, `lib/data/database_helper.dart`, `lib/data/contacts_data.dart`.

### Flow
1) User action triggers `ContactsProvider.syncDeviceContacts()`.
2) Requests `Permission.contacts`; aborts with `_error` if denied.
3) Fetches device contacts with `flutter_contacts` (properties + phones).
4) Normalizes numbers (digits only) and compares against existing DB entries to avoid duplicates.
5) Inserts new contacts into SQLite via `DatabaseHelper.insertContact`, then reloads provider state.

```dart
// contacts_provider.dart
Future<bool> syncDeviceContacts() async {
  _isSyncing = true; notifyListeners();
  final permission = await Permission.contacts.request();
  if (!permission.isGranted) { _error = 'Contact permission denied'; _isSyncing = false; notifyListeners(); return false; }

  final deviceContacts = await fc.FlutterContacts.getContacts(
    withProperties: true,
    withPhoto: false,
  );

  final existingNumbers = (await _dbHelper.getAllContacts())
      .map((c) => _normalizePhoneNumber(c.phoneNumber))
      .toSet();

  for (var deviceContact in deviceContacts) {
    if (deviceContact.phones.isEmpty) continue;
    final phoneNumber = deviceContact.phones.first.number;
    final normalized = _normalizePhoneNumber(phoneNumber);
    if (existingNumbers.contains(normalized)) continue;

    await _dbHelper.insertContact(Contact(
      name: deviceContact.displayName,
      phoneNumber: phoneNumber,
      designation: deviceContact.organizations.isNotEmpty
          ? deviceContact.organizations.first.title
          : '',
      organization: deviceContact.organizations.isNotEmpty
          ? deviceContact.organizations.first.company
          : '',
      expertise: '',
      location: deviceContact.addresses.isNotEmpty
          ? '${deviceContact.addresses.first.city}, ${deviceContact.addresses.first.state}'
          : '',
      note: deviceContact.notes.isNotEmpty
          ? deviceContact.notes.first.note
          : '',
      profileImagePath: '',
    ));
  }

  await loadContacts();
  _isSyncing = false; notifyListeners();
  return true;
}
```

### Persistence Layer
`DatabaseHelper` opens `pro_dialer.db`, creates `contacts` table, and exposes CRUD plus `getContactByPhone` partial match for incoming-call lookups.

```dart
// database_helper.dart (create + lookup)
await db.execute('''
  CREATE TABLE contacts(
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT,
    phoneNumber TEXT,
    designation TEXT,
    organization TEXT,
    expertise TEXT,
    location TEXT,
    note TEXT,
    profileImagePath TEXT
  )
''');

Future<Contact?> getContactByPhone(String phoneNumber) async {
  final maps = await db.query(
    'contacts',
    where: 'phoneNumber LIKE ?',
    whereArgs: ['%$phoneNumber%'],
  );
  return maps.isNotEmpty ? Contact.fromMap(maps.first) : null;
}
```

### Seeding
`DatabaseSeeder.seedDatabase()` loads `contactsList` from `contacts_data.dart` on first run to populate the DB if empty.

## Default Permission Prompts & Default Dialer Flow
File: `lib/screens/home_screen.dart`.

- Permissions: `_checkAndRequestPermissions()` verifies Phone, Contacts, Microphone. If any missing, requests all; on denial, shows a blocking dialog with retry and Settings deep-link.
- Post-grant hook: `_onPermissionsGranted()` sets `_permissionsGranted` and reloads contacts.
- Default dialer: MethodChannel `com.nighatech.pro_dialer/default_dialer` with `_checkDefaultDialerStatus()` (called on init and on resume) and `_requestDefaultDialer()` to open system picker. App blocks main UI until set as default.

```dart
// home_screen.dart (permission + default dialer)
final phoneStatus = await Permission.phone.status;
final contactsStatus = await Permission.contacts.status;
final micStatus = await Permission.microphone.status;
if (!phoneStatus.isGranted || !contactsStatus.isGranted || !micStatus.isGranted) {
  final statuses = await [Permission.phone, Permission.contacts, Permission.microphone].request();
  if (statuses.values.every((s) => s.isGranted)) {
    await _onPermissionsGranted();
  } else {
    _showPermissionDeniedDialog();
  }
} else {
  await _onPermissionsGranted();
}
_checkDefaultDialerStatus();
...
final bool isDefault = await platform.invokeMethod('isDefaultDialer');
if (!isDefault) _requestDefaultDialer();
```

## Recents Screen Updates
File: `lib/screens/recent_screen.dart`.

- Data source: `call_log` plugin; requests `Permission.phone` before fetching.
- Rendering: list of `CallLogEntry` models (adapter in `call_log_entry.dart` parses types, formats date/duration, selects icon/color).
- UX updates: refresh action, empty/error/permission states, and swipe-to-clear with confirmation + undo snackbar (local list removal; TODO notes about DB if added).
- Call-back: tap phone icon triggers `NativeCallService().startCall()`.

```dart
// recent_screen.dart (loading + swipe-to-clear)
final status = await Permission.phone.request();
if (!status.isGranted) { _permissionDenied = true; _isLoading = false; return; }
final entries = await call_log_package.CallLog.get();
_callLogs = entries.map((e) => CallLogEntry.fromCallLog(e)).toList();
...
return Dismissible(
  key: Key('${log.timestamp}_$index'),
  confirmDismiss: (_) => showDialog(... 'Clear Call Log?'),
  onDismissed: (_) {
    setState(() => _callLogs.removeAt(index));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Call log cleared for ${log.displayName}'), action: SnackBarAction(label: 'UNDO', onPressed: () => setState(() => _callLogs.insert(index, log)))),
    );
  },
  child: _buildCallLogItem(log),
);
```

## Telephony Bridge & Incoming Call Handling
File: `lib/services/native_call_service.dart`.

- MethodChannel `com.example.pro_dialer/call` exposes `startCall`, `answerCall`, `endCall`, `setMuted`, `getCallState`, `getPhoneNumber`, etc., with defensive error handling.
- `init()` registers `incomingCall` and `callStateChanged` callbacks to navigate to `IncomingCallScreen` and pop to root on disconnect.
- Default dialer request helper (`requestDefaultDialer`) and state check (`isDefaultDialer`) for native integration.

```dart
// native_call_service.dart (init + incoming handling)
platform.setMethodCallHandler((call) async {
  switch (call.method) {
    case 'incomingCall':
      await _handleIncomingCall(call.arguments);
      break;
    case 'callStateChanged':
      await _handleCallStateChanged(call.arguments);
      break;
  }
});
...
Future<void> startCall(String phoneNumber) async {
  final ok = await platform.invokeMethod('startCall', {'number': phoneNumber});
  if (!ok) throw Exception('Failed to start call');
}
...
final contactsProvider = Provider.of<ContactsProvider>(_context!, listen: false);
Contact? contact = await contactsProvider.findContactForCall(phoneNumber);
if (contact == null) contact = Contact(name: 'Unknown Number', phoneNumber: phoneNumber, ...);
Navigator.push(context, MaterialPageRoute(builder: (_) => IncomingCallScreen(contact: contact!)));
```

## Models
- `Contact`: DTO with `toMap/fromMap`, helper initials, copyWith; used across DB and UI.
- `CallLogEntry`: adapter around `call_log` entries with type parsing, formatted date/duration, and UI color/icon helpers.

## Notable Gaps / TODOs
- Recents swipe-to-clear only affects in-memory list; no persistent call-log store yet.
- No conflict resolution for contact updates during sync (dedupe only by first phone number normalized).
- Native Android/iOS implementations for method channels are assumed but not present in this repo snapshot.
- README is still Flutter default; consider documenting the flows above.
