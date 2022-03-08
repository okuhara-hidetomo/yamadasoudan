import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class UserState extends ChangeNotifier {
  // FirebaseUserをUserへ変更
  User user;

  void setUser(User newUser) {
    user = newUser;
    notifyListeners();
  }
}
