import 'package:flutter/material.dart';

void main() {
  runApp(const SheetMusicApp());
}

//The class describing the main app
class SheetMusicApp extends StatelessWidget {
  const SheetMusicApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    //Use Material Design based App
    return MaterialApp(
      //Set the name of the app window
      title: 'Sheet Music Scanner',
      //Set theme properties that are propogated to all widgets
      theme: ThemeData(
        //Set colourscheme
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.lightGreen),
        //Use Material3 widgets instead of Material2 widgets
        useMaterial3: true,
      ),
      //The start of the widget tree for the actual app
      home: const Scaffold(
        bottomNavigationBar: TabBar(),
      ),
    );
  }
}

//This is the widget that manages the tabs
class TabBar extends StatefulWidget {
  const TabBar({super.key});

  @override
  State<TabBar> createState() => _TabBarState();
}

class _TabBarState extends State<TabBar> {
  int currentPageIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        bottomNavigationBar: NavigationBar(
          onDestinationSelected: (int index) {
            setState(() {
              currentPageIndex = index;
            });
          },
          //The icons and text shown for each tab
          destinations: const [
            //Home Tab
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: 'Home',
            ),
            //Files Tab
            NavigationDestination(
              icon: Icon(Icons.folder_outlined),
              selectedIcon: Icon(Icons.folder),
              label: 'Files',
            ),
            //Scan Tab
            NavigationDestination(
              icon: Icon(Icons.camera_outlined),
              selectedIcon: Icon(Icons.camera),
              label: 'Scan',
            ),
            //View Tab
            NavigationDestination(
              icon: Icon(Icons.note_outlined),
              selectedIcon: Icon(Icons.note),
              label: 'View',
            ),
          ],
        ),
        body: [
          //The tab contents that will be displayed
          const HomeTab(),
          const FileTab(),
          const ScanTab(),
          const ViewTab(),
        ][currentPageIndex]);
  }
}

class HomeTab extends StatelessWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    //Placeholder Content
    return Container(
      alignment: Alignment.center,
      child: const Text('Page 1'),
    );
  }
}

class FileTab extends StatelessWidget {
  const FileTab({super.key});

  @override
  Widget build(BuildContext context) {
    //Placeholder Content
    return Container(
      alignment: Alignment.center,
      child: const Text('Page 2'),
    );
  }
}

class ScanTab extends StatelessWidget {
  const ScanTab({super.key});

  @override
  Widget build(BuildContext context) {
    //Placeholder Content
    return Container(
      alignment: Alignment.center,
      child: const Text('Page 3'),
    );
  }
}

class ViewTab extends StatelessWidget {
  const ViewTab({super.key});

  @override
  Widget build(BuildContext context) {
    //Placeholder Content
    return Container(
      alignment: Alignment.center,
      child: const Text('Page 4'),
    );
  }
}
