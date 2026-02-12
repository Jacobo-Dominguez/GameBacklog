import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' as io;

class ImageUtils {
  static ImageProvider? getAvatarProvider(String? avatarUrl) {
    if (avatarUrl == null || avatarUrl.isEmpty) return null;

    if (avatarUrl.startsWith('http') || avatarUrl.startsWith('blob:') || kIsWeb) {
      // En Web, incluso si es una ruta local aparente, se maneja como NetworkImage o similar
      // ImagePicker en web devuelve un blob URL o una ruta que Flutter Web maneja bien con NetworkImage
      return NetworkImage(avatarUrl);
    } else {
      // Solo en plataformas no web usamos FileImage
      return FileImage(io.File(avatarUrl));
    }
  }
}
