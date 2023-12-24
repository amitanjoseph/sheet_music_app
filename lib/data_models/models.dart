class SheetMusic {
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
  });

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

  @override
  String toString() {
    return "SheetMusic${toMap()}";
  }
}

class Image {
  final int sheetMusicId;
  final String image;
  final int part;
  final int seqNo;

  Image({
    required this.sheetMusicId,
    required this.image,
    required this.part,
    required this.seqNo,
  });

  Map<String, Object?> toMap() {
    return {
      "sheetMusicId": sheetMusicId,
      "image": image,
      "part": part,
      "sequenceNumber": seqNo,
    };
  }

  @override
  String toString() {
    return "Image${toMap()}";
  }
}
