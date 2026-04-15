import 'package:flutter_dotenv/flutter_dotenv.dart';

/// ZEGOCLOUD configuration — reads App ID and App Sign from .env.
class ZegoConfig {
  ZegoConfig._();

  /// ZEGOCLOUD numeric App ID from console.
  static int get appID =>
      int.tryParse(dotenv.env['ZEGO_APP_ID'] ?? '') ?? 0;

  /// ZEGOCLOUD App Sign (hex string) from console.
  static String get appSign => dotenv.env['ZEGO_APP_SIGN'] ?? '';

  /// Whether ZEGO credentials are configured.
  static bool get isConfigured => appID > 0 && appSign.isNotEmpty;
}
