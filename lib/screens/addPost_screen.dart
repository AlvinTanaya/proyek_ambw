import 'package:flutter/material.dart';
import 'base_screen.dart';

class AddPostScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text('Add Post Screen'),
      ),
      bottomNavigationBar: BaseScreen(currentIndex: 2),
    );
  }
}
