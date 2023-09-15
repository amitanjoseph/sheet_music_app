import 'package:flutter/material.dart';

void main() {
  runApp(const SheetMusicApp());
}

class SheetMusicApp extends StatelessWidget {
  const SheetMusicApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sheet Music App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.lightGreen),
        useMaterial3: true,
      ),
      home: const Scaffold(
        bottomNavigationBar: BottomTabBar(),
      ),
    );
  }
}

class BottomTabBar extends StatefulWidget {
  const BottomTabBar({super.key});

  @override
  State<BottomTabBar> createState() => _BottomTabBarState();
}

class _BottomTabBarState extends State<BottomTabBar> {
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
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Icon(Icons.folder_outlined),
              selectedIcon: Icon(Icons.folder),
              label: 'Files',
            ),
            NavigationDestination(
              icon: Icon(Icons.camera_outlined),
              selectedIcon: Icon(Icons.camera),
              label: 'Scan',
            ),
            NavigationDestination(
              icon: Icon(Icons.note_outlined),
              selectedIcon: Icon(Icons.note),
              label: 'View',
            ),
          ],
          selectedIndex: currentPageIndex,
        ),
        body: [
          const HomeTab(),
          const FileTab(),
          const ScanTab(),
          const ViewTab(),
        ][currentPageIndex]);
  }
}

class HomeTab extends StatelessWidget {
  const HomeTab({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      child: const Text('Page 1'),
    );
  }
}

class FileTab extends StatelessWidget {
  const FileTab({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      child: const Text('Page 2'),
    );
  }
}

class ScanTab extends StatelessWidget {
  const ScanTab({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      child: const Text('Page 3'),
    );
  }
}

class ViewTab extends StatelessWidget {
  const ViewTab({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      child: const Text('Page 4'),
    );
  }
}
