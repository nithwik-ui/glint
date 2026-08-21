import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';

class RequestSigner {
  static const String _sharedSecret = 'glint_shared_hmac_secret_key_2026_luxury_wallpapers';
  static const String _appToken = 'glint_premium_secure_session_token_2026';

  // Generate secure signing headers for the given API endpoint path
  static Map<String, String> getSigningHeaders(String path) {
    // Current Unix timestamp in seconds
    final String timestamp = (DateTime.now().millisecondsSinceEpoch ~/ 1000).toString();
    final String nonce = _generateNonce();

    // Payload format: path|timestamp|nonce (e.g. /api/wallpapers/curated|1782098000|abcdef123)
    final String message = '$path|$timestamp|$nonce';

    // Sign using HMAC-SHA256
    final List<int> keyBytes = utf8.encode(_sharedSecret);
    final List<int> messageBytes = utf8.encode(message);
    final Hmac hmac = Hmac(sha256, keyBytes);
    final String signature = hmac.convert(messageBytes).toString();

    return {
      'x-glint-app-token': _appToken,
      'x-glint-timestamp': timestamp,
      'x-glint-nonce': nonce,
      'x-glint-signature': signature,
      'Content-Type': 'application/json',
    };
  }

  // Generate a random MD5 hash as a nonce string
  static String _generateNonce() {
    final int randomVal = Random().nextInt(10000000);
    final String base = '${DateTime.now().microsecondsSinceEpoch}_$randomVal';
    return md5.convert(utf8.encode(base)).toString();
  }
}
