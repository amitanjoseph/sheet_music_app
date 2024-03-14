import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sheet_music_app/data_models/models.dart';
import 'package:sheet_music_app/pigeon/scanner.dart';
import 'package:sheet_music_app/tab_pages/files.dart' as files;
import 'package:sheet_music_app/utils/music_utils.dart';
import 'package:sqflite/sqflite.dart';

import 'main.dart';

part 'state.g.dart';

//State of current open tab
final currentPageProvider = StateProvider((ref) => AppPages.homeTab);
//Current sheet music sorting order in file tab
final fileOrderingProvider =
    StateProvider((ref) => files.FileOrdering.viewDate);
//Current sheet music filtering in file tab
final filterProvider = StateProvider<files.Filters>((ref) => files.None());

//Parent Class representing the state of the Sheet Music
sealed class SheetMusicState {
  final KeySig keySignature;
  final int tempo;
  const SheetMusicState({required this.keySignature, required this.tempo});
}

//Class representing Sheet Music that was already saved
class Saved extends SheetMusicState {
  final int sheetMusicId;
  const Saved(
      {required this.sheetMusicId,
      required super.keySignature,
      required super.tempo});
}

//Class representing Sheet Music that has hust been captured
class Unsaved extends SheetMusicState {
  final List<List<File>> images;
  Unsaved(
      {required this.images,
      required super.keySignature,
      required super.tempo});
}

//Provider to access Sheet Music
@riverpod
class SheetMusic extends _$SheetMusic {
  //Default to Unsaved Music
  @override
  SheetMusicState build() {
    return Unsaved(images: [[]], keySignature: KeySig.C, tempo: 100);
  }

  //Method to set the state to Saved Sheet Music
  //with previously set Tempo and Key Signature
  Future<void> setSaved(int id) async {
    //Database handle
    final db = await ref.watch(databaseProvider.future);
    //Get Key Signature and Tempo for Sheet Music
    final sheetMusic = (await db.query("SheetMusic",
        columns: ["keySignature", "tempo"],
        where: "id = ?",
        whereArgs: [id]))[0];
    //Set tempo and sheet music
    final tempo = sheetMusic["tempo"] as int;
    final keySig = KeySig.fromString(sheetMusic["keySignature"] as String);
    state = Saved(sheetMusicId: id, tempo: tempo, keySignature: keySig);
  }

  //Return true if state is unsaved, otherwise false
  bool stateIsUnsaved() {
    switch (state) {
      case Unsaved():
        return true;
      case Saved():
        return false;
    }
  }

  //Returns the database id of the sheet music if it was saved (otherwise null)
  int? getSheetMusicId() {
    switch (state) {
      case Unsaved():
        return null;
      case Saved(sheetMusicId: final id):
        return id;
    }
  }

  //Method to add a part to the Unsaved sheet music (when added in the scan tab)
  void addPart() {
    switch (state) {
      case Unsaved(
          images: final images,
          keySignature: final keySig,
          tempo: final tempo
        ):
        //Add the new part (done by adding the empty list, which acts as the new empty list)
        state =
            Unsaved(images: images + [[]], keySignature: keySig, tempo: tempo);
        break;
      case Saved():
        break;
    }
  }

  //Method to add a new image to the current part
  void addImage(File image) {
    switch (state) {
      case Unsaved(
          images: final images,
          keySignature: final keySig,
          tempo: final tempo
        ):
        //Add image to the last part
        images.last.add(image);
        state = Unsaved(images: images, keySignature: keySig, tempo: tempo);
      case Saved():
        break;
    }
  }

  //Get the current tempo and key signature
  (int, KeySig) getTempoAndKeySig() {
    return (state.tempo, state.keySignature);
  }

  //Change the tempo of the piece
  Future<void> setTempo(int tempo) async {
    switch (state) {
      //If it is unsaved, just update the state
      case Unsaved(
          images: final images,
          keySignature: final keySig,
        ):
        state = Unsaved(images: images, keySignature: keySig, tempo: tempo);
      //If it is saved, update the database tempo and current state
      case Saved(sheetMusicId: final id, keySignature: final keySig):
        state = Saved(sheetMusicId: id, keySignature: keySig, tempo: tempo);
        final db = await ref.watch(databaseProvider.future);
        //Get current database info for sheet music
        var model = Map<String, Object?>.from((await db
            .query("SheetMusic", where: "id = ?", whereArgs: [id]))[0]);
        //Update tempo from saved data
        model["tempo"] = tempo.toString();
        //Update database record to have new tempo
        await db.update("SheetMusic", model, where: "id = ?", whereArgs: [id]);
    }
  }

