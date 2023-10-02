// Autogenerated from Pigeon (v11.0.1), do not edit directly.
// See also: https://pub.dev/packages/pigeon
// ignore_for_file: public_member_api_docs, non_constant_identifier_names, avoid_as, unused_import, unnecessary_parenthesis, prefer_null_aware_operators, omit_local_variable_types, unused_shown_name, unnecessary_import

import 'dart:async';
import 'dart:typed_data' show Float64List, Int32List, Int64List, Uint8List;

import 'package:flutter/foundation.dart' show ReadBuffer, WriteBuffer;
import 'package:flutter/services.dart';

enum Pitch {
  A0,
  B0,
  C0,
  D0,
  E0,
  F0,
  G0,
  A1,
  B1,
  C1,
  D1,
  E1,
  F1,
  G1,
  A2,
  B2,
  C2,
  D2,
  E2,
  F2,
  G2,
  A3,
  B3,
  C3,
  D3,
  E3,
  F3,
  G3,
  A4,
  B4,
  C4,
  D4,
  E4,
  F4,
  G4,
  A5,
  B5,
  C5,
  D5,
  E5,
  F5,
  G5,
  A6,
  B6,
  C6,
  D6,
  E6,
  F6,
  G6,
  A7,
  B7,
  C7,
  D7,
  E7,
  F7,
  G7,
  A8,
  B8,
  C8,
}

enum Length {
  breve,
  semibreve,
  minim,
  crotchet,
  quaver,
  semiquaver,
  demisemiquaver,
  hemidemisemiquaver,
}

class ScannerAPI {
  /// Constructor for [ScannerAPI].  The [binaryMessenger] named argument is
  /// available for dependency injection.  If it is left null, the default
  /// BinaryMessenger will be used which routes to the host platform.
  ScannerAPI({BinaryMessenger? binaryMessenger})
      : _binaryMessenger = binaryMessenger;
  final BinaryMessenger? _binaryMessenger;

  static const MessageCodec<Object?> codec = StandardMessageCodec();

  Future<String> scan(String arg_imagePath) async {
    final BasicMessageChannel<Object?> channel = BasicMessageChannel<Object?>(
        'dev.flutter.pigeon.sheet_music_app.ScannerAPI.scan', codec,
        binaryMessenger: _binaryMessenger);
    final List<Object?>? replyList =
        await channel.send(<Object?>[arg_imagePath]) as List<Object?>?;
    if (replyList == null) {
      throw PlatformException(
        code: 'channel-error',
        message: 'Unable to establish connection on channel.',
      );
    } else if (replyList.length > 1) {
      throw PlatformException(
        code: replyList[0]! as String,
        message: replyList[1] as String?,
        details: replyList[2],
      );
    } else if (replyList[0] == null) {
      throw PlatformException(
        code: 'null-error',
        message: 'Host platform returned null value for non-null return value.',
      );
    } else {
      return (replyList[0] as String?)!;
    }
  }
}