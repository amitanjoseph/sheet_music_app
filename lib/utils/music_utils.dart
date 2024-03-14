// ignore_for_file: constant_identifier_names

import 'dart:typed_data';
import 'package:quiver/iterables.dart';

import 'package:sheet_music_app/pigeon/scanner.dart';

//The 2 types of key signature and the related sharps and flats
enum KeySigType {
  sharp,
  flat;

  static const sharps = ["F", "C", "G", "D", "A", "E", "B"];
  static const flats = ["B", "E", "A", "D", "G", "C", "F"];
}

//Each key signature, consisting of the type and the number of accidentals
enum KeySig {
  C(KeySigType.sharp, 0),
  G(KeySigType.sharp, 1),
  D(KeySigType.sharp, 2),
  A(KeySigType.sharp, 3),
  E(KeySigType.sharp, 4),
  B(KeySigType.sharp, 5),
  FSharp(KeySigType.sharp, 6),
  CSharp(KeySigType.sharp, 7),
  F(KeySigType.flat, 1),
  BFlat(KeySigType.flat, 2),
  EFlat(KeySigType.flat, 3),
  AFlat(KeySigType.flat, 4),
  DFlat(KeySigType.flat, 5),
  GFlat(KeySigType.flat, 6);

  final KeySigType type;
  final int numberOfAccidentals;

  const KeySig(this.type, this.numberOfAccidentals);

  //Print the Key Signature in a friendly format
  @override
  String toString() {
    if (name.length == 1) {
      return name;
    } else {
      switch (name.substring(1)) {
        case "Sharp":
          return "${name.substring(0, 1)}#";
        case "Flat":
          return "${name.substring(0, 1)}b";
        default:
          throw "Invalid Key Signature";
      }
    }
  }

  //Parse a string key signature to KeySig (for db deserialisation)
  static KeySig fromString(String input) {
    switch (input) {
      case "C":
        return KeySig.C;
      case "G":
        return KeySig.G;
      case "D":
        return KeySig.D;
      case "A":
        return KeySig.A;
      case "E":
        return KeySig.E;
      case "B":
        return KeySig.B;
      case "F#":
        return KeySig.FSharp;
      case "C#":
        return KeySig.CSharp;
      case "F":
        return KeySig.F;
      case "Bb":
        return KeySig.BFlat;
      case "Eb":
        return KeySig.EFlat;
      case "Ab":
        return KeySig.AFlat;
      case "Db":
        return KeySig.DFlat;
      case "Gb":
        return KeySig.GFlat;
      default:
        throw "Cannot convert String to KeySig";
    }
  }
}

//Transpose pitch to the correct key signature
int transposedPitchToMidi(Pitch pitch, KeySig scale) {
  //Get note name and number
  final [note, number] = pitch.name.split('');
  //First few notes and their midi values
  final noteToMidi = {
    "A": 21,
    "B": 23,
    "C": 24,
    "D": 26,
    "E": 28,
    "F": 29,
    "G": 31,
  };

  //Offset from the noteToMidi values
  final offset =
      note != 'A' && note != 'B' ? int.parse(number) - 1 : int.parse(number);
  //Calculate midi number
  final midi = noteToMidi[note]! + 12 * offset;
  //Modify note based on accidentals
  switch (scale.type) {
    case KeySigType.sharp:
      //If note should be sharp, increase pitch by semitone
      final sharps = KeySigType.sharps.take(scale.numberOfAccidentals).toList();
      return midi + (sharps.contains(note) ? 1 : 0);
    case KeySigType.flat:
      //If note should be flat, decrease pitch by semitone
      final flats = KeySigType.flats.take(scale.numberOfAccidentals).toList();
      return midi + (flats.contains(note) ? -1 : 0);
  }
}

//Convert bpm to number of seconds beat should be held
double bpmToSecondsPerBeat(int bpm) {
  return 60 / bpm;
}

//Convert length to number of beats
double lengthToBeats(Length length) {
  switch (length) {
    case Length.breve:
      return 8;
    case Length.semibreve:
      return 4;
    case Length.minim:
      return 2;
    case Length.crotchet:
      return 1;
    case Length.quaver:
      return 0.5;
    case Length.semiquaver:
      return 0.25;
    case Length.demisemiquaver:
      return 0.125;
    case Length.hemidemisemiquaver:
      return 0.0625;
  }
}

//Extension methods to convert note to and from bytes (for SMN)
extension SMNParsing on Note {
  (int, int) toBytes() {
    return (pitch.index + 1, length.index + 1);
  }

  static Note fromBytes((int, int) bytes) {
    return Note(
      pitch: Pitch.values[bytes.$1 - 1],
      length: Length.values[bytes.$2 - 1],
    );
  }
}

//Return bytes for SMN file from music
Uint8List makeSMN(List<List<Note>> parts) {
  //For each part, convert the music into a tuple of
  //a list of the note lengths and a list of the note pitches
  final byteParts = parts.map((i) {
    //Convert to SMN bytes
    final bytes = i.map((e) => e.toBytes());
    //Seperate pitches and lengths
    var out = (<int>[], <int>[]);
    for (final (pitch, length) in bytes) {
      out.$1.add(pitch);
      out.$2.add(length);
    }
    return out;
  });
  //Bytes to return
  final bytes = BytesBuilder();
  //Add pitches and lengths in correct format as defined in SMN spec
  for (final (pitches, lengths) in byteParts) {
    bytes.add(pitches);
    bytes.addByte(0);
    bytes.add(lengths);
    bytes.addByte(0);
  }
  return bytes.toBytes();
}

//Deserialise bytes to 2D list of notes for music
List<List<Note>> fromSMN(Uint8List bytes) {
  //Split bytes into contiguous lists of pitches and lengths
  final splits = bytes.fold([<int>[]], (previousValue, element) {
    if (element == 0) {
      return previousValue + [[]];
    } else {
      previousValue.last.add(element);
      return previousValue;
    }
  }).where((element) => element.isNotEmpty);
  var parts = [<Note>[]];
  //Get each consecutive pair of pitches and lengths
  for (final [pitches, lengths] in partition(splits, 2)) {
    //Zip and convert each pitch and length to a note
    parts.add(
      zip([pitches, lengths])
          .map((e) => SMNParsing.fromBytes((e[0], e[1])))
          .toList(),
    );
  }
  return parts;
}
