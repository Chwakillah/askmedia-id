// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'env.dart';

// **************************************************************************
// FlutterSecureDotEnvAnnotationGenerator
// **************************************************************************

class _$Env extends Env {
  const _$Env(this._encryptionKey, this._iv) : super._();

  final String _encryptionKey;
  final String _iv;
  static final Uint8List _encryptedValues = Uint8List.fromList([
    61,
    61,
    53,
    21,
    119,
    74,
    249,
    36,
    76,
    22,
    22,
    49,
    130,
    103,
    134,
    19,
    231,
    99,
    159,
    183,
    177,
    107,
    118,
    241,
    80,
    82,
    148,
    131,
    154,
    84,
    171,
    250,
    184,
    232,
    96,
    176,
    106,
    207,
    178,
    40,
    147,
    185,
    150,
    2,
    76,
    171,
    83,
    186,
  ]);
  @override
  String get apiBaseUrl => _get('API_BASE_URL');

  @override
  String get apiWebSocketUrl => _get('API_WEB_SOCKET_URL');

  T _get<T>(String key, {T Function(String)? fromString}) {
    T parseValue(String strValue) {
      if (T == String) {
        return (strValue) as T;
      } else if (T == int) {
        return int.parse(strValue) as T;
      } else if (T == double) {
        return double.parse(strValue) as T;
      } else if (T == bool) {
        return (strValue.toLowerCase() == 'true') as T;
      } else if (T == Enum || fromString != null) {
        if (fromString == null) {
          throw Exception('fromString is required for Enum');
        }

        return fromString(strValue.split('.').last);
      }

      throw Exception('Type ${T.toString()} not supported');
    }

    final encryptionKey = base64.decode(_encryptionKey.trim());
    final iv = base64.decode(_iv.trim());
    final decrypted = AESCBCEncrypter.aesCbcDecrypt(
      encryptionKey,
      iv,
      _encryptedValues,
    );
    final jsonMap = json.decode(decrypted) as Map<String, dynamic>;
    if (!jsonMap.containsKey(key)) {
      throw Exception('Key $key not found in .env file');
    }

    final encryptedValue = jsonMap[key] as String;
    final decryptedValue = AESCBCEncrypter.aesCbcDecrypt(
      encryptionKey,
      iv,
      base64.decode(encryptedValue),
    );
    return parseValue(decryptedValue);
  }
}
