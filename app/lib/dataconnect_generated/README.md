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


### GetWeeklyLeaderboard
#### Required Arguments
```dart
// No required arguments
ExampleConnector.instance.getWeeklyLeaderboard().execute();
```



#### Return Type
`execute()` returns a `QueryResult<GetWeeklyLeaderboardData, void>`
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

final result = await ExampleConnector.instance.getWeeklyLeaderboard();
GetWeeklyLeaderboardData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
final ref = ExampleConnector.instance.getWeeklyLeaderboard().ref();
ref.execute();

ref.subscribe(...);
```


### GetStudentByFriendCode
#### Required Arguments
```dart
String friendCode = ...;
ExampleConnector.instance.getStudentByFriendCode(
  friendCode: friendCode,
).execute();
```



#### Return Type
`execute()` returns a `QueryResult<GetStudentByFriendCodeData, GetStudentByFriendCodeVariables>`
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

final result = await ExampleConnector.instance.getStudentByFriendCode(
  friendCode: friendCode,
);
GetStudentByFriendCodeData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String friendCode = ...;

final ref = ExampleConnector.instance.getStudentByFriendCode(
  friendCode: friendCode,
).ref();
ref.execute();

ref.subscribe(...);
```


### GetSentFriendRequests
#### Required Arguments
```dart
String fromStudentUid = ...;
ExampleConnector.instance.getSentFriendRequests(
  fromStudentUid: fromStudentUid,
).execute();
```



#### Return Type
`execute()` returns a `QueryResult<GetSentFriendRequestsData, GetSentFriendRequestsVariables>`
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

final result = await ExampleConnector.instance.getSentFriendRequests(
  fromStudentUid: fromStudentUid,
);
GetSentFriendRequestsData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String fromStudentUid = ...;

final ref = ExampleConnector.instance.getSentFriendRequests(
  fromStudentUid: fromStudentUid,
).ref();
ref.execute();

ref.subscribe(...);
```


### GetFriendsForStudent
#### Required Arguments
```dart
String studentUid = ...;
ExampleConnector.instance.getFriendsForStudent(
  studentUid: studentUid,
).execute();
```



#### Return Type
`execute()` returns a `QueryResult<GetFriendsForStudentData, GetFriendsForStudentVariables>`
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

final result = await ExampleConnector.instance.getFriendsForStudent(
  studentUid: studentUid,
);
GetFriendsForStudentData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String studentUid = ...;

final ref = ExampleConnector.instance.getFriendsForStudent(
  studentUid: studentUid,
).ref();
ref.execute();

ref.subscribe(...);
```


### GetPendingFriendRequestsForParent
#### Required Arguments
```dart
String parentUid = ...;
ExampleConnector.instance.getPendingFriendRequestsForParent(
  parentUid: parentUid,
).execute();
```



#### Return Type
`execute()` returns a `QueryResult<GetPendingFriendRequestsForParentData, GetPendingFriendRequestsForParentVariables>`
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

final result = await ExampleConnector.instance.getPendingFriendRequestsForParent(
  parentUid: parentUid,
);
GetPendingFriendRequestsForParentData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String parentUid = ...;

