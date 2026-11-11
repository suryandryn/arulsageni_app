import 'dart:io';

import 'package:flutter/material.dart';

import '../core/theme.dart';

bool adalahVideo(String path) => RegExp(r'\.(mp4|mov|3gp|webm|mkv)$', caseSensitive: false).hasMatch(path);

String namaBerkas(String path) => path.split(RegExp(r'[\\/]')).last;

bool _berkasLokal(String path) => !path.startsWith('http') && File(path).existsSync();

/// Grid 3 kolom kotak persegi (.media). Ketuk untuk memperbesar.
class GridMedia extends StatelessWidget {
  const GridMedia({super.key, required this.berkas, this.label, this.onHapus, this.tambahan});

  final List<String> berkas;

  /// Teks pengganti jenis berkas (mis. "KTP").
  final String? label;
  final ValueChanged<String>? onHapus;

  /// Kotak ekstra di akhir (mis. tombol tambah).
  final Widget? tambahan;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: GridView.count(
        crossAxisCount: 3,
        mainAxisSpacing: 6,
        crossAxisSpacing: 6,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          for (final f in berkas) _Kotak(f, label: label, onHapus: onHapus == null ? null : () => onHapus!(f)),
          ?tambahan,
        ],
      ),
    );
  }
}

class _Kotak extends StatelessWidget {
  const _Kotak(this.path, {this.label, this.onHapus});
  final String path;
  final String? label;
  final VoidCallback? onHapus;

  @override
  Widget build(BuildContext context) {
    final video = adalahVideo(path);
    final Widget isi;
    if (!video && path.startsWith('http')) {
      isi = Image.network(path, fit: BoxFit.cover);
    } else if (!video && _berkasLokal(path)) {
      isi = Image.file(File(path), fit: BoxFit.cover);
    } else {
      isi = Padding(
        padding: const EdgeInsets.all(4),
        child: Center(
          child: Text(
            '${label ?? (video ? '▶ Video' : 'Foto')}\n${namaBerkas(path)}',
            textAlign: TextAlign.center,
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12, color: AppColors.mut),
          ),
        ),
      );
    }
    return Stack(
      fit: StackFit.expand,
      children: [
        Material(
          color: AppColors.krem,
          borderRadius: BorderRadius.circular(10),
          clipBehavior: Clip.antiAlias,
          child: InkWell(onTap: () => lihatMedia(context, path), child: isi),
        ),
        if (onHapus != null)
          Positioned(
            top: 4,
            right: 4,
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
    );
  }
}

/// Kotak "tambah" untuk grid media.
class KotakTambah extends StatelessWidget {
  const KotakTambah({super.key, required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: const BorderSide(color: AppColors.pri),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.add_a_photo_outlined, color: AppColors.pri),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, color: AppColors.pri)),
            ),
          ],
        ),
      ),
    );
  }
}

/// Tampilan penuh foto/video (.lihat). Ketuk untuk menutup.
// TODO(api): putar video dengan video_player setelah media diambil dari server.
void lihatMedia(BuildContext context, String path) {
  final video = adalahVideo(path);
  showDialog<void>(
    context: context,
    barrierColor: const Color(0xDD000000),
    builder: (ctx) => GestureDetector(
      onTap: () => Navigator.pop(ctx),
      child: Material(
        color: Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: !video && (path.startsWith('http') || _berkasLokal(path))
                    ? InteractiveViewer(
                        child: path.startsWith('http') ? Image.network(path) : Image.file(File(path)),
                      )
                    : AspectRatio(
                        aspectRatio: 3 / 4,
                        child: Container(
                          alignment: Alignment.center,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.white54, width: 2),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            '${video ? 'Pemutar video' : 'Pratinjau foto'}: ${namaBerkas(path)}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
              ),
              const SizedBox(height: 16),
              const Text('Ketuk untuk menutup', style: TextStyle(color: Colors.white)),
            ],
          ),
        ),
      ),
    ),
  );
}
