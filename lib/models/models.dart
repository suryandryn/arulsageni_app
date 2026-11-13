enum Role { pasien, admin }

/// Status pendaftaran sesuai demo desain.
enum StatusPendaftaran {
  menunggu('Menunggu'),
  perluDilengkapi('Perlu dilengkapi'),
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
    this.email,
    this.dibuat,
    this.jumlahPendaftaran,
  });

  final String id;
  final String nama;
  final String noHp;
  final Role role;

  /// Email akun admin (boleh kosong); null untuk pasien.
  final String? email;

  /// Waktu akun dibuat dan jumlah pendaftarannya (diisi di Data Pasien admin).
  final DateTime? dibuat;
  final int? jumlahPendaftaran;

  /// Akun nonaktif tidak bisa masuk (diatur admin di Data Pasien).
  final bool aktif;

  bool get isAdmin => role == Role.admin;

  AppUser copyWith({bool? aktif, String? nama, String? email}) => AppUser(
    id: id,
    nama: nama ?? this.nama,
    noHp: noHp,
    role: role,
    aktif: aktif ?? this.aktif,
    email: email ?? this.email,
    dibuat: dibuat,
    jumlahPendaftaran: jumlahPendaftaran,
  );
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
    this.nomorAntrean,
    this.alasan,
    this.catatan,
    this.dilengkapi,
    this.pengajuan,
    this.namaAkun,
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

  /// Nomor antrean di [tanggal], urut siapa yang lebih dulu dijadwalkan admin; disusun ulang
  /// bila ada yang batal / pindah tanggal. Null bila belum / tidak lagi dijadwalkan.
  final int? nomorAntrean;

  /// Alasan bila ditolak (dikirim ke pasien).
  final String? alasan;

  /// Catatan "perlu dilengkapi" terakhir dari admin; tetap ada setelah pasien melengkapi.
  final String? catatan;

  /// Waktu pasien terakhir melengkapi pendaftaran (null bila belum).
  final DateTime? dilengkapi;

  /// Pasien boleh mengedit pendaftaran (hanya saat diminta dilengkapi).
  bool get bisaDilengkapi => status == StatusPendaftaran.perluDilengkapi;

  /// Pengajuan jadwal ulang / pembatalan terbaru dari pasien (null bila belum pernah).
  final Pengajuan? pengajuan;

  /// Nama akun yang mendaftarkan (hanya untuk admin; null bila tidak diketahui).
  final String? namaAkun;

  /// Pengajuan yang masih menunggu keputusan admin.
  Pengajuan? get pengajuanMenunggu => pengajuan?.status == StatusPengajuan.menunggu ? pengajuan : null;

  /// Pasien boleh mengajukan jadwal ulang (hanya bila sudah dijadwalkan).
  bool get bisaAjukanJadwalUlang => status == StatusPendaftaran.dijadwalkan && pengajuanMenunggu == null;

  /// Pasien boleh mengajukan pembatalan (menunggu / perlu dilengkapi / dijadwalkan).
  bool get bisaAjukanBatal =>
      const [
        StatusPendaftaran.menunggu,
        StatusPendaftaran.perluDilengkapi,
        StatusPendaftaran.dijadwalkan,
      ].contains(status) &&
      pengajuanMenunggu == null;

  static const _tetap = Object();

  /// [pengajuan] & [nomorAntrean]: kirim `null` untuk menghapus; tidak dikirim = tetap.
  Pendaftaran copyWith({
    Object? nomorAntrean = _tetap,
    String? nama,
    int? umur,
    String? alamat,
    String? noHp,
    String? keluhan,
    List<String>? mediaKondisi,
    String? fotoKtp,
    StatusPendaftaran? status,
    DateTime? tanggal,
    String? jam,
    String? alasan,
    String? catatan,
    DateTime? dilengkapi,
    Object? pengajuan = _tetap,
    String? namaAkun,
  }) {
    return Pendaftaran(
      id: id,
      userId: userId,
      nama: nama ?? this.nama,
      umur: umur ?? this.umur,
      alamat: alamat ?? this.alamat,
      noHp: noHp ?? this.noHp,
      keluhan: keluhan ?? this.keluhan,
      mediaKondisi: mediaKondisi ?? this.mediaKondisi,
      fotoKtp: fotoKtp ?? this.fotoKtp,
      dibuat: dibuat,
      status: status ?? this.status,
      tanggal: tanggal ?? this.tanggal,
      jam: jam ?? this.jam,
      nomorAntrean: identical(nomorAntrean, _tetap) ? this.nomorAntrean : nomorAntrean as int?,
      alasan: alasan ?? this.alasan,
      catatan: catatan ?? this.catatan,
      dilengkapi: dilengkapi ?? this.dilengkapi,
      pengajuan: identical(pengajuan, _tetap) ? this.pengajuan : pengajuan as Pengajuan?,
      namaAkun: namaAkun ?? this.namaAkun,
    );
  }
}

