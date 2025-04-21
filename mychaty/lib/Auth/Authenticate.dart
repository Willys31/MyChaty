import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:mychaty/Screens/HomeScreen.dart';
import 'package:mychaty/Auth/LoginScreen.dart';

class Authenticate extends StatelessWidget {
  
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) {
    if(_auth.currentUser != null){
      return HomeScreen();
    }else{
      return LoginScreen();
    }
  }
}