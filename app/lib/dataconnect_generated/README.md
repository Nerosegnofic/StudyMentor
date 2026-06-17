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


### GetStudentOwnedItems
#### Required Arguments
```dart
String studentUid = ...;
ExampleConnector.instance.getStudentOwnedItems(
  studentUid: studentUid,
).execute();
```



#### Return Type
`execute()` returns a `QueryResult<GetStudentOwnedItemsData, GetStudentOwnedItemsVariables>`
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

final result = await ExampleConnector.instance.getStudentOwnedItems(
  studentUid: studentUid,
);
GetStudentOwnedItemsData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String studentUid = ...;

final ref = ExampleConnector.instance.getStudentOwnedItems(
  studentUid: studentUid,
).ref();
ref.execute();

ref.subscribe(...);
```


### GetStudentAvatar
#### Required Arguments
```dart
String studentUid = ...;
ExampleConnector.instance.getStudentAvatar(
  studentUid: studentUid,
).execute();
```



#### Return Type
`execute()` returns a `QueryResult<GetStudentAvatarData, GetStudentAvatarVariables>`
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

final result = await ExampleConnector.instance.getStudentAvatar(
  studentUid: studentUid,
);
GetStudentAvatarData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String studentUid = ...;

final ref = ExampleConnector.instance.getStudentAvatar(
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


### GetUnreadLocalNotificationEvents
#### Required Arguments
```dart
String toParentUid = ...;
ExampleConnector.instance.getUnreadLocalNotificationEvents(
  toParentUid: toParentUid,
).execute();
```



#### Return Type
`execute()` returns a `QueryResult<GetUnreadLocalNotificationEventsData, GetUnreadLocalNotificationEventsVariables>`
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

final result = await ExampleConnector.instance.getUnreadLocalNotificationEvents(
  toParentUid: toParentUid,
);
GetUnreadLocalNotificationEventsData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String toParentUid = ...;

final ref = ExampleConnector.instance.getUnreadLocalNotificationEvents(
  toParentUid: toParentUid,
).ref();
ref.execute();

ref.subscribe(...);
```


### GetLocalNotificationPreferences
#### Required Arguments
```dart
String userUid = ...;
ExampleConnector.instance.getLocalNotificationPreferences(
  userUid: userUid,
).execute();
```



#### Return Type
`execute()` returns a `QueryResult<GetLocalNotificationPreferencesData, GetLocalNotificationPreferencesVariables>`
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

final result = await ExampleConnector.instance.getLocalNotificationPreferences(
  userUid: userUid,
);
GetLocalNotificationPreferencesData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String userUid = ...;

final ref = ExampleConnector.instance.getLocalNotificationPreferences(
  userUid: userUid,
).ref();
ref.execute();

ref.subscribe(...);
```

## Mutations

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
Role role = ...;
ExampleConnector.instance.upsertCurrentUser(
  role: role,
).execute();
```

#### Optional Arguments
We return a builder for each query. For UpsertCurrentUser, we created `UpsertCurrentUserBuilder`. For queries and mutations with optional parameters, we return a builder class.
The builder pattern allows Data Connect to distinguish between fields that haven't been set and fields that have been set to null. A field can be set by calling its respective setter method like below:
```dart
class UpsertCurrentUserVariablesBuilder {
  ...
 
  UpsertCurrentUserVariablesBuilder email(String? t) {
   _email.value = t;
   return this;
  }
  UpsertCurrentUserVariablesBuilder fullName(String? t) {
   _fullName.value = t;
   return this;
  }

  ...
}
ExampleConnector.instance.upsertCurrentUser(
  role: role,
)
.email(email)
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
  role: role,
);
UpsertCurrentUserData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
Role role = ...;

final ref = ExampleConnector.instance.upsertCurrentUser(
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
   InsertAppRuleVariablesBuilder isPaused(bool? t) {
   _isPaused.value = t;
   return this;
  }

  ...
}
ExampleConnector.instance.insertAppRule(
  studentUid: studentUid,
  packageName: packageName,
  appLabel: appLabel,
)
.isPaused(isPaused)
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


### InsertStudentOwnedItem
#### Required Arguments
```dart
String studentUid = ...;
String itemId = ...;
ExampleConnector.instance.insertStudentOwnedItem(
  studentUid: studentUid,
  itemId: itemId,
).execute();
```



#### Return Type
`execute()` returns a `OperationResult<InsertStudentOwnedItemData, InsertStudentOwnedItemVariables>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

