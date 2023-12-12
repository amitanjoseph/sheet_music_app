// ignore_for_file: constant_identifier_names
import 'package:pigeon/pigeon.dart';

//The pitch of a note - from A0 to C8
enum Pitch {
  A0,
  B0,
  C1,
  D1,
  E1,
  F1,
  G1,
  A1,
  B1,
  C2,
  D2,
  E2,
  F2,
  G2,
  A2,
  B2,
  C3,
  D3,
  E3,
  F3,
  G3,
  A3,
  B3,
  C4,
  D4,
  E4,
  F4,
  G4,
  A4,
  B4,
  C5,
  D5,
  E5,
  F5,
  G5,
  A5,
  B5,
  C6,
  D6,
  E6,
  F6,
  G6,
  A6,
  B6,
  C7,
  D7,
  E7,
  F7,
  G7,
  A7,
  B7,
  C8,
}

//Lengths of notes
enum Length {
  breve(value: 8),
  semibreve(value: 4),
  minim(value: 2),
  crotchet(value: 1),
  quaver(value: 1 / 2),
  semiquaver(value: 1 / 4),
  demisemiquaver(value: 1 / 8),
  hemidemisemiquaver(value: 1 / 16);

  final double value;
  const Length({required this.value});
}

class Note {
  final Pitch pitch;
  final Length length;
  const Note(this.pitch, this.length);
}

class Return {
  final List<Note?> notes;
  final String path;
  const Return(this.path, this.notes);
}

//The api for scanning images
@HostApi()
abstract class ScannerAPI {
  Return scan(String imagePath);
}
