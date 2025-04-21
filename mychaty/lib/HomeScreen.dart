import 'package:flutter/material.dart';
import 'package:mychaty/methods.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Home Screen"),
        centerTitle: true,
        backgroundColor: Colors.blueAccent,
      ),
      body: Center(
        child: TextButton(
          onPressed: () => logOut(context), 
          child: Text("LogOut")
        ),
      ),
    );
  }
}