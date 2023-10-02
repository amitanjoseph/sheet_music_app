// Autogenerated from Pigeon (v11.0.1), do not edit directly.
// See also: https://pub.dev/packages/pigeon

package com.example.sheet_music_app.pigeon

import android.util.Log
import io.flutter.plugin.common.BasicMessageChannel
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MessageCodec
import io.flutter.plugin.common.StandardMessageCodec
import java.io.ByteArrayOutputStream
import java.nio.ByteBuffer

private fun wrapResult(result: Any?): List<Any?> {
  return listOf(result)
}

private fun wrapError(exception: Throwable): List<Any?> {
  if (exception is FlutterError) {
    return listOf(
      exception.code,
      exception.message,
      exception.details
    )
  } else {
    return listOf(
      exception.javaClass.simpleName,
      exception.toString(),
      "Cause: " + exception.cause + ", Stacktrace: " + Log.getStackTraceString(exception)
    )
  }
}

/**
 * Error class for passing custom error details to Flutter via a thrown PlatformException.
 * @property code The error code.
 * @property message The error message.
 * @property details The error details. Must be a datatype supported by the api codec.
 */
class FlutterError (
  val code: String,
  override val message: String? = null,
  val details: Any? = null
) : Throwable()

enum class Pitch(val raw: Int) {
  A0(0),
  B0(1),
  C0(2),
  D0(3),
  E0(4),
  F0(5),
  G0(6),
  A1(7),
  B1(8),
  C1(9),
  D1(10),
  E1(11),
  F1(12),
  G1(13),
  A2(14),
  B2(15),
  C2(16),
  D2(17),
  E2(18),
  F2(19),
  G2(20),
  A3(21),
  B3(22),
  C3(23),
  D3(24),
  E3(25),
  F3(26),
  G3(27),
  A4(28),
  B4(29),
  C4(30),
  D4(31),
  E4(32),
  F4(33),
  G4(34),
  A5(35),
  B5(36),
  C5(37),
  D5(38),
  E5(39),
  F5(40),
  G5(41),
  A6(42),
  B6(43),
  C6(44),
  D6(45),
  E6(46),
  F6(47),
  G6(48),
  A7(49),
  B7(50),
  C7(51),
  D7(52),
  E7(53),
  F7(54),
  G7(55),
  A8(56),
  B8(57),
  C8(58);

  companion object {
    fun ofRaw(raw: Int): Pitch? {
      return values().firstOrNull { it.raw == raw }
    }
  }
}

enum class Length(val raw: Int) {
  BREVE(0),
  SEMIBREVE(1),
  MINIM(2),
  CROTCHET(3),
  QUAVER(4),
  SEMIQUAVER(5),
  DEMISEMIQUAVER(6),
  HEMIDEMISEMIQUAVER(7);

  companion object {
    fun ofRaw(raw: Int): Length? {
      return values().firstOrNull { it.raw == raw }
    }
  }
}
/** Generated interface from Pigeon that represents a handler of messages from Flutter. */
interface ScannerAPI {
  fun scan(imagePath: String): String

  companion object {
    /** The codec used by ScannerAPI. */
    val codec: MessageCodec<Any?> by lazy {
      StandardMessageCodec()
    }
    /** Sets up an instance of `ScannerAPI` to handle messages through the `binaryMessenger`. */
    @Suppress("UNCHECKED_CAST")
    fun setUp(binaryMessenger: BinaryMessenger, api: ScannerAPI?) {
      run {
        val channel = BasicMessageChannel<Any?>(binaryMessenger, "dev.flutter.pigeon.sheet_music_app.ScannerAPI.scan", codec)
        if (api != null) {
          channel.setMessageHandler { message, reply ->
            val args = message as List<Any?>
            val imagePathArg = args[0] as String
            var wrapped: List<Any?>
            try {
              wrapped = listOf<Any?>(api.scan(imagePathArg))
            } catch (exception: Throwable) {
              wrapped = wrapError(exception)
            }
            reply.reply(wrapped)
          }
        } else {
          channel.setMessageHandler(null)
        }
      }
    }
  }
}
