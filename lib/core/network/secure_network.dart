import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:crypto/crypto.dart';

class SecureNetworkOverrides extends HttpOverrides {
  // Replace with your production server's SSL SHA-256 fingerprint for SSL Pinning.
  static const String? _pinnedFingerprint = null; 

  @override
  HttpClient createHttpClient(SecurityContext? context) {
    // We create a very strict SecurityContext here
    final SecurityContext secureContext = SecurityContext(withTrustedRoots: true);
    
    final HttpClient client = super.createHttpClient(secureContext);
    
    client.badCertificateCallback = (X509Certificate cert, String host, int port) {
      if (_pinnedFingerprint != null) {
        final sha = sha256.convert(cert.der).toString();
        if (sha == _pinnedFingerprint) {
          return true; // Trusted strictly by PIN
        }
      }
      
      if (kReleaseMode) {
        debugPrint("CRITICAL SECURITY: Blocked invalid SSL certificate for $host. Possible Man-In-The-Middle attack.");
        return false;
      }
      
      // In development, you might return true to allow Charles Proxy or local untrusted certs,
      // but defaulting to false is safest.
      return false; // Very strict enforcement
    };
    
    return client;
  }
}
