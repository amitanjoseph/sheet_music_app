import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sheet_music_app/tab_pages/files.dart';
import 'package:sheet_music_app/tab_pages/home.dart';
import 'package:sheet_music_app/tab_pages/scan.dart';
import 'package:sheet_music_app/tab_pages/view.dart';

import 'state.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(statusBarColor: Colors.transparent));
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(const SheetMusicApp());
}

//The class describing the main app
class SheetMusicApp extends StatelessWidget {
  const SheetMusicApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    //Use Material Design based App
    return ProviderScope(
      child: MaterialApp(
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
        home: const TabBar(),
      ),
    );
  }
}

//Each of the tabs
enum AppPages {
  homeTab,
  filesTab,
  scanTab,
  viewTab,
}

//Tab controller
class TabBar extends ConsumerWidget {
  const TabBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    //Updates the current page when needed
    final currentPage = ref.watch(currentPageProvider);
    return Scaffold(
        //Sets tab bar at bottom
        bottomNavigationBar: NavigationBar(
          onDestinationSelected: (int index) {
            ref.read(currentPageProvider.notifier).state =
                AppPages.values[index];
          },
          //Show highlight on currrent selected page
          selectedIndex: currentPage.index,
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
        //The tab contents that will be displayed
        body: [
          const HomeTab(),
          const FileTab(),
          const ScanTab(),
          const ViewTab(),
        ][currentPage.index]);
  }
}
