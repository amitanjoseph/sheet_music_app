import 'package:sqflite/sqflite.dart';

abstract class Model {
  final String database;

  Model(this.database);
  Map<String, Object?> toMap();

  Future<void> insert(Future<Database> database) async {
    final db = await database;

    await db.insert(this.database, toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  @override
  String toString() {
    // ignore: prefer_interpolation_to_compose_strings
    return database + "${toMap()}";
  }
}

class SheetMusic extends Model {
  final int id;
  final String name;
  final String file;
  final String? composer;
  final int dateViewed;
  final int dateCreated;
  final String? folder;
  final String keySig;
  final int tempo;

  SheetMusic({
    required this.id,
    required this.name,
    required this.file,
    required this.composer,
    required this.dateViewed,
    required this.dateCreated,
    required this.folder,
    required this.keySig,
    required this.tempo,
  }) : super("SheetMusic");

  @override
  Map<String, Object?> toMap() {
    return {
      "id": id,
      "name": name,
      "file": file,
      "composer": composer,
      "dateViewed": dateViewed,
      "dateCreated": dateCreated,
      "folder": folder,
      "keySignature": keySig,
      "tempo": tempo,
    };
  }
}

class Image extends Model {
  final int sheetMusicId;
  final String image;
  final int part;
  final int seqNo;

  Image({
    required this.sheetMusicId,
    required this.image,
    required this.part,
    required this.seqNo,
  }) : super("Images");

  @override
  Map<String, Object?> toMap() {
    return {
      "sheetMusicId": sheetMusicId,
      "image": image,
      "part": part,
      "sequenceNumber": seqNo,
    };
  }
}
