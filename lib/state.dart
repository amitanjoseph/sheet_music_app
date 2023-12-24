//The current open page
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sheet_music_app/utils/music_utils.dart';
import 'package:sqflite/sqflite.dart';

import 'main.dart';

part 'state.g.dart';

//State of current open tab
final currentPageProvider = StateProvider((ref) => AppPages.homeTab);

//Variable for storing the newly scanned sheet music
//images before they are saved
final temporarySheetMusicImageProvider = StateProvider((ref) => [<File>[]]);

final controlsState = StateProvider((ref) => (120, KeySig.C));

@riverpod
Future<Database> database(DatabaseRef ref) async {
  final db = await openDatabase(
    join(await getDatabasesPath(), "sheet_music.db"),
    onCreate: (db, version) async {
      await db.execute(
          "CREATE TABLE SheetMusic(id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL, file TEXT NOT NULL, composer TEXT, dateViewed INTEGER NOT NULL, dateCreated INTEGER NOT NULL, folder TEXT, keySignature TEXT NOT NULL, tempo INTEGER NOT NULL)");
      return db.execute(
          "CREATE TABLE Images(sheetMusicId INTEGER NOT NULL, image TEXT NOT NULL, part INTEGER NOT NULL, sequenceNumber INTEGER NOT NULL, PRIMARY KEY (id, image))");
    },
    version: 1,
  );
  return db;
}
