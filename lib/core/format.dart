import 'package:intl/intl.dart';

/// Nama hari, indeks = DateTime.weekday - 1 (Senin = 1).
const namaHari = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];

DateTime tanggalSaja(DateTime d) => DateTime(d.year, d.month, d.day);

String fmtTanggal(DateTime d) => DateFormat('EEEE, d MMMM y', 'id_ID').format(d);

String fmtTanggalPendek(DateTime d) => DateFormat('d MMM y', 'id_ID').format(d);

String fmtJam(DateTime d) => DateFormat('HH:mm').format(d);

String fmtWaktu(DateTime d) => DateFormat('d MMM, HH:mm', 'id_ID').format(d);

/// "3 hari 4 jam lagi" / "2 jam 15 menit lagi".
String hitungMundur(DateTime target, {DateTime? sekarang}) {
  final diff = target.difference(sekarang ?? DateTime.now());
  if (diff.isNegative) return 'Waktunya sudah tiba';
  final hari = diff.inDays;
  final jam = diff.inHours % 24;
  final menit = diff.inMinutes % 60;
  if (hari > 0) return '$hari hari $jam jam lagi';
  if (jam > 0) return '$jam jam $menit menit lagi';
  return '$menit menit lagi';
}

/// Gabungkan tanggal dengan slot "HH:mm".
DateTime gabungJam(DateTime tanggal, String slot) {
  final p = slot.split(':');
  return DateTime(tanggal.year, tanggal.month, tanggal.day, int.parse(p[0]), int.parse(p[1]));
}
