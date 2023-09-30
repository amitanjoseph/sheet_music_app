//The current open page
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'main.dart';

//State of current open tab
final currentPageProvider = StateProvider((ref) => AppPages.homeTab);

//Variable for storing the newly scanned sheet music
//images before they are saved
final temporarySheetMusicImages = StateProvider((ref) => [<Image>[]]);
