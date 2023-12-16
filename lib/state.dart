//The current open page
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'main.dart';

//State of current open tab
final currentPageProvider = StateProvider((ref) => AppPages.homeTab);

//Variable for storing the newly scanned sheet music
//images before they are saved
final temporarySheetMusicImageProvider = StateProvider((ref) => [<File>[]]);
