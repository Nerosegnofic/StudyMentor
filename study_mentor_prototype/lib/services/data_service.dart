import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import '../data/data_models.dart';

class DataService {
  Map<String, dynamic> _database = {};

  // --- 1. File Handling & Core Methods (Unchanged) ---
  Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  Future<File> get _localFile async {
    final path = await _localPath;
    return File('$path/data.json');
  }

  Future<void> loadDatabase() async {
    try {
      final file = await _localFile;
      if (await file.exists()) {
        final contents = await file.readAsString();
        if (contents.isNotEmpty) {
          _database = jsonDecode(contents);
        } else {
          await _initializeEmptyDatabase();
        }
      } else {
        await _initializeEmptyDatabase();
      }
    } catch (e) {
      print("Error loading database: $e");
      await _initializeEmptyDatabase();
    }
  }

  Future<void> _initializeEmptyDatabase() async {
    final defaultChild = Child(
      userInfo: User(
        id: 'child1',
        username: 'ahmed',
        password: '456',
        role: UserRole.child,
      ),
      config: ChildConfig(
        grade: 5,
        subjects: ['Math'],
        sessionTimeMinutes: 1,
      ),
      quizzes: [],
      analysis: Analysis(strengths: [], weaknesses: []),
    );

    final defaultParent = Parent(
      userInfo: User(
        id: 'parent1',
        username: 'parent',
        password: '123',
        role: UserRole.parent,
      ),
      childrenIds: [defaultChild.userInfo.id],
    );

    _database = {
      'users': [
        defaultParent.toJson(),
        defaultChild.toJson(),
      ],
      'active_user_id': null,
    };

    await saveDatabase();
  }

  Future<void> saveDatabase() async {
    try {
      final file = await _localFile;
      const encoder = JsonEncoder.withIndent('  ');
      await file.writeAsString(encoder.convert(_database));
    } catch (e) {
      print("Error saving database: $e");
    }
  }

  // --- 2. User & Data Access Methods (Unchanged) ---

  List<Parent> getParents() {
    final users = _database['users'] as List;
    return users
        .where((userJson) => userJson['role'] == 'parent')
        .map((userJson) => Parent.fromJson(userJson))
        .toList();
  }

  List<Child> getChildren() {
    final users = _database['users'] as List;
    return users
        .where((userJson) => userJson['role'] == 'child')
        .map((userJson) => Child.fromJson(userJson))
        .toList();
  }

  Child? getChildById(String childId) {
    final children = getChildren();
    try {
      return children.firstWhere((child) => child.userInfo.id == childId);
    } catch(e) {
      return null; // Return null if not found
    }
  }

  dynamic login(String username, String password) {
    final allUsersJson = _database['users'] as List;
    for (var userJson in allUsersJson) {
      if (userJson['username'] == username && userJson['password'] == password) {
        _database['active_user_id'] = userJson['id'];
        saveDatabase();
        if (userJson['role'] == 'parent') {
          return Parent.fromJson(userJson);
        } else {
          return Child.fromJson(userJson);
        }
      }
    }
    return null;
  }

  void logout() {
    _database['active_user_id'] = null;
    saveDatabase();
  }

  // --- 3. NEW & UPDATED Data Modification Methods ---

  /// Adds a new child and links them to the parent.
  Future<void> addChild(String parentId, Child newChild) async {
    final users = _database['users'] as List;

    users.add(newChild.toJson());

    for (var i = 0; i < users.length; i++) {
      if (users[i]['id'] == parentId && users[i]['role'] == 'parent') {
        final parent = Parent.fromJson(users[i]);
        parent.childrenIds.add(newChild.userInfo.id);
        users[i] = parent.toJson();
        break;
      }
    }

    await saveDatabase();
  }

  /// Updates the configuration for a specific child.
  Future<void> updateChildConfig(String childId, ChildConfig newConfig) async {
    final users = _database['users'] as List;
    for (var i = 0; i < users.length; i++) {
      if (users[i]['id'] == childId) {
        // Create a Child object from the existing data
        final child = Child.fromJson(users[i]);
        // Create a new Child object with the updated config
        final updatedChild = Child(
          userInfo: child.userInfo,
          config: newConfig, // Use the new config
          quizzes: child.quizzes,
          analysis: child.analysis,
        );
        users[i] = updatedChild.toJson();
        break;
      }
    }
    await saveDatabase();
  }

  /// Adds a quiz result to a specific child's record.
  Future<void> addQuizResult(String childId, QuizResult result) async {
    final users = _database['users'] as List;
    for (var i = 0; i < users.length; i++) {
      if (users[i]['id'] == childId) {
        final child = Child.fromJson(users[i]);
        child.quizzes.add(result);
        users[i] = child.toJson();
        break;
      }
    }
    await saveDatabase();
  }

  Future<void> clearDatabaseForTesting() async {
    try {
      final file = await _localFile;
      if (await file.exists()) {
        await file.delete();
        _database = {};
        print("Database cleared successfully.");
      }
    } catch (e) {
      print("Error clearing database: $e");
    }
  }
}