# Basic Usage

```dart
ExampleConnector.instance.GetUserByUid(getUserByUidVariables).execute();
ExampleConnector.instance.GetStudentsByParent(getStudentsByParentVariables).execute();
ExampleConnector.instance.GetStudentWithParent(getStudentWithParentVariables).execute();
ExampleConnector.instance.GetInstalledAppsForStudent(getInstalledAppsForStudentVariables).execute();
ExampleConnector.instance.InsertInstalledApp(insertInstalledAppVariables).execute();
ExampleConnector.instance.DeleteAllInstalledAppsForStudent(deleteAllInstalledAppsForStudentVariables).execute();
ExampleConnector.instance.GetStudentProfile(getStudentProfileVariables).execute();
ExampleConnector.instance.GetStudentByUsername(getStudentByUsernameVariables).execute();
ExampleConnector.instance.GetWeeklyLeaderboard().execute();
ExampleConnector.instance.GetStudentByFriendCode(getStudentByFriendCodeVariables).execute();

```

## Optional Fields

Some operations may have optional fields. In these cases, the Flutter SDK exposes a builder method, and will have to be set separately.

Optional fields can be discovered based on classes that have `Optional` object types.

This is an example of a mutation with an optional field:

```dart
await ExampleConnector.instance.UpsertStudentAvatar({ ... })
.equippedHair(...)
.execute();
```

Note: the above example is a mutation, but the same logic applies to query operations as well. Additionally, `createMovie` is an example, and may not be available to the user.