enum JenisPengajuan {
  jadwalUlang('Jadwal ulang'),
  batal('Pembatalan');

  const JenisPengajuan(this.label);
  final String label;
}

enum StatusPengajuan {
  menunggu('Menunggu keputusan admin'),
  disetujui('Disetujui'),
  ditolak('Ditolak');

  const StatusPengajuan(this.label);
  final String label;
}

/// Pengajuan jadwal ulang / pembatalan dari pasien; disetujui atau ditolak admin
/// (alasan penolakan wajib dan dikirim ke pasien).
class Pengajuan {
  const Pengajuan({
    required this.id,
    required this.jenis,
    required this.status,
    required this.dibuat,
    this.tanggal,
    this.jam,
    this.alasan,
    this.alasanTolak,
  });

  final String id;
  final JenisPengajuan jenis;
  final StatusPengajuan status;
  final DateTime dibuat;

  /// Jadwal yang diminta (hanya jadwal ulang).
  final DateTime? tanggal;
  final String? jam;

  /// Alasan dari pasien (boleh kosong).
  final String? alasan;

  /// Alasan dari admin bila ditolak.
  final String? alasanTolak;

  Pengajuan copyWith({StatusPengajuan? status, String? alasanTolak}) => Pengajuan(
    id: id,
    jenis: jenis,
    status: status ?? this.status,
    dibuat: dibuat,
    tanggal: tanggal,
    jam: jam,
    alasan: alasan,
    alasanTolak: alasanTolak ?? this.alasanTolak,
  );
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
    this.pengajuanMenunggu = 0,
    this.pasienHariBerikut = const [],
    this.terbaru = const [],
  });

  final int menunggu;

  /// Hari praktik berikutnya (tanggal terdekat sesudah hari ini yang punya slot aktif);
  /// null bila belum ada slot aktif sama sekali.
  final DateTime? hariBerikut;
  final int jadwalHariBerikut;
  final int sisaKuota30Hari;
  final int chatBelumDibaca;

  /// Pengajuan jadwal ulang / pembatalan dari pasien yang belum diputuskan.
  final int pengajuanMenunggu;

  /// Pasien terjadwal di [hariBerikut], urut jam.
  final List<JadwalPasien> pasienHariBerikut;

  /// 5 pendaftaran menunggu terbaru ("Menunggu dinilai").
  final List<Pendaftaran> terbaru;
}

typedef JadwalPasien = ({String id, String nama, String jam, int? nomor});

/// Info klinik yang diatur admin (panel web / aplikasi): menu Info & kartu jadwal pasien.
/// Gambar di Info klinik yang bisa diganti admin.
enum JenisGambar {
  /// Halaman Masuk & Daftar Akun.
  logo('logo', 'Logo halaman Masuk & Daftar Akun'),

  /// Foto profil di menu Info pasien.
  foto('foto', 'Foto profil di menu Info');

  const JenisGambar(this.kunci, this.label);

  /// Segmen URL API: `/gambar/{kunci}`.
  final String kunci;
  final String label;
}

class InfoKlinik {
  const InfoKlinik({
    required this.alamat,
    required this.mapsUrl,
    required this.waAdmin,
    required this.biaya,
    this.biayaCatatan = '',
    this.websiteUrl = '',
    this.websiteKeterangan = '',
    required this.jadwalBerobat,
    this.logoUrl = '',
    this.fotoUrl = '',
  });

