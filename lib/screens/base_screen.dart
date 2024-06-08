import 'package:flutter/material.dart';

import 'addPost_screen.dart';
import 'home_screen.dart';
import 'marketplace_screen.dart';
import 'otherUser_screen.dart';
import 'profileUser_screen.dart';

class BaseScreen extends StatelessWidget {
  final int currentIndex;

  const BaseScreen({Key? key, required this.currentIndex}) : super(key: key);

  void _onTabTapped(BuildContext context, int index) {
    if (index != currentIndex) {
      Widget nextPage;
      switch (index) {
        case 0:
          nextPage = HomeScreen();
          break;
        case 1:
          nextPage = OtherUserScreen();
          break;
        case 2:
          nextPage = AddPostScreen();
          break;
        case 3:
          nextPage = MarketPlaceScreen();
          break;
        case 4:
          nextPage = ProfileUserScreen();
          break;
        default:
          nextPage = HomeScreen();
      }
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => nextPage),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: (index) => _onTabTapped(context, index),
      selectedItemColor: Colors.purple, // Set selected item color to purple
      unselectedItemColor: Colors.black, // Set unselected item color to black
      showUnselectedLabels: true, // Ensure unselected labels are shown
      items: [
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.people),
          label: 'Other Users',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.add),
          label: 'Add Post',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.shopping_cart),
          label: 'Marketplace',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: 'Profile',
        ),
      ],
    );
  }
}
