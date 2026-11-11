enum Role { pasien, admin }

enum StatusPendaftaran {
  menungguVerifikasi('Menunggu verifikasi'),
  perluDilengkapi('Perlu dilengkapi'),
  terjadwal('Terjadwal'),
  tidakDapatDitangani('Tidak dapat ditangani'),
  selesai('Selesai'),
  tidakHadir('Tidak hadir'),
  dibatalkan('Dibatalkan');

  const StatusPendaftaran(this.label);
  final String label;

  bool get aktif =>
      this == menungguVerifikasi || this == perluDilengkapi || this == terjadwal;
}

class AppUser {
  const AppUser({
    required this.id,
    required this.nama,
    required this.noWa,
    required this.role,
  });

  final String id;
  final String nama;
  final String noWa;
  final Role role;

  bool get isAdmin => role == Role.admin;
}

class Pendaftaran {
  const Pendaftaran({
    required this.id,
    required this.kode,
    required this.userId,
    required this.nama,
    required this.noWa,
    required this.kota,
    required this.keluhan,
    required this.mediaKondisi,
    required this.status,
    required this.dibuat,
    this.fotoKtp,
    this.jadwal,
    this.noAntrean,
    this.catatanAdmin,
  });

  final String id;
  final String kode;
  final String userId;
  final String nama;
  final String noWa;
  final String kota;
  final String keluhan;

  /// Path lokal / URL foto & video kondisi pasien (hanya untuk admin).
  final List<String> mediaKondisi;

  /// Path lokal / URL foto KTP dengan NIK ditutup (hanya untuk admin).
  final String? fotoKtp;

  final StatusPendaftaran status;
  final DateTime dibuat;
  final DateTime? jadwal;
  final int? noAntrean;
  final String? catatanAdmin;

  Pendaftaran copyWith({
    StatusPendaftaran? status,
    DateTime? jadwal,
    int? noAntrean,
    String? catatanAdmin,
    bool hapusJadwal = false,
  }) {
    return Pendaftaran(
      id: id,
      kode: kode,
      userId: userId,
      nama: nama,
      noWa: noWa,
      kota: kota,
      keluhan: keluhan,
      mediaKondisi: mediaKondisi,
      fotoKtp: fotoKtp,
      dibuat: dibuat,
      status: status ?? this.status,
      jadwal: hapusJadwal ? null : (jadwal ?? this.jadwal),
      noAntrean: hapusJadwal ? null : (noAntrean ?? this.noAntrean),
      catatanAdmin: catatanAdmin ?? this.catatanAdmin,
    );
  }
}

class FormPendaftaran {
  const FormPendaftaran({
    required this.userId,
    required this.nama,
    required this.noWa,
    required this.kota,
    required this.keluhan,
    required this.mediaKondisi,
    this.fotoKtp,
  });

  final String userId;
  final String nama;
  final String noWa;
  final String kota;
  final String keluhan;
  final List<String> mediaKondisi;
  final String? fotoKtp;
}

class MediaSosial {
  const MediaSosial({required this.platform, required this.nama, required this.url});
  final String platform;
  final String nama;
  final String url;
}

class KlinikInfo {
  const KlinikInfo({
    required this.nama,
    required this.pemilik,
    required this.alamat,
    required this.mapsUrl,
    required this.waAdmin,
    required this.estimasiBiaya,
    required this.mediaSosial,
    required this.website,
  });

  final String nama;
  final String pemilik;
  final String alamat;
  final String mapsUrl;
  final String waAdmin;
  final List<String> estimasiBiaya;
  final List<MediaSosial> mediaSosial;
  final String website;

  KlinikInfo copyWith({
    String? alamat,
    String? mapsUrl,
    String? waAdmin,
    List<String>? estimasiBiaya,
  }) {
    return KlinikInfo(
      nama: nama,
      pemilik: pemilik,
      alamat: alamat ?? this.alamat,
      mapsUrl: mapsUrl ?? this.mapsUrl,
      waAdmin: waAdmin ?? this.waAdmin,
      estimasiBiaya: estimasiBiaya ?? this.estimasiBiaya,
      mediaSosial: mediaSosial,
      website: website,
    );
  }
}

class PengaturanJadwal {
  const PengaturanJadwal({
    required this.kuotaPerHari,
    required this.hariPraktik,
    required this.slotJam,
    required this.periodeAkhir,
    required this.tanggalKhusus,
  });

  final int kuotaPerHari;

  /// DateTime.weekday (1 = Senin ... 7 = Minggu).
  final Set<int> hariPraktik;

  /// Pilihan jam janji, format "HH:mm".
  final List<String> slotJam;

  /// Batas akhir periode jadwal yang dibuka.
  final DateTime periodeAkhir;

  /// Kuota khusus per tanggal; nilai 0 = libur.
  final Map<DateTime, int> tanggalKhusus;

  PengaturanJadwal copyWith({
    int? kuotaPerHari,
    Set<int>? hariPraktik,
    List<String>? slotJam,
    DateTime? periodeAkhir,
    Map<DateTime, int>? tanggalKhusus,
  }) {
    return PengaturanJadwal(
      kuotaPerHari: kuotaPerHari ?? this.kuotaPerHari,
      hariPraktik: hariPraktik ?? this.hariPraktik,
      slotJam: slotJam ?? this.slotJam,
      periodeAkhir: periodeAkhir ?? this.periodeAkhir,
      tanggalKhusus: tanggalKhusus ?? this.tanggalKhusus,
    );
  }
}

class Pesan {
  const Pesan({
    required this.id,
    required this.pasienId,
    required this.dariAdmin,
    required this.isi,
    required this.waktu,
  });

  final String id;

  /// Percakapan selalu antara satu pasien dan admin klinik.
  final String pasienId;
  final bool dariAdmin;
  final String isi;
  final DateTime waktu;
}

class Percakapan {
  const Percakapan({required this.pasien, required this.terakhir});
  final AppUser pasien;
  final Pesan terakhir;
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
    required this.jadwalBesok,
    required this.totalTerdaftar,
    required this.chatTerbaru,
  });

  final int menunggu;
  final int jadwalBesok;
  final int totalTerdaftar;
  final List<Percakapan> chatTerbaru;
}
