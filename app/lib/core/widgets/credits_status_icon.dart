import 'package:flutter/material.dart';

/// The single credits icon used by balance surfaces across the app.
///
/// Keeping the asset and its sizing behavior here ensures the Home status
/// badge and larger Settings balance card always stay visually consistent.
class CreditsStatusIcon extends StatelessWidget {
  const CreditsStatusIcon({super.key, this.size = 22});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/icons/credites.png',
      width: size,
      height: size,
      fit: BoxFit.contain,
    );
  }
}
