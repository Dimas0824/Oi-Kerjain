import 'dart:convert';

class JsonCodecUtil {
  const JsonCodecUtil._();

  static String encode(Object value) => jsonEncode(value);

  static dynamic decode(String source) => jsonDecode(source);
}
