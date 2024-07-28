import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

final userProvider = FutureProvider<User>((ref) async {
  final box = await Hive.openBox('userBox');
  
  // Retrieve user data from Hive
  final userData = box.get('userData');
  
  // If user data exists in Hive, return it
  if (userData != null) {
    return User.fromJson(userData);
  }
  
  // Otherwise, return a default user object
  return User();
});

class User {
  String name;
  String id = Uuid().v4();
  
  User({this.name = ''});
  
  // Convert user object to JSON
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'id': id,
    };
  }
  
  // Create user object from JSON
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      name: json['name'],
    );
  }
  
  // Save user data to Hive
  void save() {
    final box = Hive.box('userBox');
    box.put('userData', toJson());
  }
}