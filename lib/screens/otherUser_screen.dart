import 'package:flutter/material.dart';
import 'base_screen.dart';

class OtherUserScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text('Other Users Screen'),
      ),
      bottomNavigationBar: BaseScreen(currentIndex: 1),
    );
  }
}
