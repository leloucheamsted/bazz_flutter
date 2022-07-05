import 'package:flutter/foundation.dart';

class SignedUrlResponse {
  final String signedUrl, publicUrl;
  final int expiresIn;

  const SignedUrlResponse({
    required this.signedUrl,
    required this.publicUrl,
    required this.expiresIn,
  });

  factory SignedUrlResponse.fromMap(Map<String, dynamic> map) {
    return SignedUrlResponse(
      signedUrl: map['signedUrl'] as String,
      publicUrl: map['publicUrl'] as String,
      expiresIn: map['expiresIn'] as int,
    );
  }
}
