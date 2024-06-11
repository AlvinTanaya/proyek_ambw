import 'package:flutter/material.dart';

import 'add_story_image_screen.dart';
import 'add_story_video_screen.dart';
import 'base_screen.dart';

class ChooseStoryUploadTypeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Choose Story Upload Type"),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => AddStoryImageScreen()),
                );
              },
              child: Text('Upload Image Story'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => AddStoryVideoScreen()),
                );
              },
              child: Text('Upload Video Story'),
            ),
          ],
        ),
      ),

    );
  }
}
