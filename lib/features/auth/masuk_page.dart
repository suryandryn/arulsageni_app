import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/klinik.dart';
import '../../core/theme.dart';
import '../../state/session.dart';
import '../../widgets/ui.dart';
import 'akun_baru_page.dart';
import 'auth_layout.dart';

class MasukPage extends StatefulWidget {
  const MasukPage({super.key});

  @override
  State<MasukPage> createState() => _MasukPageState();
}

class _MasukPageState extends State<MasukPage> {
  bool _pasien = true;
  bool _proses = false;
  // Kolom kosong saat dibuka; contoh isian tampil sebagai placeholder.
  final _hp = TextEditingController();
  final _sandiP = TextEditingController();
  final _user = TextEditingController();
  final _sandiA = TextEditingController();

  @override
  void dispose() {
    for (final c in [_hp, _sandiP, _user, _sandiA]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _masuk() async {
    final s = context.read<Session>();
    final (a, b) = _pasien ? (_hp.text, _sandiP.text) : (_user.text, _sandiA.text);
    if (a.trim().isEmpty || b.isEmpty) return toast(context, 'Lengkapi', 'Isi semua kolom.');
    setState(() => _proses = true);
    try {
      _pasien ? await s.masukPasien(a, b) : await s.masukAdmin(a, b);
    } catch (e) {
      if (mounted) toast(context, 'Gagal masuk', '$e');
    } finally {
      if (mounted) setState(() => _proses = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthLayout(
      children: [
        const AuthHero(
          judul: Klinik.nama,
          keterangan: 'Daftar berobat dan lihat jadwal janji temu dari HP.',
        ),
        _Tab(pasien: _pasien, onUbah: (v) => setState(() => _pasien = v)),
        Kartu(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: _pasien
                ? [
                    const Label('Nomor HP (WhatsApp)', atas: 0),
                    TextField(
                      controller: _hp,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(hintText: '08xxxxxxxxxx'),
                    ),
                    const Label('Kata sandi'),
                    TextField(
                      controller: _sandiP,
                      obscureText: true,
                      decoration: const InputDecoration(hintText: 'Kata sandi Anda'),
                      onSubmitted: (_) => _masuk(),
                    ),
                    Tombol('Masuk', memuat: _proses, onPressed: _masuk),
                  ]
                : [
                    const Label('Nama pengguna', atas: 0),
                    TextField(
                      controller: _user,
                      decoration: const InputDecoration(hintText: 'Nama pengguna admin'),
                    ),
                    const Label('Kata sandi'),
                    TextField(
                      controller: _sandiA,
                      obscureText: true,
                      decoration: const InputDecoration(hintText: 'Kata sandi admin'),
                      onSubmitted: (_) => _masuk(),
                    ),
                    Tombol('Masuk Admin', memuat: _proses, onPressed: _masuk),
                  ],
          ),
        ),
        if (_pasien)
          AuthTautan(
            teks: 'Belum punya akun?',
            tautan: 'Daftar akun',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const AkunBaruPage()),
            ),
          ),
      ],
    );
  }
}

/// Tab Pasien / Admin (.tabs).
class _Tab extends StatelessWidget {
  const _Tab({required this.pasien, required this.onUbah});
  final bool pasien;
  final ValueChanged<bool> onUbah;

  @override
  Widget build(BuildContext context) {
    Widget tab(String label, bool on, bool nilai) => Expanded(
          child: GestureDetector(
            onTap: () => onUbah(nilai),
            child: Container(
              padding: const EdgeInsets.all(10),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: on ? Colors.white : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(label,
                  style: TextStyle(fontWeight: FontWeight.w600, color: on ? AppColors.pri : AppColors.mut)),
            ),
          ),
        );
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: AppColors.krem, borderRadius: BorderRadius.circular(10)),
      child: Row(children: [tab('Pasien', pasien, true), tab('Admin', !pasien, false)]),
    );
  }
}
