import 'package:flutter/material.dart';
import 'package:video_compress/video_compress.dart';

import '../core/theme.dart';
import 'ui.dart';

/// Batas video kondisi (hosting hanya 250 MB): maks. 30 detik, dikompres ke 540p
/// (±5 MB untuk 30 detik). Server menolak video > [batasVideoMb] MB.
const durasiMaksVideo = Duration(seconds: 30);
const batasVideoMb = 10;

/// Kompres video di HP sambil menampilkan dialog kemajuan.
/// Mengembalikan path hasil kompres, atau null bila ditolak/gagal (pesan sudah ditampilkan).
Future<String?> kompresVideo(BuildContext context, String path) async {
  final MediaInfo info;
  try {
    info = await VideoCompress.getMediaInfo(path);
  } catch (_) {
    if (context.mounted) toast(context, 'Video tidak bisa dibaca', 'Pilih video lain.');
    return null;
  }
  // Toleransi 1 detik: rekaman kamera 30 detik kadang tercatat 30,4 detik.
  if ((info.duration ?? 0) > durasiMaksVideo.inMilliseconds + 1000) {
    if (context.mounted) {
      toast(
        context,
        'Video terlalu panjang',
        'Video maks. ${durasiMaksVideo.inSeconds} detik. Potong dulu atau rekam ulang.',
      );
    }
    return null;
  }
  if (!context.mounted) return null;

  final kemajuan = ValueNotifier<double>(0);
  final langganan = VideoCompress.compressProgress$.subscribe((p) => kemajuan.value = p / 100);
  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => PopScope(
      canPop: false,
      child: AlertDialog(
        backgroundColor: Colors.white,
        title: const Text('Memproses video'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Video diperkecil agar cepat terkirim. Mohon tunggu.', style: tsMut),
            const SizedBox(height: 16),
            ValueListenableBuilder<double>(
              valueListenable: kemajuan,
              builder: (_, v, _) => LinearProgressIndicator(value: v > 0 ? v : null, color: AppColors.pri),
            ),
          ],
        ),
      ),
    ),
  );

  MediaInfo? hasil;
  try {
    hasil = await VideoCompress.compressVideo(path, quality: VideoQuality.Res960x540Quality, includeAudio: true);
  } catch (_) {
    hasil = null;
  } finally {
    langganan.unsubscribe();
    if (context.mounted) Navigator.of(context, rootNavigator: true).pop();
    kemajuan.dispose();
  }
  if (!context.mounted) return null;
  final keluaran = hasil?.path;
  if (keluaran == null) {
    toast(context, 'Gagal memproses video', 'Coba lagi atau pilih video lain.');
    return null;
  }
  if ((hasil?.filesize ?? 0) > batasVideoMb * 1000 * 1000) {
    toast(context, 'Video terlalu besar', 'Setelah diperkecil masih lebih dari $batasVideoMb MB. Persingkat videonya.');
    return null;
  }
  return keluaran;
}
