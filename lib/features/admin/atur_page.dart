import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/klinik.dart';
import '../../core/theme.dart';
import '../../data/repository.dart';
import '../../models/models.dart';
import '../../state/session.dart';
import '../../widgets/async_view.dart';
import '../../widgets/ui.dart';
import 'admin_shell.dart';

class AturPage extends StatelessWidget {
  const AturPage({super.key});

  @override
  Widget build(BuildContext context) {
    void buka(Widget w) => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => w));
    return Scaffold(
      appBar: headerApp('Atur'),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Kartu(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                _ItemMenu('Data pasien', () => buka(const DataPasienPage())),
                _ItemMenu('Media sosial', () => buka(const MediaSosialPage())),
                _ItemMenu('Kalender & slot jadwal', () => tabAdmin.value = 2, terakhir: true),
              ],
            ),
          ),
          const Kartu(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                JudulKartu('Profil admin'),
                Text('admin - ${Klinik.nama}', style: tsMut),
              ],
            ),
          ),
          const Text('Alamat, biaya, dan nomor admin di menu Info diatur saat pembuatan aplikasi.', style: tsCap),
          Tombol('Keluar', varian: Varian.merah, onPressed: context.read<Session>().keluar),
        ],
      ),
    );
  }
}

/// Baris menu (.mlist a).
class _ItemMenu extends StatelessWidget {
  const _ItemMenu(this.label, this.onTap, {this.terakhir = false});
  final String label;
  final VoidCallback onTap;
  final bool terakhir;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          border: terakhir ? null : const Border(bottom: BorderSide(color: AppColors.bd)),
        ),
        child: Row(
          children: [
            Expanded(child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600))),
            const Text('›', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

// ======================================================================= data pasien

class DataPasienPage extends StatelessWidget {
  const DataPasienPage({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = context.read<Repository>();
    return Scaffold(
      appBar: headerApp('Data Pasien', aksi: [TombolHeader('Kembali', onTap: () => Navigator.pop(context))]),
      body: AsyncView(
        load: (repo) => repo.akunPasien(),
        builder: (context, list) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            for (final a in list)
              Kartu(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Baris(
                      kiri: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(a.nama, style: const TextStyle(fontWeight: FontWeight.w700)),
                          Text(a.noHp, style: tsMut),
                        ],
                      ),
                      kanan: Tag.aktif(a.aktif),
                    ),
                    DeretPil(children: [
                      Pil('Reset sandi', onTap: () async {
                        await repo.resetSandi(a.id);
                        if (context.mounted) {
                          toast(context, 'Sandi direset', 'Sandi sementara 123456, kirim lewat WhatsApp.');
                        }
                      }),
                      Pil(a.aktif ? 'Nonaktifkan' : 'Aktifkan', onTap: () => repo.aturAkunAktif(a.id, !a.aktif)),
                    ]),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ======================================================================= media sosial

class MediaSosialPage extends StatefulWidget {
  const MediaSosialPage({super.key});

  @override
  State<MediaSosialPage> createState() => _MediaSosialPageState();
}

class _MediaSosialPageState extends State<MediaSosialPage> {
  int? _ubah; // indeks yang sedang diubah
  String _platform = platformMedsos.first;
  final _nama = TextEditingController();
  final _url = TextEditingController();

  @override
  void dispose() {
    _nama.dispose();
    _url.dispose();
    super.dispose();
  }

  /// Mengembalikan `true` bila tersimpan.
  Future<bool> _simpan(List<MediaSosial> baru, [String? judul, String? isi]) async {
    try {
      await context.read<Repository>().simpanMediaSosial(baru);
      if (judul != null && mounted) toast(context, judul, isi ?? '');
      return true;
    } catch (e) {
      if (mounted) toast(context, 'URL tidak valid', '$e');
      return false;
    }
  }

  void _mulaiUbah(List<MediaSosial> list, int i) => setState(() {
        _ubah = i;
        _platform = list[i].platform;
        _nama.text = list[i].nama;
        _url.text = list[i].url;
      });

  void _kosongkan() => setState(() {
        _ubah = null;
        _platform = platformMedsos.first;
        _nama.clear();
        _url.clear();
      });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: headerApp('Media Sosial', aksi: [TombolHeader('Kembali', onTap: () => Navigator.pop(context))]),
      body: AsyncView(
        load: (repo) => repo.mediaSosial(),
        builder: (context, list) {
          List<MediaSosial> salin() => List.of(list);
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              for (var i = 0; i < list.length; i++)
                Kartu(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Baris(
                        kiri: Text('${list[i].platform}: ${list[i].nama}',
                            style: const TextStyle(fontWeight: FontWeight.w700)),
                        kanan: Tag.aktif(list[i].aktif),
                      ),
                      Text(list[i].url, style: tsCap),
                      DeretPil(children: [
                        Pil('↑', nonaktif: i == 0, onTap: () {
                          final l = salin()..insert(i - 1, list[i])..removeAt(i + 1);
                          _simpan(l);
                        }),
                        Pil('↓', nonaktif: i == list.length - 1, onTap: () {
                          final l = salin()..insert(i + 2, list[i])..removeAt(i);
                          _simpan(l);
                        }),
                        Pil('Ubah', onTap: () => _mulaiUbah(list, i)),
                        Pil(list[i].aktif ? 'Nonaktifkan' : 'Aktifkan', onTap: () {
                          final l = salin();
                          l[i] = l[i].copyWith(aktif: !l[i].aktif);
                          _simpan(l);
                        }),
                        Pil('Hapus', onTap: () async {
                          if (!await konfirmasi(context, 'Hapus tautan ini?')) return;
                          if (await _simpan(salin()..removeAt(i))) _kosongkan();
                        }),
                      ]),
                    ],
                  ),
                ),
              Kartu(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    JudulKartu(_ubah != null ? 'Ubah tautan' : 'Tambah tautan'),
                    const Label('Platform'),
                    DropdownButtonFormField<String>(
                      initialValue: _platform,
                      key: ValueKey(('pl', _ubah, _platform)),
                      items: [for (final p in platformMedsos) DropdownMenuItem(value: p, child: Text(p))],
                      onChanged: (v) => _platform = v ?? _platform,
                    ),
                    const Label('Nama akun'),
                    TextField(controller: _nama),
                    const Label('URL'),
                    TextField(
                      controller: _url,
                      keyboardType: TextInputType.url,
                      decoration: const InputDecoration(hintText: 'https://...'),
                    ),
                    Tombol(_ubah != null ? 'Simpan Perubahan' : 'Tambah', onPressed: () async {
                      if (_nama.text.trim().isEmpty) return toast(context, 'Lengkapi', 'Isi nama akun.');
                      final s = MediaSosial(platform: _platform, nama: _nama.text.trim(), url: _url.text.trim());
                      final l = salin();
                      if (_ubah != null) {
                        l[_ubah!] = s.copyWith(aktif: l[_ubah!].aktif);
                      } else {
                        l.add(s);
                      }
                      if (await _simpan(l, 'Tersimpan', 'Langsung tampil di menu Info.')) _kosongkan();
                    }),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