final result = await ExampleConnector.instance.insertStudentOwnedItem(
  studentUid: studentUid,
  itemId: itemId,
);
InsertStudentOwnedItemData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String studentUid = ...;
String itemId = ...;

final ref = ExampleConnector.instance.insertStudentOwnedItem(
  studentUid: studentUid,
  itemId: itemId,
).ref();
ref.execute();
```


### UpsertStudentAvatar
#### Required Arguments
```dart
String studentUid = ...;
String gender = ...;
String skinTone = ...;
ExampleConnector.instance.upsertStudentAvatar(
  studentUid: studentUid,
  gender: gender,
  skinTone: skinTone,
).execute();
```

#### Optional Arguments
We return a builder for each query. For UpsertStudentAvatar, we created `UpsertStudentAvatarBuilder`. For queries and mutations with optional parameters, we return a builder class.
The builder pattern allows Data Connect to distinguish between fields that haven't been set and fields that have been set to null. A field can be set by calling its respective setter method like below:
```dart
class UpsertStudentAvatarVariablesBuilder {
  ...
   UpsertStudentAvatarVariablesBuilder equippedHair(String? t) {
   _equippedHair.value = t;
   return this;
  }
  UpsertStudentAvatarVariablesBuilder equippedOutfit(String? t) {
   _equippedOutfit.value = t;
   return this;
  }
  UpsertStudentAvatarVariablesBuilder equippedBottom(String? t) {
   _equippedBottom.value = t;
   return this;
  }
  UpsertStudentAvatarVariablesBuilder equippedShoes(String? t) {
   _equippedShoes.value = t;
   return this;
  }
  UpsertStudentAvatarVariablesBuilder equippedAccessory(String? t) {
   _equippedAccessory.value = t;
   return this;
  }
  UpsertStudentAvatarVariablesBuilder equippedBackground(String? t) {
   _equippedBackground.value = t;
   return this;
  }
  UpsertStudentAvatarVariablesBuilder equippedSpecial(String? t) {
   _equippedSpecial.value = t;
   return this;
  }
  UpsertStudentAvatarVariablesBuilder avatarConfig(String? t) {
   _avatarConfig.value = t;
   return this;
  }

  ...
}
ExampleConnector.instance.upsertStudentAvatar(
  studentUid: studentUid,
  gender: gender,
  skinTone: skinTone,
)
.equippedHair(equippedHair)
.equippedOutfit(equippedOutfit)
.equippedBottom(equippedBottom)
.equippedShoes(equippedShoes)
.equippedAccessory(equippedAccessory)
.equippedBackground(equippedBackground)
.equippedSpecial(equippedSpecial)
.avatarConfig(avatarConfig)
.execute();
```

#### Return Type
`execute()` returns a `OperationResult<UpsertStudentAvatarData, UpsertStudentAvatarVariables>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

final result = await ExampleConnector.instance.upsertStudentAvatar(
  studentUid: studentUid,
  gender: gender,
  skinTone: skinTone,
);
UpsertStudentAvatarData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String studentUid = ...;
String gender = ...;
String skinTone = ...;

final ref = ExampleConnector.instance.upsertStudentAvatar(
  studentUid: studentUid,
  gender: gender,
  skinTone: skinTone,
).ref();
ref.execute();
```


### DeleteAllOwnedItemsForStudent
#### Required Arguments
```dart
String studentUid = ...;
ExampleConnector.instance.deleteAllOwnedItemsForStudent(
  studentUid: studentUid,
).execute();
```



#### Return Type
`execute()` returns a `OperationResult<DeleteAllOwnedItemsForStudentData, DeleteAllOwnedItemsForStudentVariables>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

final result = await ExampleConnector.instance.deleteAllOwnedItemsForStudent(
  studentUid: studentUid,
);
DeleteAllOwnedItemsForStudentData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String studentUid = ...;

final ref = ExampleConnector.instance.deleteAllOwnedItemsForStudent(
  studentUid: studentUid,
).ref();
ref.execute();
```


### DeleteStudentAvatar
#### Required Arguments
```dart
String studentUid = ...;
ExampleConnector.instance.deleteStudentAvatar(
  studentUid: studentUid,
).execute();
```



#### Return Type
`execute()` returns a `OperationResult<DeleteStudentAvatarData, DeleteStudentAvatarVariables>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

final result = await ExampleConnector.instance.deleteStudentAvatar(
  studentUid: studentUid,
);
DeleteStudentAvatarData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String studentUid = ...;

