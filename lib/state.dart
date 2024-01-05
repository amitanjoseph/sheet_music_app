import 'dart:io';
import 'dart:developer' as dev;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sheet_music_app/data_models/models.dart';
import 'package:sheet_music_app/pigeon/scanner.dart';
import 'package:sheet_music_app/utils/music_utils.dart';
import 'package:sqflite/sqflite.dart';

import 'main.dart';

part 'state.g.dart';

//State of current open tab
final currentPageProvider = StateProvider((ref) => AppPages.homeTab);

//Variable for storing the newly scanned sheet music
//images before they are saved
// final temporarySheetMusicImageProvider = StateProvider((ref) => [<File>[]]);

sealed class SheetMusicState {}

class Saved implements SheetMusicState {
  final int sheetMusicId;
  const Saved({required this.sheetMusicId});
}

class Unsaved implements SheetMusicState {
  List<List<File>> images;
  Unsaved({required this.images});
}

@riverpod
class SheetMusic extends _$SheetMusic {
  @override
  SheetMusicState build() {
    dev.log("rebuilt");
    return Unsaved(images: [[]]);
  }

  void setSaved(int id) {
    state = Saved(sheetMusicId: id);
  }

  void addPart() {
    switch (state) {
      case Unsaved(images: final images):
        state = Unsaved(images: images + [[]]);
        dev.log(toString(), name: "add part");
        break;
      case Saved():
        break;
    }
  }

  void addImage(File image) {
    switch (state) {
      case Unsaved(images: final images):
        final List<List<File>> imageCopy =
            List<List<File>>.from(images.map((e) => List<File>.from(e)));
        imageCopy.last.add(image);
        state = Unsaved(images: imageCopy);
        dev.log(toString(), name: "add image");
      case Saved():
        break;
    }
  }

  Future<(List<List<Note>>, List<List<File>>)> getMusic() async {
    dev.log(toString(), name: "HEHHHEHEHEH");
    switch (state) {
      case Unsaved(images: final images):
        return (
          await Future.wait(images.map((part) async {
            return (await Future.wait(part.map((line) async {
              return (await ScannerAPI().scan(line.path));
            })))
                .expand((element) => element.map((e) => e!))
                .toList();
          })),
          images
        );
      case Saved(sheetMusicId: final id):
        final db = await ref
            .listen(
              databaseProvider.future,
              (previous, next) {},
            )
            .read();
        // ignore: non_constant_identifier_names
        final SMNFilePath = (await db.query(
          "SheetMusic",
          columns: ["file"],
          where: "id = ?",
          whereArgs: [id],
        ))[0]["file"] as String;
        final bytes = await File(SMNFilePath).readAsBytes();
        final music = fromSMN(bytes);
        final images = (await db
                .query("Images", where: "sheetMusicId = ?", whereArgs: [id]))
            .map((e) => Image.fromMap(e))
            .toList();
        final List<List<Image>> sortedImages = [];
        for (var i = 0; i < music.length; i++) {
          sortedImages.add([]);
        }
        for (final i in images) {
          sortedImages[i.part].add(i);
        }
        for (final i in sortedImages) {
          i.sort((a, b) => a.seqNo.compareTo(b.seqNo));
        }
        return (
          music,
          sortedImages.map((e) => e.map((i) => File(i.image)).toList()).toList()
        );
    }
  }

  @override
  String toString() {
    switch (state) {
      case Unsaved(images: final images):
        return images.map((i) => i.map((j) => j.path).toString()).toString();
      default:
        return state.toString();
    }
  }
}

final controlsState = StateProvider((ref) => (120, KeySig.C));

@riverpod
Future<Database> database(DatabaseRef ref) async {
  final db = await openDatabase(
    join(await getDatabasesPath(), "sheet_music.db"),
    onCreate: (db, version) async {
      await db.execute(
          "CREATE TABLE SheetMusic(id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL, file TEXT NOT NULL, composer TEXT, dateViewed INTEGER NOT NULL, dateCreated INTEGER NOT NULL, folder TEXT, keySignature TEXT NOT NULL, tempo INTEGER NOT NULL)");
      return db.execute(
          "CREATE TABLE Images(sheetMusicId INTEGER NOT NULL, image TEXT NOT NULL, part INTEGER NOT NULL, sequenceNumber INTEGER NOT NULL, PRIMARY KEY (sheetMusicId, image))");
    },
    version: 1,
  );
  return db;
}
