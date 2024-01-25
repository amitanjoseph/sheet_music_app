import 'package:sqflite/sqflite.dart';

abstract class Model {
  final String table;

  Model(this.table);
  Map<String, Object?> toMap();

  Future<int> insert(Database db) {
    return db.insert(table, toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  @override
  String toString() {
    // ignore: prefer_interpolation_to_compose_strings
    return table + "${toMap()}";
  }
}

class SheetMusicModel extends Model {
  final String name;
  final String file;
  final String? composer;
  final int dateViewed;
  final int dateCreated;
  final String? folder;
  final String keySig;
  final int tempo;

  SheetMusicModel({
    required this.name,
    required this.file,
    required this.composer,
    required this.dateViewed,
    required this.dateCreated,
    required this.folder,
    required this.keySig,
    required this.tempo,
  }) : super("SheetMusic");

  SheetMusicModel.fromMap(Map<String, Object?> map)
      : this(
          name: map["name"] as String,
          file: map["file"] as String,
          composer: map["composer"] as String?,
          dateViewed: map["dateViewed"] as int,
          dateCreated: map["dateCreated"] as int,
          folder: map["folder"] as String?,
          keySig: map["keySignature"] as String,
          tempo: map["tempo"] as int,
        );

  @override
  Map<String, Object?> toMap() {
    return {
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

  @override
  String toString() {
    var map = toMap();
    map["dateViewed"] =
        DateTime.fromMillisecondsSinceEpoch(map["dateViewed"] as int);
    map["dateCreated"] =
        DateTime.fromMillisecondsSinceEpoch(map["dateCreated"] as int);
    return "SheetMusic$map";
  }
}

class ImageModel extends Model {
  final int sheetMusicId;
  final String image;
  final int part;
  final int seqNo;

  ImageModel({
    required this.sheetMusicId,
    required this.image,
    required this.part,
    required this.seqNo,
  }) : super("Images");

  ImageModel.fromMap(Map<String, Object?> map)
      : this(
          sheetMusicId: map["sheetMusicId"] as int,
          image: map["image"] as String,
          part: map["part"] as int,
          seqNo: map["sequenceNumber"] as int,
        );

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
