//The current open page
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'main.dart';

//State of current open tab
final currentPageProvider = StateProvider((ref) => AppPages.homeTab);
