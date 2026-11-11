import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/config.dart';
import '../../core/klinik.dart';
import '../../core/theme.dart';
import '../../state/session.dart';
import '../../widgets/ui.dart';
import 'akun_baru_page.dart';

class MasukPage extends StatefulWidget {
  const MasukPage({super.key});

  @override
  State<MasukPage> createState() => _MasukPageState();
}

class _MasukPageState extends State<MasukPage> {
  bool _pasien = true;
  bool _proses = false;
  // Mode demo: data masuk sudah terisi, seperti di demo desain.
  final _hp = TextEditingController(text: AppConfig.useMock ? '0812-3456-7890' : '');
  final _sandiP = TextEditingController(text: AppConfig.useMock ? '123456' : '');
  final _user = TextEditingController(text: AppConfig.useMock ? 'admin' : '');
  final _sandiA = TextEditingController(text: AppConfig.useMock ? '123456' : '');

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
    return Scaffold(
      body: SafeArea(
        child: ListView(
          children: [
            // .hero
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 32, 22, 8),
              child: Column(
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      border: Border.all(color: Colors.white, width: 4),
                      boxShadow: const [BoxShadow(color: Color(0x22000000), blurRadius: 14, offset: Offset(0, 4))],
                      image: const DecorationImage(
                        image: AssetImage(Klinik.foto),
                        fit: BoxFit.cover,
                        alignment: Alignment(0, -0.7),
                      ),
                    ),
                  ),
                  Text(Klinik.nama, textAlign: TextAlign.center, style: lora(26)),
                  const SizedBox(height: 8),
                  const Text('Daftar berobat dan lihat jadwal janji temu dari HP.',
                      textAlign: TextAlign.center, style: tsMut),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _Tab(pasien: _pasien, onUbah: (v) => setState(() => _pasien = v)),
                  Kartu(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: _pasien
                          ? [
                              const Label('Nomor HP (WhatsApp)', atas: 0),
                              TextField(controller: _hp, keyboardType: TextInputType.phone),
                              const Label('Kata sandi'),
                              TextField(controller: _sandiP, obscureText: true, onSubmitted: (_) => _masuk()),
                              Tombol('Masuk', memuat: _proses, onPressed: _masuk),
                            ]
                          : [
                              const Label('Nama pengguna', atas: 0),
                              TextField(controller: _user),
                              const Label('Kata sandi'),
                              TextField(controller: _sandiA, obscureText: true, onSubmitted: (_) => _masuk()),
                              Tombol('Masuk Admin', memuat: _proses, onPressed: _masuk),
                            ],
                    ),
                  ),
                  if (_pasien)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('Belum punya akun? ', style: tsMut),
                        GestureDetector(
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(builder: (_) => const AkunBaruPage()),
                          ),
                          child: const Text('Daftar akun',
                              style: TextStyle(
                                color: AppColors.pri,
                                fontSize: 14,
                                decoration: TextDecoration.underline,
                                decorationColor: AppColors.pri,
                              )),
                        ),
                      ],
                    ),
                  if (AppConfig.useMock)
                    const Padding(
                      padding: EdgeInsets.only(top: 14),
                      child: Text('Demo: data masuk sudah terisi.', textAlign: TextAlign.center, style: tsCap),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
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