  //Change the key signature of the piece
  Future<void> setKeySig(KeySig keySig) async {
    switch (state) {
      //If it is unsaved, just update the state
      case Unsaved(
          images: final images,
          tempo: final tempo,
        ):
        state = Unsaved(images: images, keySignature: keySig, tempo: tempo);
      //If it is saved, update the database tempo
      case Saved(sheetMusicId: final id, tempo: final tempo):
        state = Saved(sheetMusicId: id, keySignature: keySig, tempo: tempo);
        final db = await ref.watch(databaseProvider.future);
        //Get current database info for sheet music
        var model = Map<String, Object?>.from((await db
            .query("SheetMusic", where: "id = ?", whereArgs: [id]))[0]);
        //Update keySig from saved data
        model["keySignature"] = keySig.toString();
        //Update database record to have new keySig
        await db.update("SheetMusic", model, where: "id = ?", whereArgs: [id]);
    }
  }

  //Returns the music notes and corresponding images, either by
  //analysing the new images or by getting it from the database
  Future<(List<List<Note>>, List<List<File>>)> getMusic() async {
    switch (state) {
      case Unsaved(images: final images):
        //Scan each image and flatten the list to merge the notes into each part
        //Return the 2D list of notes and the images
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
        //Database handle
        final db = await ref.watch(
          databaseProvider.future,
        );
        //Get file path to SMN File
        // ignore: non_constant_identifier_names
        final SMNFilePath = (await db.query(
          "SheetMusic",
          columns: ["file"],
          where: "id = ?",
          whereArgs: [id],
        ))[0]["file"] as String;
        //Read the SMN File bytes
        final bytes = await File(SMNFilePath).readAsBytes();
        //Decompress from bzip2
        final smnBytes = BZip2Decoder().decodeBytes(bytes);
        //Parse SMN bytes into 2D list of notes
        final music = fromSMN(Uint8List.fromList(smnBytes));
        //Read images from database, for the corresponding sheet music
        final images = (await db
                .query("Images", where: "sheetMusicId = ?", whereArgs: [id]))
            .map((e) => ImageModel.fromMap(e))
            .toList();
        //List storing images in correct order
        final List<List<ImageModel>> sortedImages = [];
        //Add empty lists for each part
        for (var i = 0; i < music.length; i++) {
          sortedImages.add([]);
        }
        //Add each image to the correct part
        for (final i in images) {
          sortedImages[i.part].add(i);
        }
        //Sort each image in each part so it displays in correct order
        for (final i in sortedImages) {
          i.sort((a, b) => a.seqNo.compareTo(b.seqNo));
        }
        //Return music and images
        return (
          music,
          sortedImages.map((e) => e.map((i) => File(i.image)).toList()).toList()
        );
    }
  }

  //Useful for debugging: Returns useful information about the current state
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

//Database Provider
@riverpod
Future<Database> database(DatabaseRef ref) async {
  //Open database
  final db = await openDatabase(
    //Path to database
    join(await getDatabasesPath(), "sheet_music.db"),
    //If database does not exist, create the tables
    onCreate: (db, version) async {
      await db.execute(
          "CREATE TABLE SheetMusic(id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL, file TEXT NOT NULL, composer TEXT, dateViewed INTEGER NOT NULL, dateCreated INTEGER NOT NULL, folder TEXT, keySignature TEXT NOT NULL, tempo INTEGER NOT NULL)");
      return db.execute(
          "CREATE TABLE Images(sheetMusicId INTEGER NOT NULL, image TEXT NOT NULL, part INTEGER NOT NULL, sequenceNumber INTEGER NOT NULL, PRIMARY KEY (sheetMusicId, image))");
    },
    version: 1,
  );
  //Return database handler
  return db;
}
