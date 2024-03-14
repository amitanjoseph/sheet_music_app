import 'package:sqflite/sqflite.dart';

//The base class for models. Defines common methods
abstract class Model {
  //Name of the table - i.e. SheetMusic or Images
  final String table;

  Model(this.table);
  //Method for converting to a map that can be inserted into the database
  Map<String, Object?> toMap();

  //Method that inserts the model into the database
  Future<int> insert(Database db) {
    return db.insert(table, toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  //Default toString
  @override
  String toString() {
    return "$table${toMap()}";
  }
}

//Models for each image
class ImageModel extends Model {
  //Database fields
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

  //Takes a map from the database and converts it into an object to use
  ImageModel.fromMap(Map<String, Object?> map)
      : this(
          sheetMusicId: map["sheetMusicId"] as int,
          image: map["image"] as String,
          part: map["part"] as int,
          seqNo: map["sequenceNumber"] as int,
        );

  //Converts the model into a map that can be inserted into the database
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

//Model for each of piece of sheet music
class SheetMusicModel extends Model {
  //Database Fields
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

  //Takes a map from the database and converts it into an object to use
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

  //Converts the model into a map that can be inserted into the database
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

  //Overrides the toString method so dates are printed as dates not milliseconds from Epoch
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
