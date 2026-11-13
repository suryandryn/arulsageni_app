import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';

import '../core/theme.dart';
import '../data/repository.dart';

bool adalahVideo(String path) => RegExp(r'\.(mp4|mov|3gp|webm|mkv)$', caseSensitive: false).hasMatch(path);

String namaBerkas(String path) => path.split(RegExp(r'[\\/]')).last;

bool _berkasLokal(String path) => !path.startsWith('http') && File(path).existsSync();

/// Gambar dari server memakai token masuk (berkas pasien bersifat privat).
Widget _gambarServer(BuildContext context, String url, {BoxFit? fit}) => Image.network(
  url,
  fit: fit,
  headers: context.read<Repository>().headerMedia,
  errorBuilder: (_, _, _) => const Center(child: Icon(Icons.broken_image_outlined, color: AppColors.mut)),
);

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
      isi = _gambarServer(context, path, fit: BoxFit.cover);
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
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12, color: AppColors.pri),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Tampilan penuh foto/video (.lihat). Ketuk di luar media untuk menutup.
void lihatMedia(BuildContext context, String path) {
  final video = adalahVideo(path);
  if (video && (path.startsWith('http') || _berkasLokal(path))) {
    final header = context.read<Repository>().headerMedia;
    showDialog<void>(
      context: context,
      barrierColor: const Color(0xDD000000),
      builder: (ctx) => _PemutarVideo(path: path, header: header),
    );
    return;
  }
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
                        child: path.startsWith('http') ? _gambarServer(context, path) : Image.file(File(path)),
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

/// Pemutar video kondisi (dari server memakai token masuk, atau berkas di HP).
class _PemutarVideo extends StatefulWidget {
  const _PemutarVideo({required this.path, required this.header});
  final String path;
  final Map<String, String> header;

  @override
  State<_PemutarVideo> createState() => _PemutarVideoState();
}

class _PemutarVideoState extends State<_PemutarVideo> {
  late final VideoPlayerController _c = widget.path.startsWith('http')
      ? VideoPlayerController.networkUrl(Uri.parse(widget.path), httpHeaders: widget.header)
      : VideoPlayerController.file(File(widget.path));
  Object? _galat;

  @override
  void initState() {
    super.initState();
    _c.addListener(_ubah);
    _c.initialize().then((_) => _c.play()).catchError((Object e) {
      if (mounted) setState(() => _galat = e);
    });
  }

  void _ubah() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _c.removeListener(_ubah);
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final v = _c.value;
    final Widget isi;
    if (_galat != null || v.hasError) {
      isi = Text(
        'Video tidak dapat diputar.\n${namaBerkas(widget.path)}',
        textAlign: TextAlign.center,
        style: const TextStyle(color: Colors.white),
      );
    } else if (!v.isInitialized) {
      isi = const CircularProgressIndicator(color: Colors.white);
    } else {
      isi = Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: AspectRatio(
              aspectRatio: v.aspectRatio,
              child: GestureDetector(
                onTap: () => v.isPlaying ? _c.pause() : _c.play(),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    VideoPlayer(_c),
                    if (!v.isPlaying)
                      const CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.black54,
                        child: Icon(Icons.play_arrow_rounded, size: 40, color: Colors.white),
                      ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          VideoProgressIndicator(
            _c,
            allowScrubbing: true,
            colors: const VideoProgressColors(playedColor: AppColors.gold, bufferedColor: Colors.white38),
          ),
        ],
      );
    }
    return Material(
      color: Colors.transparent,
      child: Column(
        children: [
          Align(
            alignment: Alignment.topRight,
            child: IconButton(
              tooltip: 'Tutup',
              color: Colors.white,
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              child: Center(child: isi),
            ),
          ),
          const Padding(
            padding: EdgeInsets.only(bottom: 16),
            child: Text('Ketuk video untuk jeda / putar', style: TextStyle(color: Colors.white70)),
          ),
        ],
      ),
    );
  }
}