final ref = ExampleConnector.instance.deleteStudentAvatar(
  studentUid: studentUid,
).ref();
ref.execute();
```


### DeleteStudentSettings
#### Required Arguments
```dart
String studentUid = ...;
ExampleConnector.instance.deleteStudentSettings(
  studentUid: studentUid,
).execute();
```



#### Return Type
`execute()` returns a `OperationResult<DeleteStudentSettingsData, DeleteStudentSettingsVariables>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

final result = await ExampleConnector.instance.deleteStudentSettings(
  studentUid: studentUid,
);
DeleteStudentSettingsData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String studentUid = ...;

final ref = ExampleConnector.instance.deleteStudentSettings(
  studentUid: studentUid,
).ref();
ref.execute();
```


### DeleteStudentConfig
#### Required Arguments
```dart
String studentUid = ...;
ExampleConnector.instance.deleteStudentConfig(
  studentUid: studentUid,
).execute();
```



#### Return Type
`execute()` returns a `OperationResult<DeleteStudentConfigData, DeleteStudentConfigVariables>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

final result = await ExampleConnector.instance.deleteStudentConfig(
  studentUid: studentUid,
);
DeleteStudentConfigData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String studentUid = ...;

final ref = ExampleConnector.instance.deleteStudentConfig(
  studentUid: studentUid,
).ref();
ref.execute();
```


### DeleteStudentRecord
#### Required Arguments
```dart
String uid = ...;
ExampleConnector.instance.deleteStudentRecord(
  uid: uid,
).execute();
```



#### Return Type
`execute()` returns a `OperationResult<DeleteStudentRecordData, DeleteStudentRecordVariables>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

final result = await ExampleConnector.instance.deleteStudentRecord(
  uid: uid,
);
DeleteStudentRecordData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String uid = ...;

final ref = ExampleConnector.instance.deleteStudentRecord(
  uid: uid,
).ref();
ref.execute();
```


### DeleteUserRecord
#### Required Arguments
```dart
String uid = ...;
ExampleConnector.instance.deleteUserRecord(
  uid: uid,
).execute();
```



#### Return Type
`execute()` returns a `OperationResult<DeleteUserRecordData, DeleteUserRecordVariables>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

final result = await ExampleConnector.instance.deleteUserRecord(
  uid: uid,
);
DeleteUserRecordData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String uid = ...;

final ref = ExampleConnector.instance.deleteUserRecord(
  uid: uid,
).ref();
ref.execute();
```


### UpdateStudentFullName
#### Required Arguments
```dart
String uid = ...;
String fullName = ...;
ExampleConnector.instance.updateStudentFullName(
  uid: uid,
  fullName: fullName,
).execute();
```



#### Return Type
`execute()` returns a `OperationResult<UpdateStudentFullNameData, UpdateStudentFullNameVariables>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

final result = await ExampleConnector.instance.updateStudentFullName(
  uid: uid,
  fullName: fullName,
);
UpdateStudentFullNameData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String uid = ...;
String fullName = ...;

final ref = ExampleConnector.instance.updateStudentFullName(
  uid: uid,
  fullName: fullName,
).ref();
ref.execute();
```


### UpdateStudentLastActiveAt
#### Required Arguments
```dart
// No required arguments
ExampleConnector.instance.updateStudentLastActiveAt().execute();
```



#### Return Type
`execute()` returns a `OperationResult<UpdateStudentLastActiveAtData, void>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

final result = await ExampleConnector.instance.updateStudentLastActiveAt();
UpdateStudentLastActiveAtData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
final ref = ExampleConnector.instance.updateStudentLastActiveAt().ref();
ref.execute();
```


### DeleteParentRecord
#### Required Arguments
```dart
// No required arguments
ExampleConnector.instance.deleteParentRecord().execute();
```



#### Return Type
`execute()` returns a `OperationResult<DeleteParentRecordData, void>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

