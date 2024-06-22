import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'otherUser_screen.dart';
import 'addPost_screen.dart';
import 'marketplace_screen.dart';
import 'profileUser_screen.dart';
import 'add_story_image_screen.dart';
import 'add_story_video_screen.dart';
import 'story_screen.dart';


class BaseScreen extends StatefulWidget {
  const BaseScreen({Key? key, required this.currentIndex}) : super(key: key);

  final int currentIndex;

  @override
  _BaseScreenState createState() => _BaseScreenState();
}

class _BaseScreenState extends State<BaseScreen> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.currentIndex;
    _pageController = PageController(initialPage: _currentIndex);
  }

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
    _pageController.jumpToPage(index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          PageView(
            controller: _pageController,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              HomeScreen(),
              OtherUserScreen(),
              ChooseUploadTypeScreen(),
              MarketPlaceScreen(),
              ProfileUserScreen(),
              AddStoryImageScreen(),
              AddStoryVideoScreen(),
              AddPostImageScreen(),
              AddPostVideoScreen(),
            ],
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: BottomNavigationBar(
              currentIndex: _currentIndex,
              onTap: _onTabTapped,
              selectedItemColor: Colors.black,
              unselectedItemColor: Colors.grey,
              showUnselectedLabels: true,
              items: const [
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
            ),
          ),
        ],
      ),
    );
  }
}
