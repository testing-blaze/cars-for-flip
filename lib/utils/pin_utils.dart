import 'dart:convert';

import 'package:crypto/crypto.dart';

String hashPin(String pin) {
  return sha256.convert(utf8.encode(pin)).toString();
}

bool isValidPinFormat(String pin) {
  return RegExp(r'^\d{4}$').hasMatch(pin);
}

