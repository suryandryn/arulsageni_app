enum Role { pasien, admin }

/// Status pendaftaran sesuai demo desain.
enum StatusPendaftaran {
  menunggu('Menunggu'),
  dijadwalkan('Dijadwalkan'),
  ditolak('Ditolak'),
  selesai('Selesai'),
  tidakHadir('Tidak hadir'),
  batal('Batal');

  const StatusPendaftaran(this.label);
  final String label;
}

class AppUser {
  const AppUser({
    required this.id,
    required this.nama,
    required this.noHp,
    required this.role,
    this.aktif = true,
  });

  final String id;
  final String nama;
  final String noHp;
  final Role role;

  /// Akun nonaktif tidak bisa masuk (diatur admin di Data Pasien).
  final bool aktif;

  bool get isAdmin => role == Role.admin;

  AppUser copyWith({bool? aktif}) =>
      AppUser(id: id, nama: nama, noHp: noHp, role: role, aktif: aktif ?? this.aktif);
}

/// Satu pendaftaran berobat. Satu akun bisa mendaftarkan beberapa pasien
/// (mis. anggota keluarga).
class Pendaftaran {
  const Pendaftaran({
    required this.id,
    required this.userId,
    required this.nama,
    required this.umur,
    required this.alamat,
    required this.noHp,
    required this.keluhan,
    required this.mediaKondisi,
    required this.fotoKtp,
    required this.status,
    required this.dibuat,
    this.tanggal,
    this.jam,
    this.alasan,
  });

  final String id;
  final String userId;
  final String nama;
  final int umur;
  final String alamat;
  final String noHp;
  final String keluhan;

  /// Path lokal / URL foto & video kondisi (hanya admin & pemilik).
  final List<String> mediaKondisi;

  /// Path lokal / URL foto KTP dengan NIK ditutup (hanya admin).
  final String fotoKtp;

  final StatusPendaftaran status;
  final DateTime dibuat;

  /// Tanggal berobat (tanpa jam) dan slot jam "08.00".
  final DateTime? tanggal;
  final String? jam;

  /// Alasan bila ditolak (dikirim ke pasien).
  final String? alasan;

  Pendaftaran copyWith({
    StatusPendaftaran? status,
    DateTime? tanggal,
    String? jam,
    String? alasan,
  }) {
    return Pendaftaran(
      id: id,
      userId: userId,
      nama: nama,
      umur: umur,
      alamat: alamat,
      noHp: noHp,
      keluhan: keluhan,
      mediaKondisi: mediaKondisi,
      fotoKtp: fotoKtp,
      dibuat: dibuat,
      status: status ?? this.status,
      tanggal: tanggal ?? this.tanggal,
      jam: jam ?? this.jam,
      alasan: alasan ?? this.alasan,
    );
  }
}

class FormPendaftaran {
  const FormPendaftaran({
    required this.userId,
    required this.nama,
    required this.umur,
    required this.noHp,
    required this.alamat,
    required this.keluhan,
    required this.mediaKondisi,
    required this.fotoKtp,
  });

  final String userId;
  final String nama;
  final int umur;
  final String noHp;
  final String alamat;
  final String keluhan;
  final List<String> mediaKondisi;
  final String fotoKtp;
}

/// Slot jam pada satu tanggal, dengan kuota sendiri.
class Slot {
  const Slot({
    required this.tanggal,
    required this.jam,
    required this.kuota,
    required this.aktif,
    required this.terisi,
  });

  final DateTime tanggal;
  final String jam;
  final int kuota;
  final bool aktif;
  final int terisi;

  int get sisa => (kuota - terisi).clamp(0, kuota);
}

class MediaSosial {
  const MediaSosial({required this.platform, required this.nama, required this.url, this.aktif = true});

  final String platform;
  final String nama;
  final String url;
  final bool aktif;

  MediaSosial copyWith({String? platform, String? nama, String? url, bool? aktif}) => MediaSosial(
        platform: platform ?? this.platform,
        nama: nama ?? this.nama,
        url: url ?? this.url,
        aktif: aktif ?? this.aktif,
      );
}

const platformMedsos = ['YouTube', 'Facebook', 'TikTok', 'Instagram', 'Snack Video'];

class Pesan {
  const Pesan({
    required this.id,
    required this.pasienId,
    required this.dariAdmin,
    required this.isi,
    required this.waktu,
    this.dibaca = false,
  });

  final String id;

  /// Percakapan selalu antara satu akun pasien dan admin klinik.
  final String pasienId;
  final bool dariAdmin;
  final String isi;
  final DateTime waktu;
  final bool dibaca;
}

class Percakapan {
  const Percakapan({required this.pasien, required this.terakhir, required this.belumDibaca});
  final AppUser pasien;
  final Pesan terakhir;
  final int belumDibaca;
}

class Notifikasi {
  const Notifikasi({
    required this.id,
    required this.userId,
    required this.judul,
    required this.isi,
    required this.waktu,
    this.dibaca = false,
  });

  final String id;
  final String userId;
  final String judul;
  final String isi;
  final DateTime waktu;
  final bool dibaca;
}

class RingkasAdmin {
  const RingkasAdmin({
    required this.menunggu,
    required this.hariBerikut,
    required this.jadwalHariBerikut,
    required this.sisaKuota30Hari,
    required this.chatBelumDibaca,
  });

  final int menunggu;

  /// Hari praktik berikutnya (bukan Minggu).
  final DateTime hariBerikut;
  final int jadwalHariBerikut;
  final int sisaKuota30Hari;
  final int chatBelumDibaca;
}
