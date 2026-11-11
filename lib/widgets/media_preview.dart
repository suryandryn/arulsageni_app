import 'dart:io';

import 'package:flutter/material.dart';

bool adalahVideo(String path) {
  final p = path.toLowerCase();
  return p.endsWith('.mp4') || p.endsWith('.mov') || p.endsWith('.3gp') || p.endsWith('.mkv');
}

/// Kotak pratinjau foto/video. Path lokal (sebelum upload) atau URL (dari server).
class MediaThumb extends StatelessWidget {
  const MediaThumb(this.path, {super.key, this.size = 88, this.onHapus});

  final String path;
  final double size;
  final VoidCallback? onHapus;

  @override
  Widget build(BuildContext context) {
    final Widget isi;
    if (adalahVideo(path)) {
      isi = const ColoredBox(
        color: Color(0xFF1F2A24),
        child: Center(child: Icon(Icons.play_circle_fill, color: Colors.white, size: 36)),
      );
    } else if (path.startsWith('http')) {
      isi = Image.network(path, fit: BoxFit.cover);
    } else {
      isi = Image.file(File(path), fit: BoxFit.cover,
          errorBuilder: (_, _, _) => const Icon(Icons.broken_image));
    }
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(borderRadius: BorderRadius.circular(10), child: isi),
          if (onHapus != null)
            Positioned(
              top: 2,
              right: 2,
              child: InkWell(
                onTap: onHapus,
                child: const CircleAvatar(
                  radius: 12,
                  backgroundColor: Colors.black54,
                  child: Icon(Icons.close, size: 14, color: Colors.white),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