final result = await ExampleConnector.instance.deleteParentRecord();
DeleteParentRecordData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
final ref = ExampleConnector.instance.deleteParentRecord().ref();
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
String quizCount = ...;
ExampleConnector.instance.upsertStudentConfig(
  studentUid: studentUid,
  usageHours: usageHours,
  usageMinutes: usageMinutes,
  cooldownHours: cooldownHours,
  cooldownMinutes: cooldownMinutes,
  quizCount: quizCount,
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
  quizCount: quizCount,
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
String quizCount = ...;

final ref = ExampleConnector.instance.upsertStudentConfig(
  studentUid: studentUid,
  usageHours: usageHours,
  usageMinutes: usageMinutes,
  cooldownHours: cooldownHours,
  cooldownMinutes: cooldownMinutes,
  quizCount: quizCount,
).ref();
ref.execute();
```


### InsertLocalNotificationEvent
#### Required Arguments
```dart
String fromStudentUid = ...;
String toParentUid = ...;
String eventType = ...;
String payload = ...;
ExampleConnector.instance.insertLocalNotificationEvent(
  fromStudentUid: fromStudentUid,
  toParentUid: toParentUid,
  eventType: eventType,
  payload: payload,
).execute();
```



#### Return Type
`execute()` returns a `OperationResult<InsertLocalNotificationEventData, InsertLocalNotificationEventVariables>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

final result = await ExampleConnector.instance.insertLocalNotificationEvent(
  fromStudentUid: fromStudentUid,
  toParentUid: toParentUid,
  eventType: eventType,
  payload: payload,
);
InsertLocalNotificationEventData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String fromStudentUid = ...;
String toParentUid = ...;
String eventType = ...;
String payload = ...;

final ref = ExampleConnector.instance.insertLocalNotificationEvent(
  fromStudentUid: fromStudentUid,
  toParentUid: toParentUid,
  eventType: eventType,
  payload: payload,
).ref();
ref.execute();
```


### MarkLocalNotificationEventsRead
#### Required Arguments
```dart
String eventIds = ...;
ExampleConnector.instance.markLocalNotificationEventsRead(
  eventIds: eventIds,
).execute();
```



#### Return Type
`execute()` returns a `OperationResult<MarkLocalNotificationEventsReadData, MarkLocalNotificationEventsReadVariables>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

final result = await ExampleConnector.instance.markLocalNotificationEventsRead(
  eventIds: eventIds,
);
MarkLocalNotificationEventsReadData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String eventIds = ...;

final ref = ExampleConnector.instance.markLocalNotificationEventsRead(
  eventIds: eventIds,
).ref();
ref.execute();
```


### UpsertLocalNotificationPreference
#### Required Arguments
```dart
String userUid = ...;
String category = ...;
bool enabled = ...;
ExampleConnector.instance.upsertLocalNotificationPreference(
  userUid: userUid,
  category: category,
  enabled: enabled,
).execute();
```

#### Optional Arguments
We return a builder for each query. For UpsertLocalNotificationPreference, we created `UpsertLocalNotificationPreferenceBuilder`. For queries and mutations with optional parameters, we return a builder class.
The builder pattern allows Data Connect to distinguish between fields that haven't been set and fields that have been set to null. A field can be set by calling its respective setter method like below:
```dart
class UpsertLocalNotificationPreferenceVariablesBuilder {
  ...
   UpsertLocalNotificationPreferenceVariablesBuilder reminderTime(String? t) {
   _reminderTime.value = t;
   return this;
  }

  ...
}
ExampleConnector.instance.upsertLocalNotificationPreference(
  userUid: userUid,
  category: category,
  enabled: enabled,
)
.reminderTime(reminderTime)
.execute();
```

#### Return Type
`execute()` returns a `OperationResult<UpsertLocalNotificationPreferenceData, UpsertLocalNotificationPreferenceVariables>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

final result = await ExampleConnector.instance.upsertLocalNotificationPreference(
  userUid: userUid,
  category: category,
  enabled: enabled,
);
UpsertLocalNotificationPreferenceData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String userUid = ...;
String category = ...;
bool enabled = ...;

final ref = ExampleConnector.instance.upsertLocalNotificationPreference(
  userUid: userUid,
  category: category,
  enabled: enabled,
).ref();
ref.execute();
```


### DeleteLocalNotificationPreferencesForUser
#### Required Arguments
```dart
String userUid = ...;
ExampleConnector.instance.deleteLocalNotificationPreferencesForUser(
  userUid: userUid,
).execute();
```



#### Return Type
`execute()` returns a `OperationResult<DeleteLocalNotificationPreferencesForUserData, DeleteLocalNotificationPreferencesForUserVariables>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

final result = await ExampleConnector.instance.deleteLocalNotificationPreferencesForUser(
  userUid: userUid,
);
DeleteLocalNotificationPreferencesForUserData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String userUid = ...;

final ref = ExampleConnector.instance.deleteLocalNotificationPreferencesForUser(
  userUid: userUid,
).ref();
ref.execute();
```