  /// Penanda tanggal berobat di [jadwalBerobat]; diganti tanggal pasien (huruf kapital).
  static const penandaTanggal = '{tanggal}';

  final String alamat;
  final String mapsUrl;
  final String waAdmin;

  /// Rincian biaya; satu baris = satu poin.
  final String biaya;

  /// Kalimat penutup biaya (tebal); boleh kosong.
  final String biayaCatatan;

  /// Kosong = bagian Website disembunyikan.
  final String websiteUrl;
  final String websiteKeterangan;

  /// Paragraf di bawah kartu jadwal; satu baris = satu paragraf.
  final String jadwalBerobat;

  /// Gambar yang diatur admin ([JenisGambar]): URL server atau path berkas (mode demo).
  /// Kosong = gambar bawaan aplikasi (`Klinik.foto`). Diubah lewat `Repository.gantiGambar`,
  /// bukan `simpanInfoKlinik`.
  final String logoUrl;
  final String fotoUrl;

  String gambar(JenisGambar j) => switch (j) {
    JenisGambar.logo => logoUrl,
    JenisGambar.foto => fotoUrl,
  };

  InfoKlinik denganGambar({required String logo, required String foto}) => InfoKlinik(
    alamat: alamat,
    mapsUrl: mapsUrl,
    waAdmin: waAdmin,
    biaya: biaya,
    biayaCatatan: biayaCatatan,
    websiteUrl: websiteUrl,
    websiteKeterangan: websiteKeterangan,
    jadwalBerobat: jadwalBerobat,
    logoUrl: logo,
    fotoUrl: foto,
  );

  static List<String> _baris(String s) => [
    for (final b in s.split('\n'))
      if (b.trim().isNotEmpty) b.trim(),
  ];

  List<String> get poinBiaya => _baris(biaya);

  /// Paragraf jadwal untuk satu pasien.
  List<String> arahanJadwal(String tanggalKapital) => [
    for (final p in _baris(jadwalBerobat)) p.replaceAll(penandaTanggal, tanggalKapital),
  ];

  /// Nama situs tanpa https:// dan garis miring di akhir, mis. "pengobatankangarulsageni.com".
  String get websiteNama => websiteUrl.replaceFirst(RegExp(r'^https?://(www\.)?'), '').replaceFirst(RegExp(r'/$'), '');

  /// Nilai bawaan dari klien (sama dengan bawaan server).
  static const bawaan = InfoKlinik(
    alamat: 'RT.013/RW.004, Kampung Curug Rendeng, Kec. Jalan Cagak, Kabupaten Subang, Jawa Barat 41281',
    mapsUrl: 'https://maps.app.goo.gl/uvurN77g3fJBCdNa6',
    waAdmin: '0895 2203 3857',
    biaya:
        'Untuk pendaftaran 10 rb bayar di tempat\n'
        'Pengobatan Se iklasnya Untuk Kang Arul Sageni\n'
        'Untuk Obatnya dan vitaminnya nanti di Harga 600rb untuk Segala Macam penyakit Medis non Medis dapat (6 Produk)',
    biayaCatatan: 'Semuanya bayar di tempat Saat Pengobatan',
    websiteUrl: 'https://pengobatankangarulsageni.com',
    websiteKeterangan: 'Website resmi',
    jadwalBerobat:
        '{tanggal} JAM 04.00 PAGI SUDAH HARUS DI LOKASI KARENA PENDAFTARAN DI TUTUP (JAM 8 PAGI) '
        'JANGAN SAMPAI ANDA TIDAK MENDAPTKAN ANTRIAN\n'
        'SILAHKAN DATANG TEPAT WAKTU SESUAI JADWAL YANG SUDAH DI TENTUKAN🙏 JANGAN SAMPAI TELAT.\n'
        'KALAU BISA DATANG LEBIH AWAL LEBIH BAIK JANGAN KHAWATIR KAMI SUDAH SEDIAKAN PENGINAPAN GRATIS '
        'UNTUK PASIEN ISTIRAHAT. TERIMAKASIH SALAM SEHAT UNTUK SEMUA☺️🙏',
  );
}
