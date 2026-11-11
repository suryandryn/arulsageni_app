import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/klinik.dart';
import '../../state/session.dart';
import '../../widgets/ui.dart';

class AkunBaruPage extends StatefulWidget {
  const AkunBaruPage({super.key});

  @override
  State<AkunBaruPage> createState() => _AkunBaruPageState();
}

class _AkunBaruPageState extends State<AkunBaruPage> {
  final _nama = TextEditingController();
  final _hp = TextEditingController();
  final _sandi = TextEditingController();
  bool _proses = false;

  @override
  void dispose() {
    for (final c in [_nama, _hp, _sandi]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _daftar() async {
    if (_nama.text.trim().isEmpty || _hp.text.trim().isEmpty) {
      return toast(context, 'Lengkapi', 'Isi nama dan nomor HP.');
    }
    if (_sandi.text.length < 6) return toast(context, 'Kata sandi terlalu pendek', 'Minimal 6 karakter.');
    setState(() => _proses = true);
    try {
      await context.read<Session>().daftarAkun(nama: _nama.text, noHp: _hp.text, sandi: _sandi.text);
      if (!mounted) return;
      toast(context, 'Akun dibuat', 'Selamat datang di ${Klinik.nama}');
      Navigator.of(context).pop();
    } catch (e) {
      if (mounted) toast(context, 'Gagal mendaftar', '$e');
    } finally {
      if (mounted) setState(() => _proses = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: headerApp('Daftar Akun', aksi: [TombolHeader('Kembali', onTap: () => Navigator.pop(context))]),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Kartu(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Label('Nama lengkap', atas: 0),
                TextField(controller: _nama, textCapitalization: TextCapitalization.words),
                const Label('Nomor HP (WhatsApp)'),
                TextField(
                  controller: _hp,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(hintText: '08xxxxxxxxxx'),
                ),
                const Label('Kata sandi'),
                TextField(controller: _sandi, obscureText: true),
              ],
            ),
          ),
          Tombol('Daftar dan Masuk', atas: 0, memuat: _proses, onPressed: _daftar),
        ],
      ),
    );
  }
}
