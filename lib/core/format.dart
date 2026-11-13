import 'package:intl/intl.dart';

/// Singkatan hari, indeks = DateTime.weekday % 7 (Minggu = 0), seperti demo.
const hariSingkat = ['Min', 'Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab'];

DateTime tanggalSaja(DateTime d) => DateTime(d.year, d.month, d.day);

/// Senin, 25 November 2026
String fmtTanggal(DateTime d) => DateFormat('EEEE, d MMMM y', 'id_ID').format(d);

/// Senin, 25 November
String fmtHariTanggal(DateTime d) => DateFormat('EEEE, d MMMM', 'id_ID').format(d);

/// Senin, 25 Nov
String fmtHariTanggalPendek(DateTime d) => DateFormat('EEEE, d MMM', 'id_ID').format(d);

/// 25 Nov 2026
String fmtPendek(DateTime d) => DateFormat('d MMM y', 'id_ID').format(d);

/// 25 Nov
String fmtTglBln(DateTime d) => DateFormat('d MMM', 'id_ID').format(d);

/// November 2026
String fmtBulan(DateTime d) => DateFormat('MMMM y', 'id_ID').format(d);

/// 25 Nov 09.12
String fmtWaktu(DateTime d) => '${DateFormat('d MMM', 'id_ID').format(d)} ${DateFormat('HH.mm').format(d)}';

/// "H-3", "Hari ini", atau "Sudah lewat" (sama dengan panel web).
String hMinus(DateTime tanggal, {DateTime? sekarang}) {
  final n = tanggalSaja(tanggal).difference(tanggalSaja(sekarang ?? DateTime.now())).inDays;
  return n > 0 ? 'H-$n' : (n == 0 ? 'Hari ini' : 'Sudah lewat');
}

/// "8:00" / "08.00" → "08.00" (24 jam); null bila tidak valid. Sama dengan
/// `JadwalService::normalJam` di server.
String? normalJam(String s) {
  final m = RegExp(r'^(\d{1,2})[.:](\d{2})$').firstMatch(s.trim());
  if (m == null) return null;
  final (j, n) = (int.parse(m[1]!), int.parse(m[2]!));
  if (j > 23 || n > 59) return null;
  return '${'$j'.padLeft(2, '0')}.${'$n'.padLeft(2, '0')}';
}