final ref = ExampleConnector.instance.getPendingFriendRequestsForParent(
  parentUid: parentUid,
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


### GetSiblingLeaderboard
#### Required Arguments
```dart
String parentUid = ...;
ExampleConnector.instance.getSiblingLeaderboard(
  parentUid: parentUid,
).execute();
```



#### Return Type
`execute()` returns a `QueryResult<GetSiblingLeaderboardData, GetSiblingLeaderboardVariables>`
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

final result = await ExampleConnector.instance.getSiblingLeaderboard(
  parentUid: parentUid,
);
GetSiblingLeaderboardData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String parentUid = ...;

final ref = ExampleConnector.instance.getSiblingLeaderboard(
  parentUid: parentUid,
).ref();
ref.execute();

ref.subscribe(...);
```


### GetAllSubjectProgress
#### Required Arguments
```dart
String studentUid = ...;
ExampleConnector.instance.getAllSubjectProgress(
  studentUid: studentUid,
).execute();
```



#### Return Type
`execute()` returns a `QueryResult<GetAllSubjectProgressData, GetAllSubjectProgressVariables>`
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

final result = await ExampleConnector.instance.getAllSubjectProgress(
  studentUid: studentUid,
);
GetAllSubjectProgressData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String studentUid = ...;

final ref = ExampleConnector.instance.getAllSubjectProgress(
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
String username = ...;
ExampleConnector.instance.insertStudent(
  parentUid: parentUid,
  username: username,
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
  username: username,
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
  username: username,
);
InsertStudentData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String parentUid = ...;
String username = ...;

final ref = ExampleConnector.instance.insertStudent(
  parentUid: parentUid,
  username: username,
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


### UpdateLastActiveAt
#### Required Arguments
```dart
// No required arguments
ExampleConnector.instance.updateLastActiveAt().execute();
```



#### Return Type
`execute()` returns a `OperationResult<UpdateLastActiveAtData, void>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

final result = await ExampleConnector.instance.updateLastActiveAt();
UpdateLastActiveAtData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
final ref = ExampleConnector.instance.updateLastActiveAt().ref();
ref.execute();
```


### SendFriendRequest
#### Required Arguments
```dart
String fromStudentUid = ...;
String toFriendCode = ...;
String toStudentUid = ...;
String toStudentName = ...;
ExampleConnector.instance.sendFriendRequest(
  fromStudentUid: fromStudentUid,
  toFriendCode: toFriendCode,
  toStudentUid: toStudentUid,
  toStudentName: toStudentName,
).execute();
```



#### Return Type
`execute()` returns a `OperationResult<SendFriendRequestData, SendFriendRequestVariables>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

final result = await ExampleConnector.instance.sendFriendRequest(
  fromStudentUid: fromStudentUid,
  toFriendCode: toFriendCode,
  toStudentUid: toStudentUid,
  toStudentName: toStudentName,
);
SendFriendRequestData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String fromStudentUid = ...;
String toFriendCode = ...;
String toStudentUid = ...;
String toStudentName = ...;

final ref = ExampleConnector.instance.sendFriendRequest(
  fromStudentUid: fromStudentUid,
  toFriendCode: toFriendCode,
  toStudentUid: toStudentUid,
  toStudentName: toStudentName,
).ref();
ref.execute();
```


### CreateFriendship
#### Required Arguments
```dart
String studentUid = ...;
String friendUid = ...;
ExampleConnector.instance.createFriendship(
  studentUid: studentUid,
  friendUid: friendUid,
).execute();
```



#### Return Type
`execute()` returns a `OperationResult<CreateFriendshipData, CreateFriendshipVariables>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

final result = await ExampleConnector.instance.createFriendship(
  studentUid: studentUid,
  friendUid: friendUid,
);
CreateFriendshipData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String studentUid = ...;
String friendUid = ...;

final ref = ExampleConnector.instance.createFriendship(
  studentUid: studentUid,
  friendUid: friendUid,
).ref();
ref.execute();
```


### RemoveFriend
#### Required Arguments
```dart
String id = ...;
ExampleConnector.instance.removeFriend(
  id: id,
).execute();
```



#### Return Type
`execute()` returns a `OperationResult<RemoveFriendData, RemoveFriendVariables>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

final result = await ExampleConnector.instance.removeFriend(
  id: id,
);
RemoveFriendData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String id = ...;

final ref = ExampleConnector.instance.removeFriend(
  id: id,
).ref();
ref.execute();
```


### UpdateFriendRequestStatus
#### Required Arguments
```dart
String id = ...;
String status = ...;
ExampleConnector.instance.updateFriendRequestStatus(
  id: id,
  status: status,
).execute();
```



#### Return Type
`execute()` returns a `OperationResult<UpdateFriendRequestStatusData, UpdateFriendRequestStatusVariables>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

final result = await ExampleConnector.instance.updateFriendRequestStatus(
  id: id,
  status: status,
);
UpdateFriendRequestStatusData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String id = ...;
String status = ...;

final ref = ExampleConnector.instance.updateFriendRequestStatus(
  id: id,
  status: status,
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


### UpdateStudentCoins
#### Required Arguments
```dart
int totalCoins = ...;
ExampleConnector.instance.updateStudentCoins(
  totalCoins: totalCoins,
).execute();
```



#### Return Type
`execute()` returns a `OperationResult<UpdateStudentCoinsData, UpdateStudentCoinsVariables>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

final result = await ExampleConnector.instance.updateStudentCoins(
  totalCoins: totalCoins,
);
UpdateStudentCoinsData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
int totalCoins = ...;

final ref = ExampleConnector.instance.updateStudentCoins(
  totalCoins: totalCoins,
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


### UpdateStudentXpAndCoins
#### Required Arguments
```dart
int totalXp = ...;
int weeklyXp = ...;
int totalCoins = ...;
int totalQuestionsAnswered = ...;
int currentStreak = ...;
ExampleConnector.instance.updateStudentXpAndCoins(
  totalXp: totalXp,
  weeklyXp: weeklyXp,
  totalCoins: totalCoins,
  totalQuestionsAnswered: totalQuestionsAnswered,
  currentStreak: currentStreak,
).execute();
```



#### Return Type
`execute()` returns a `OperationResult<UpdateStudentXpAndCoinsData, UpdateStudentXpAndCoinsVariables>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

final result = await ExampleConnector.instance.updateStudentXpAndCoins(
  totalXp: totalXp,
  weeklyXp: weeklyXp,
  totalCoins: totalCoins,
  totalQuestionsAnswered: totalQuestionsAnswered,
  currentStreak: currentStreak,
);
UpdateStudentXpAndCoinsData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
int totalXp = ...;
int weeklyXp = ...;
int totalCoins = ...;
int totalQuestionsAnswered = ...;
int currentStreak = ...;

final ref = ExampleConnector.instance.updateStudentXpAndCoins(
  totalXp: totalXp,
  weeklyXp: weeklyXp,
  totalCoins: totalCoins,
  totalQuestionsAnswered: totalQuestionsAnswered,
  currentStreak: currentStreak,
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


### DeleteAllFriendRequestsByStudent
#### Required Arguments
```dart
String studentUid = ...;
ExampleConnector.instance.deleteAllFriendRequestsByStudent(
  studentUid: studentUid,
).execute();
```



#### Return Type
`execute()` returns a `OperationResult<DeleteAllFriendRequestsByStudentData, DeleteAllFriendRequestsByStudentVariables>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

final result = await ExampleConnector.instance.deleteAllFriendRequestsByStudent(
  studentUid: studentUid,
);
DeleteAllFriendRequestsByStudentData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String studentUid = ...;

final ref = ExampleConnector.instance.deleteAllFriendRequestsByStudent(
  studentUid: studentUid,
).ref();
ref.execute();
```


### DeleteAllFriendshipsForStudent
#### Required Arguments
```dart
String studentUid = ...;
ExampleConnector.instance.deleteAllFriendshipsForStudent(
  studentUid: studentUid,
).execute();
```



#### Return Type
`execute()` returns a `OperationResult<DeleteAllFriendshipsForStudentData, DeleteAllFriendshipsForStudentVariables>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

final result = await ExampleConnector.instance.deleteAllFriendshipsForStudent(
  studentUid: studentUid,
);
DeleteAllFriendshipsForStudentData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String studentUid = ...;

final ref = ExampleConnector.instance.deleteAllFriendshipsForStudent(
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


### UpsertSubjectProgress
#### Required Arguments
```dart
String studentUid = ...;
String subjectKey = ...;
int totalXp = ...;
int level = ...;
ExampleConnector.instance.upsertSubjectProgress(
  studentUid: studentUid,
  subjectKey: subjectKey,
  totalXp: totalXp,
  level: level,
).execute();
```



#### Return Type
`execute()` returns a `OperationResult<UpsertSubjectProgressData, UpsertSubjectProgressVariables>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

final result = await ExampleConnector.instance.upsertSubjectProgress(
  studentUid: studentUid,
  subjectKey: subjectKey,
  totalXp: totalXp,
  level: level,
);
UpsertSubjectProgressData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String studentUid = ...;
String subjectKey = ...;
int totalXp = ...;
int level = ...;

final ref = ExampleConnector.instance.upsertSubjectProgress(
  studentUid: studentUid,
  subjectKey: subjectKey,
  totalXp: totalXp,
  level: level,
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

