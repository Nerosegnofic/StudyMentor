# dataconnect_generated SDK

## Installation
```sh
flutter pub get firebase_data_connect
flutterfire configure
```
For more information, see [Flutter for Firebase installation documentation](https://firebase.google.com/docs/data-connect/flutter-sdk#use-core).

## Data Connect instance
Each connector creates a static class, with an instance of the `DataConnect` class that can be used to connect to your Data Connect backend and call operations.

### Connecting to the emulator

```dart
String host = 'localhost'; // or your host name
int port = 9399; // or your port number
ExampleConnector.instance.dataConnect.useDataConnectEmulator(host, port);
```

You can also call queries and mutations by using the connector class.
## Queries

### GetUserByUid
#### Required Arguments
```dart
String uid = ...;
ExampleConnector.instance.getUserByUid(
  uid: uid,
).execute();
```



#### Return Type
`execute()` returns a `QueryResult<GetUserByUidData, GetUserByUidVariables>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

/// Result of a query request. Created to hold extra variables in the future.
class QueryResult<Data, Variables> extends OperationResult<Data, Variables> {
  QueryResult(super.dataConnect, super.data, super.ref);
}

final result = await ExampleConnector.instance.getUserByUid(
  uid: uid,
);
GetUserByUidData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String uid = ...;

final ref = ExampleConnector.instance.getUserByUid(
  uid: uid,
).ref();
ref.execute();

ref.subscribe(...);
```


### GetStudentsByParent
#### Required Arguments
```dart
String parentUid = ...;
ExampleConnector.instance.getStudentsByParent(
  parentUid: parentUid,
).execute();
```



#### Return Type
`execute()` returns a `QueryResult<GetStudentsByParentData, GetStudentsByParentVariables>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

/// Result of a query request. Created to hold extra variables in the future.
class QueryResult<Data, Variables> extends OperationResult<Data, Variables> {
  QueryResult(super.dataConnect, super.data, super.ref);
}

final result = await ExampleConnector.instance.getStudentsByParent(
  parentUid: parentUid,
);
GetStudentsByParentData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String parentUid = ...;

final ref = ExampleConnector.instance.getStudentsByParent(
  parentUid: parentUid,
).ref();
ref.execute();

ref.subscribe(...);
```


### GetStudentWithParent
#### Required Arguments
```dart
String uid = ...;
ExampleConnector.instance.getStudentWithParent(
  uid: uid,
).execute();
```



#### Return Type
`execute()` returns a `QueryResult<GetStudentWithParentData, GetStudentWithParentVariables>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

/// Result of a query request. Created to hold extra variables in the future.
class QueryResult<Data, Variables> extends OperationResult<Data, Variables> {
  QueryResult(super.dataConnect, super.data, super.ref);
}

final result = await ExampleConnector.instance.getStudentWithParent(
  uid: uid,
);
GetStudentWithParentData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String uid = ...;

final ref = ExampleConnector.instance.getStudentWithParent(
  uid: uid,
).ref();
ref.execute();

ref.subscribe(...);
```


### GetInstalledAppsForStudent
#### Required Arguments
```dart
String studentUid = ...;
ExampleConnector.instance.getInstalledAppsForStudent(
  studentUid: studentUid,
).execute();
```



#### Return Type
`execute()` returns a `QueryResult<GetInstalledAppsForStudentData, GetInstalledAppsForStudentVariables>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

/// Result of a query request. Created to hold extra variables in the future.
class QueryResult<Data, Variables> extends OperationResult<Data, Variables> {
  QueryResult(super.dataConnect, super.data, super.ref);
}

final result = await ExampleConnector.instance.getInstalledAppsForStudent(
  studentUid: studentUid,
);
GetInstalledAppsForStudentData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String studentUid = ...;

final ref = ExampleConnector.instance.getInstalledAppsForStudent(
  studentUid: studentUid,
).ref();
ref.execute();

ref.subscribe(...);
```


### GetStudentProfile
#### Required Arguments
```dart
String uid = ...;
ExampleConnector.instance.getStudentProfile(
  uid: uid,
).execute();
```



#### Return Type
`execute()` returns a `QueryResult<GetStudentProfileData, GetStudentProfileVariables>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

/// Result of a query request. Created to hold extra variables in the future.
class QueryResult<Data, Variables> extends OperationResult<Data, Variables> {
  QueryResult(super.dataConnect, super.data, super.ref);
}

final result = await ExampleConnector.instance.getStudentProfile(
  uid: uid,
);
GetStudentProfileData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String uid = ...;

final ref = ExampleConnector.instance.getStudentProfile(
  uid: uid,
).ref();
ref.execute();

ref.subscribe(...);
```


### GetStudentSettings
#### Required Arguments
```dart
String studentUid = ...;
ExampleConnector.instance.getStudentSettings(
  studentUid: studentUid,
).execute();
```



#### Return Type
`execute()` returns a `QueryResult<GetStudentSettingsData, GetStudentSettingsVariables>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

/// Result of a query request. Created to hold extra variables in the future.
class QueryResult<Data, Variables> extends OperationResult<Data, Variables> {
  QueryResult(super.dataConnect, super.data, super.ref);
}

final result = await ExampleConnector.instance.getStudentSettings(
  studentUid: studentUid,
);
GetStudentSettingsData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String studentUid = ...;

final ref = ExampleConnector.instance.getStudentSettings(
  studentUid: studentUid,
).ref();
ref.execute();

ref.subscribe(...);
```


### GetAppConfigForStudent
#### Required Arguments
```dart
String studentUid = ...;
ExampleConnector.instance.getAppConfigForStudent(
  studentUid: studentUid,
).execute();
```



#### Return Type
`execute()` returns a `QueryResult<GetAppConfigForStudentData, GetAppConfigForStudentVariables>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

/// Result of a query request. Created to hold extra variables in the future.
class QueryResult<Data, Variables> extends OperationResult<Data, Variables> {
  QueryResult(super.dataConnect, super.data, super.ref);
}

final result = await ExampleConnector.instance.getAppConfigForStudent(
  studentUid: studentUid,
);
GetAppConfigForStudentData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String studentUid = ...;

final ref = ExampleConnector.instance.getAppConfigForStudent(
  studentUid: studentUid,
).ref();
ref.execute();

ref.subscribe(...);
```

## Mutations

### InsertUser
#### Required Arguments
```dart
String email = ...;
String fullName = ...;
Role role = ...;
ExampleConnector.instance.insertUser(
  email: email,
  fullName: fullName,
  role: role,
).execute();
```



#### Return Type
`execute()` returns a `OperationResult<InsertUserData, InsertUserVariables>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

final result = await ExampleConnector.instance.insertUser(
  email: email,
  fullName: fullName,
  role: role,
);
InsertUserData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String email = ...;
String fullName = ...;
Role role = ...;

final ref = ExampleConnector.instance.insertUser(
  email: email,
  fullName: fullName,
  role: role,
).ref();
ref.execute();
```


### UpsertCurrentUser
#### Required Arguments
```dart
String email = ...;
Role role = ...;
ExampleConnector.instance.upsertCurrentUser(
  email: email,
  role: role,
).execute();
```

#### Optional Arguments
We return a builder for each query. For UpsertCurrentUser, we created `UpsertCurrentUserBuilder`. For queries and mutations with optional parameters, we return a builder class.
The builder pattern allows Data Connect to distinguish between fields that haven't been set and fields that have been set to null. A field can be set by calling its respective setter method like below:
```dart
class UpsertCurrentUserVariablesBuilder {
  ...
   UpsertCurrentUserVariablesBuilder fullName(String? t) {
   _fullName.value = t;
   return this;
  }

  ...
}
ExampleConnector.instance.upsertCurrentUser(
  email: email,
  role: role,
)
.fullName(fullName)
.execute();
```

#### Return Type
`execute()` returns a `OperationResult<UpsertCurrentUserData, UpsertCurrentUserVariables>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

final result = await ExampleConnector.instance.upsertCurrentUser(
  email: email,
  role: role,
);
UpsertCurrentUserData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String email = ...;
Role role = ...;

final ref = ExampleConnector.instance.upsertCurrentUser(
  email: email,
  role: role,
).ref();
ref.execute();
```


### DeleteUser
#### Required Arguments
```dart
// No required arguments
ExampleConnector.instance.deleteUser().execute();
```



#### Return Type
`execute()` returns a `OperationResult<DeleteUserData, void>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

final result = await ExampleConnector.instance.deleteUser();
DeleteUserData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
final ref = ExampleConnector.instance.deleteUser().ref();
ref.execute();
```


### InsertParent
#### Required Arguments
```dart
// No required arguments
ExampleConnector.instance.insertParent().execute();
```

#### Optional Arguments
We return a builder for each query. For InsertParent, we created `InsertParentBuilder`. For queries and mutations with optional parameters, we return a builder class.
The builder pattern allows Data Connect to distinguish between fields that haven't been set and fields that have been set to null. A field can be set by calling its respective setter method like below:
```dart
class InsertParentVariablesBuilder {
  ...
 
  InsertParentVariablesBuilder pinCode(String? t) {
   _pinCode.value = t;
   return this;
  }
  InsertParentVariablesBuilder phoneNumber(String? t) {
   _phoneNumber.value = t;
   return this;
  }

  ...
}
ExampleConnector.instance.insertParent()
.pinCode(pinCode)
.phoneNumber(phoneNumber)
.execute();
```

#### Return Type
`execute()` returns a `OperationResult<InsertParentData, InsertParentVariables>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

final result = await ExampleConnector.instance.insertParent();
InsertParentData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
final ref = ExampleConnector.instance.insertParent().ref();
ref.execute();
```


### InsertStudent
#### Required Arguments
```dart
String parentUid = ...;
ExampleConnector.instance.insertStudent(
  parentUid: parentUid,
).execute();
```

#### Optional Arguments
We return a builder for each query. For InsertStudent, we created `InsertStudentBuilder`. For queries and mutations with optional parameters, we return a builder class.
The builder pattern allows Data Connect to distinguish between fields that haven't been set and fields that have been set to null. A field can be set by calling its respective setter method like below:
```dart
class InsertStudentVariablesBuilder {
  ...
   InsertStudentVariablesBuilder gradeLevel(int? t) {
   _gradeLevel.value = t;
   return this;
  }

  ...
}
ExampleConnector.instance.insertStudent(
  parentUid: parentUid,
)
.gradeLevel(gradeLevel)
.execute();
```

#### Return Type
`execute()` returns a `OperationResult<InsertStudentData, InsertStudentVariables>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

final result = await ExampleConnector.instance.insertStudent(
  parentUid: parentUid,
);
InsertStudentData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String parentUid = ...;

final ref = ExampleConnector.instance.insertStudent(
  parentUid: parentUid,
).ref();
ref.execute();
```


### SetUserInactive
#### Required Arguments
```dart
// No required arguments
ExampleConnector.instance.setUserInactive().execute();
```



#### Return Type
`execute()` returns a `OperationResult<SetUserInactiveData, void>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

final result = await ExampleConnector.instance.setUserInactive();
SetUserInactiveData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
final ref = ExampleConnector.instance.setUserInactive().ref();
ref.execute();
```


### MarkEmailVerified
#### Required Arguments
```dart
// No required arguments
ExampleConnector.instance.markEmailVerified().execute();
```



#### Return Type
`execute()` returns a `OperationResult<MarkEmailVerifiedData, void>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

final result = await ExampleConnector.instance.markEmailVerified();
MarkEmailVerifiedData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
final ref = ExampleConnector.instance.markEmailVerified().ref();
ref.execute();
```


### InsertAppRule
#### Required Arguments
```dart
String studentUid = ...;
String packageName = ...;
String appLabel = ...;
ExampleConnector.instance.insertAppRule(
  studentUid: studentUid,
  packageName: packageName,
  appLabel: appLabel,
).execute();
```

#### Optional Arguments
We return a builder for each query. For InsertAppRule, we created `InsertAppRuleBuilder`. For queries and mutations with optional parameters, we return a builder class.
The builder pattern allows Data Connect to distinguish between fields that haven't been set and fields that have been set to null. A field can be set by calling its respective setter method like below:
```dart
class InsertAppRuleVariablesBuilder {
  ...
   InsertAppRuleVariablesBuilder iconBase64(String? t) {
   _iconBase64.value = t;
   return this;
  }

  ...
}
ExampleConnector.instance.insertAppRule(
  studentUid: studentUid,
  packageName: packageName,
  appLabel: appLabel,
)
.iconBase64(iconBase64)
.execute();
```

#### Return Type
`execute()` returns a `OperationResult<InsertAppRuleData, InsertAppRuleVariables>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

final result = await ExampleConnector.instance.insertAppRule(
  studentUid: studentUid,
  packageName: packageName,
  appLabel: appLabel,
);
InsertAppRuleData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String studentUid = ...;
String packageName = ...;
String appLabel = ...;

final ref = ExampleConnector.instance.insertAppRule(
  studentUid: studentUid,
  packageName: packageName,
  appLabel: appLabel,
).ref();
ref.execute();
```


### DeleteAllAppRulesForStudent
#### Required Arguments
```dart
String studentUid = ...;
ExampleConnector.instance.deleteAllAppRulesForStudent(
  studentUid: studentUid,
).execute();
```



#### Return Type
`execute()` returns a `OperationResult<DeleteAllAppRulesForStudentData, DeleteAllAppRulesForStudentVariables>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

final result = await ExampleConnector.instance.deleteAllAppRulesForStudent(
  studentUid: studentUid,
);
DeleteAllAppRulesForStudentData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String studentUid = ...;

final ref = ExampleConnector.instance.deleteAllAppRulesForStudent(
  studentUid: studentUid,
).ref();
ref.execute();
```


### UpdateStudentFriendCode
#### Required Arguments
```dart
String friendCode = ...;
ExampleConnector.instance.updateStudentFriendCode(
  friendCode: friendCode,
).execute();
```



#### Return Type
`execute()` returns a `OperationResult<UpdateStudentFriendCodeData, UpdateStudentFriendCodeVariables>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

final result = await ExampleConnector.instance.updateStudentFriendCode(
  friendCode: friendCode,
);
UpdateStudentFriendCodeData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String friendCode = ...;

final ref = ExampleConnector.instance.updateStudentFriendCode(
  friendCode: friendCode,
).ref();
ref.execute();
```


### UpsertStudentSettings
#### Required Arguments
```dart
String studentUid = ...;
bool notificationsEnabled = ...;
bool soundEffectsEnabled = ...;
bool backgroundMusicEnabled = ...;
ExampleConnector.instance.upsertStudentSettings(
  studentUid: studentUid,
  notificationsEnabled: notificationsEnabled,
  soundEffectsEnabled: soundEffectsEnabled,
  backgroundMusicEnabled: backgroundMusicEnabled,
).execute();
```



#### Return Type
`execute()` returns a `OperationResult<UpsertStudentSettingsData, UpsertStudentSettingsVariables>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

final result = await ExampleConnector.instance.upsertStudentSettings(
  studentUid: studentUid,
  notificationsEnabled: notificationsEnabled,
  soundEffectsEnabled: soundEffectsEnabled,
  backgroundMusicEnabled: backgroundMusicEnabled,
);
UpsertStudentSettingsData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String studentUid = ...;
bool notificationsEnabled = ...;
bool soundEffectsEnabled = ...;
bool backgroundMusicEnabled = ...;

final ref = ExampleConnector.instance.upsertStudentSettings(
  studentUid: studentUid,
  notificationsEnabled: notificationsEnabled,
  soundEffectsEnabled: soundEffectsEnabled,
  backgroundMusicEnabled: backgroundMusicEnabled,
).ref();
ref.execute();
```


### InsertSupportTicket
#### Required Arguments
```dart
String userId = ...;
String userName = ...;
String issueType = ...;
String message = ...;
ExampleConnector.instance.insertSupportTicket(
  userId: userId,
  userName: userName,
  issueType: issueType,
  message: message,
).execute();
```



#### Return Type
`execute()` returns a `OperationResult<InsertSupportTicketData, InsertSupportTicketVariables>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

final result = await ExampleConnector.instance.insertSupportTicket(
  userId: userId,
  userName: userName,
  issueType: issueType,
  message: message,
);
InsertSupportTicketData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String userId = ...;
String userName = ...;
String issueType = ...;
String message = ...;

final ref = ExampleConnector.instance.insertSupportTicket(
  userId: userId,
  userName: userName,
  issueType: issueType,
  message: message,
).ref();
ref.execute();
```


### UpsertStudentConfig
#### Required Arguments
```dart
String studentUid = ...;
int usageHours = ...;
int usageMinutes = ...;
int cooldownHours = ...;
int cooldownMinutes = ...;
ExampleConnector.instance.upsertStudentConfig(
  studentUid: studentUid,
  usageHours: usageHours,
  usageMinutes: usageMinutes,
  cooldownHours: cooldownHours,
  cooldownMinutes: cooldownMinutes,
).execute();
```



#### Return Type
`execute()` returns a `OperationResult<UpsertStudentConfigData, UpsertStudentConfigVariables>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

final result = await ExampleConnector.instance.upsertStudentConfig(
  studentUid: studentUid,
  usageHours: usageHours,
  usageMinutes: usageMinutes,
  cooldownHours: cooldownHours,
  cooldownMinutes: cooldownMinutes,
);
UpsertStudentConfigData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String studentUid = ...;
int usageHours = ...;
int usageMinutes = ...;
int cooldownHours = ...;
int cooldownMinutes = ...;

final ref = ExampleConnector.instance.upsertStudentConfig(
  studentUid: studentUid,
  usageHours: usageHours,
  usageMinutes: usageMinutes,
  cooldownHours: cooldownHours,
  cooldownMinutes: cooldownMinutes,
).ref();
ref.execute();
```


### InsertInstalledApp
#### Required Arguments
```dart
String studentUid = ...;
String packageName = ...;
String appLabel = ...;
bool isSystemApp = ...;
ExampleConnector.instance.insertInstalledApp(
  studentUid: studentUid,
  packageName: packageName,
  appLabel: appLabel,
  isSystemApp: isSystemApp,
).execute();
```

#### Optional Arguments
We return a builder for each query. For InsertInstalledApp, we created `InsertInstalledAppBuilder`. For queries and mutations with optional parameters, we return a builder class.
The builder pattern allows Data Connect to distinguish between fields that haven't been set and fields that have been set to null. A field can be set by calling its respective setter method like below:
```dart
class InsertInstalledAppVariablesBuilder {
  ...
   InsertInstalledAppVariablesBuilder iconBase64(String? t) {
   _iconBase64.value = t;
   return this;
  }

  ...
}
ExampleConnector.instance.insertInstalledApp(
  studentUid: studentUid,
  packageName: packageName,
  appLabel: appLabel,
  isSystemApp: isSystemApp,
)
.iconBase64(iconBase64)
.execute();
```

#### Return Type
`execute()` returns a `OperationResult<InsertInstalledAppData, InsertInstalledAppVariables>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

final result = await ExampleConnector.instance.insertInstalledApp(
  studentUid: studentUid,
  packageName: packageName,
  appLabel: appLabel,
  isSystemApp: isSystemApp,
);
InsertInstalledAppData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String studentUid = ...;
String packageName = ...;
String appLabel = ...;
bool isSystemApp = ...;

final ref = ExampleConnector.instance.insertInstalledApp(
  studentUid: studentUid,
  packageName: packageName,
  appLabel: appLabel,
  isSystemApp: isSystemApp,
).ref();
ref.execute();
```


### DeleteAllInstalledAppsForStudent
#### Required Arguments
```dart
String studentUid = ...;
ExampleConnector.instance.deleteAllInstalledAppsForStudent(
  studentUid: studentUid,
).execute();
```



#### Return Type
`execute()` returns a `OperationResult<DeleteAllInstalledAppsForStudentData, DeleteAllInstalledAppsForStudentVariables>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

final result = await ExampleConnector.instance.deleteAllInstalledAppsForStudent(
  studentUid: studentUid,
);
DeleteAllInstalledAppsForStudentData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String studentUid = ...;

final ref = ExampleConnector.instance.deleteAllInstalledAppsForStudent(
  studentUid: studentUid,
).ref();
ref.execute();
```

